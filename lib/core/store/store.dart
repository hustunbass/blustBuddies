import 'dart:async';

import 'package:blast_buddies/core/ads/ads_removed.dart';
import 'package:blast_buddies/core/economy/lives.dart';
import 'package:blast_buddies/core/economy/packages.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/store/purchase_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Something the player should be told about.
enum StoreMessageKind {
  /// Coins were delivered ([StoreMessage.coins]).
  coins,

  /// Ads were removed.
  adsRemoved,

  /// A purchase was restored.
  restored,

  /// The store could not be reached.
  unavailable,

  /// The product is not in the store (yet).
  productMissing,

  /// The purchase failed.
  failed,
}

/// A message for the UI.
class StoreMessage {
  /// Creates a message.
  const StoreMessage(this.kind, [this.coins = 0]);

  /// What happened.
  final StoreMessageKind kind;

  /// Coins delivered (for [StoreMessageKind.coins]).
  final int coins;
}

/// What the shop needs to know.
class StoreState {
  /// Creates the state.
  const StoreState({
    this.busyId,
    this.firstPurchaseBonus = true,
    this.starterEndsAt,
    this.prices = const {},
  });

  /// Product whose payment sheet is open.
  final String? busyId;

  /// The next coin pack pays the first-purchase bonus.
  final bool firstPurchaseBonus;

  /// End of the starter offer; null once bought.
  final DateTime? starterEndsAt;

  /// Localised prices by product id.
  final Map<String, String> prices;

  /// Copy with changes.
  StoreState copyWith({
    String? busyId,
    bool clearBusy = false,
    bool? firstPurchaseBonus,
    Map<String, String>? prices,
    bool clearStarter = false,
  }) =>
      StoreState(
        busyId: clearBusy ? null : busyId ?? this.busyId,
        firstPurchaseBonus: firstPurchaseBonus ?? this.firstPurchaseBonus,
        starterEndsAt: clearStarter ? null : starterEndsAt,
        prices: prices ?? this.prices,
      );
}

/// Starts purchases and delivers what was bought.
class StoreNotifier extends Notifier<StoreState> {
  static const _doneKey = 'iapDone';
  static const _keepDone = 200;

  /// Clock (overridable in tests).
  DateTime Function() now = DateTime.now;

  final StreamController<StoreMessage> _messages = StreamController.broadcast();
  Timer? _busyTimeout;

  /// Messages for the player, also for purchases that finish later (Ask to Buy).
  Stream<StoreMessage> get messages => _messages.stream;

  late PurchaseService _service;

  @override
  StoreState build() {
    _service = ref.watch(purchaseServiceProvider);
    final p = ref.read(prefsProvider);
    final sub = _service.events.listen(_onEvent);
    ref.onDispose(() {
      sub.cancel();
      _busyTimeout?.cancel();
    });
    final launch = p.getInt('firstLaunchMs') ?? now().millisecondsSinceEpoch;
    if (p.getInt('firstLaunchMs') == null) p.setInt('firstLaunchMs', launch);
    final ends = DateTime.fromMillisecondsSinceEpoch(launch).add(starterOfferDuration);
    return StoreState(
      firstPurchaseBonus: !(p.getBool('firstBuyDone') ?? false),
      starterEndsAt: (p.getBool('starterClaimed') ?? false) ? null : ends,
    );
  }

  /// Whether the starter offer can still be bought.
  bool get starterActive {
    final ends = state.starterEndsAt;
    return ends != null && now().isBefore(ends);
  }

  /// Bonus coins the next purchase of [pkg] would add.
  int bonusFor(CoinPackage pkg) => state.firstPurchaseBonus ? pkg.amount.clamp(0, firstPurchaseBonusCap) : 0;

  /// Loads localised prices (call after the service initialised).
  void refreshPrices() {
    state = state.copyWith(prices: {
      for (final id in allProductIds)
        if (_service.priceOf(id) != null) id: _service.priceOf(id)!,
    });
  }

  void _clearBusy() {
    _busyTimeout?.cancel();
    _busyTimeout = null;
    state = state.copyWith(clearBusy: true);
  }

  /// Opens the payment sheet for [productId].
  Future<void> buy(String productId) async {
    if (state.busyId != null) return;
    if (productId == starterPackProductId && !starterActive) return;
    if (!_service.available) {
      _messages.add(const StoreMessage(StoreMessageKind.unavailable));
      return;
    }
    if (!_service.knows(productId)) {
      _messages.add(const StoreMessage(StoreMessageKind.productMissing));
      return;
    }
    state = state.copyWith(busyId: productId);
    // Never leave the buttons disabled if the store never answers.
    _busyTimeout?.cancel();
    _busyTimeout = Timer(const Duration(minutes: 2), _clearBusy);
    final consumable = productId != removeAdsProductId && productId != starterPackProductId;
    final started = await _service.buy(productId, consumable: consumable);
    if (!started) {
      _clearBusy();
      _messages.add(const StoreMessage(StoreMessageKind.failed));
    }
  }

  /// Re-delivers non-consumable purchases (required by the App Store).
  Future<void> restore() async {
    if (!_service.available) {
      _messages.add(const StoreMessage(StoreMessageKind.unavailable));
      return;
    }
    await _service.restore();
    _messages.add(const StoreMessage(StoreMessageKind.restored));
  }

  Future<void> _onEvent(PurchaseEvent e) async {
    switch (e.kind) {
      case PurchaseEventKind.failed:
        _clearBusy();
        _messages.add(const StoreMessage(StoreMessageKind.failed));
      case PurchaseEventKind.canceled:
        _clearBusy();
      case PurchaseEventKind.purchased:
      case PurchaseEventKind.restored:
        await _deliver(e);
        _clearBusy();
    }
  }

  Future<void> _deliver(PurchaseEvent e) async {
    final p = ref.read(prefsProvider);
    final done = p.getStringList(_doneKey) ?? <String>[];
    final tx = e.transactionId;
    // A transaction is delivered once, however often the store repeats it.
    if (tx != null && done.contains(tx)) {
      await e.complete();
      return;
    }
    final restored = e.kind == PurchaseEventKind.restored;
    final id = e.productId;
    if (id == removeAdsProductId) {
      await ref.read(adsRemovedProvider.notifier).set(true);
      _messages.add(const StoreMessage(StoreMessageKind.adsRemoved));
    } else if (id == starterPackProductId) {
      if (!(p.getBool('starterClaimed') ?? false)) {
        // Restoring only marks it as owned; coins are paid for fresh purchases.
        await p.setBool('starterClaimed', true);
        state = state.copyWith(clearStarter: true);
        if (!restored) {
          await ref.read(walletProvider.notifier).earn(starterPackCoins);
          await ref.read(livesProvider.notifier).add(LivesNotifier.maxLives);
          _messages.add(const StoreMessage(StoreMessageKind.coins, starterPackCoins));
        }
      }
    } else if (!restored) {
      final pkg = coinPackages.where((c) => c.id == id).firstOrNull;
      if (pkg != null) {
        final total = pkg.amount + bonusFor(pkg);
        await ref.read(walletProvider.notifier).earn(total);
        await p.setBool('firstBuyDone', true);
        state = state.copyWith(firstPurchaseBonus: false);
        _messages.add(StoreMessage(StoreMessageKind.coins, total));
      }
    }
    if (tx != null) {
      await p.setStringList(_doneKey, [...done, tx].reversed.take(_keepDone).toList().reversed.toList());
    }
    await e.complete();
  }
}

/// Store provider.
final storeProvider = NotifierProvider<StoreNotifier, StoreState>(StoreNotifier.new);
