import 'dart:async';

import 'package:blast_buddies/core/ads/ads_removed.dart';
import 'package:blast_buddies/core/economy/lives.dart';
import 'package:blast_buddies/core/economy/packages.dart';
import 'package:blast_buddies/core/economy/wallet.dart';
import 'package:blast_buddies/core/settings/settings.dart';
import 'package:blast_buddies/core/store/purchase_service.dart';
import 'package:blast_buddies/core/store/store.dart';
import 'package:blast_buddies/features/shop/shop_sheet.dart';
import 'package:blast_buddies/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A store we control from the test.
class FakeStore implements PurchaseService {
  FakeStore({this.isAvailable = true, Set<String>? products})
      : _known = products ?? {...allProductIds};

  final bool isAvailable;
  final Set<String> _known;
  final StreamController<PurchaseEvent> controller = StreamController.broadcast();
  final List<String> started = [];
  final Set<String> completed = {};
  bool restoreCalled = false;
  bool startOk = true;

  @override
  bool get available => isAvailable;

  @override
  Stream<PurchaseEvent> get events => controller.stream;

  @override
  Future<void> init(Set<String> productIds) async {}

  @override
  bool knows(String productId) => _known.contains(productId);

  @override
  String? priceOf(String productId) => knows(productId) ? 'USD ${productId.length}' : null;

  @override
  Future<bool> buy(String productId, {required bool consumable}) async {
    started.add('$productId:${consumable ? 'c' : 'n'}');
    return startOk;
  }

  @override
  Future<void> restore() async => restoreCalled = true;

  /// Delivers a purchase like StoreKit would.
  Future<void> deliver(String id, String tx, {PurchaseEventKind kind = PurchaseEventKind.purchased}) async {
    controller.add(PurchaseEvent(
      kind: kind,
      productId: id,
      transactionId: tx,
      complete: () async => completed.add(tx),
    ));
    await pumpEventQueue();
  }
}

Future<(ProviderContainer, FakeStore)> setup({
  Map<String, Object> prefs = const {},
  FakeStore? store,
  DateTime? now,
}) async {
  // The app was first opened at `now` (the starter offer counts from there).
  SharedPreferences.setMockInitialValues({
    'walletInit': true,
    'coin': 0,
    if (now != null) 'firstLaunchMs': now.millisecondsSinceEpoch,
    ...prefs,
  });
  final sp = await SharedPreferences.getInstance();
  final fake = store ?? FakeStore();
  final c = ProviderContainer(overrides: [
    prefsProvider.overrideWithValue(sp),
    purchaseServiceProvider.overrideWithValue(fake),
  ]);
  addTearDown(c.dispose);
  if (now != null) c.read(storeProvider.notifier).now = () => now;
  c.read(storeProvider);
  return (c, fake);
}

void main() {
  final t0 = DateTime(2026, 1, 1, 12);

  group('coin packs', () {
    test('the first pack pays a bonus once; later packs do not', () async {
      final (c, store) = await setup(now: t0);
      expect(c.read(storeProvider).firstPurchaseBonus, isTrue);
      await store.deliver('coin_500', 'tx1');
      expect(c.read(walletProvider).coin, 1000); // 500 + 500 bonus
      expect(store.completed, {'tx1'});
      expect(c.read(storeProvider).firstPurchaseBonus, isFalse);
      await store.deliver('coin_1500', 'tx2');
      expect(c.read(walletProvider).coin, 2500);
    });

    test('the bonus is capped', () async {
      final (c, store) = await setup(now: t0);
      await store.deliver('coin_10000', 'tx1');
      expect(c.read(walletProvider).coin, 10000 + firstPurchaseBonusCap);
    });

    test('the same transaction is never delivered twice, but is always completed', () async {
      final (c, store) = await setup(now: t0);
      await store.deliver('coin_500', 'tx1');
      await store.deliver('coin_500', 'tx1');
      expect(c.read(walletProvider).coin, 1000);
      expect(store.completed, {'tx1'});
    });

    test('a replay after a restart is recognised', () async {
      final (c, store) = await setup(now: t0);
      await store.deliver('coin_500', 'tx1');
      final sp = c.read(prefsProvider);
      final c2 = ProviderContainer(overrides: [
        prefsProvider.overrideWithValue(sp),
        purchaseServiceProvider.overrideWithValue(store),
      ]);
      addTearDown(c2.dispose);
      c2.read(storeProvider);
      await store.deliver('coin_500', 'tx1');
      expect(c2.read(walletProvider).coin, 1000);
    });

    test('restoring never pays consumables again', () async {
      final (c, store) = await setup(now: t0);
      await store.deliver('coin_500', 'old', kind: PurchaseEventKind.restored);
      expect(c.read(walletProvider).coin, 0);
      expect(store.completed, {'old'});
    });

    test('messages tell the player what they got', () async {
      final (c, store) = await setup(now: t0);
      final got = <StoreMessage>[];
      c.read(storeProvider.notifier).messages.listen(got.add);
      await store.deliver('coin_500', 'tx1');
      expect(got.single.kind, StoreMessageKind.coins);
      expect(got.single.coins, 1000);
    });
  });

  group('remove ads', () {
    test('a purchase turns ads off', () async {
      final (c, store) = await setup(now: t0);
      expect(c.read(adsRemovedProvider), isFalse);
      await store.deliver('remove_ads', 'tx1');
      expect(c.read(adsRemovedProvider), isTrue);
      expect(c.read(prefsProvider).getBool('adsRemoved'), isTrue);
    });

    test('restoring on a new phone turns them off too', () async {
      final (c, store) = await setup(now: t0);
      await store.deliver('remove_ads', 'tx9', kind: PurchaseEventKind.restored);
      expect(c.read(adsRemovedProvider), isTrue);
    });
  });

  group('starter pack', () {
    test('is offered for 48 hours after the first launch', () async {
      final (c, _) = await setup(now: t0);
      final n = c.read(storeProvider.notifier);
      expect(n.starterActive, isTrue);
      n.now = () => t0.add(const Duration(hours: 47, minutes: 59));
      expect(n.starterActive, isTrue);
      n.now = () => t0.add(const Duration(hours: 48, minutes: 1));
      expect(n.starterActive, isFalse);
    });

    test('pays coins and refills lives once, then disappears', () async {
      final (c, store) = await setup(now: t0);
      for (var i = 0; i < 5; i++) {
        await c.read(livesProvider.notifier).consume();
      }
      expect(c.read(livesProvider).lives, 0);
      await store.deliver('starter_pack', 'tx1');
      expect(c.read(walletProvider).coin, starterPackCoins);
      expect(c.read(livesProvider).lives, LivesNotifier.maxLives);
      expect(c.read(storeProvider.notifier).starterActive, isFalse);
      // It is not a coin pack: the first-purchase bonus is still waiting.
      expect(c.read(storeProvider).firstPurchaseBonus, isTrue);
      await store.deliver('starter_pack', 'tx2');
      expect(c.read(walletProvider).coin, starterPackCoins);
    });

    test('restoring only marks it as owned, it does not pay again', () async {
      final (c, store) = await setup(now: t0);
      await store.deliver('starter_pack', 'tx1', kind: PurchaseEventKind.restored);
      expect(c.read(walletProvider).coin, 0);
      expect(c.read(storeProvider.notifier).starterActive, isFalse);
    });

    test('cannot be bought after the offer ended', () async {
      final (c, store) = await setup(now: t0);
      c.read(storeProvider.notifier).now = () => t0.add(const Duration(days: 3));
      await c.read(storeProvider.notifier).buy('starter_pack');
      expect(store.started, isEmpty);
    });
  });

  group('starting purchases', () {
    test('coin packs are consumables, remove ads and the starter pack are not', () async {
      final (c, store) = await setup(now: t0);
      final n = c.read(storeProvider.notifier);
      await n.buy('coin_500');
      expect(c.read(storeProvider).busyId, 'coin_500');
      await store.deliver('coin_500', 'a'); // finishing clears the busy flag
      await n.buy('remove_ads');
      await store.deliver('remove_ads', 'b');
      await n.buy('starter_pack');
      expect(store.started, ['coin_500:c', 'remove_ads:n', 'starter_pack:n']);
    });

    test('only one payment sheet at a time', () async {
      final (c, store) = await setup(now: t0);
      final n = c.read(storeProvider.notifier);
      await n.buy('coin_500');
      await n.buy('coin_1500');
      expect(store.started, ['coin_500:c']);
    });

    test('cancel and failure free the buttons; failure tells the player', () async {
      final (c, store) = await setup(now: t0);
      final got = <StoreMessage>[];
      c.read(storeProvider.notifier).messages.listen(got.add);
      await c.read(storeProvider.notifier).buy('coin_500');
      await store.deliver('coin_500', 'x', kind: PurchaseEventKind.canceled);
      expect(c.read(storeProvider).busyId, isNull);
      expect(got, isEmpty);
      await c.read(storeProvider.notifier).buy('coin_500');
      await store.deliver('coin_500', 'y', kind: PurchaseEventKind.failed);
      expect(c.read(storeProvider).busyId, isNull);
      expect(got.single.kind, StoreMessageKind.failed);
      expect(c.read(walletProvider).coin, 0);
    });

    test('a store that cannot open the sheet reports a failure', () async {
      final (c, store) = await setup(now: t0);
      store.startOk = false;
      final got = <StoreMessage>[];
      c.read(storeProvider.notifier).messages.listen(got.add);
      await c.read(storeProvider.notifier).buy('coin_500');
      await pumpEventQueue();
      expect(c.read(storeProvider).busyId, isNull);
      expect(got.single.kind, StoreMessageKind.failed);
    });

    test('unavailable store and unknown products are explained', () async {
      final (c, _) = await setup(store: FakeStore(isAvailable: false), now: t0);
      final got = <StoreMessage>[];
      c.read(storeProvider.notifier).messages.listen(got.add);
      await c.read(storeProvider.notifier).buy('coin_500');
      await c.read(storeProvider.notifier).restore();
      await pumpEventQueue();
      expect(got.map((m) => m.kind), [StoreMessageKind.unavailable, StoreMessageKind.unavailable]);

      final (c2, _) = await setup(store: FakeStore(products: {'coin_1500'}), now: t0);
      final got2 = <StoreMessage>[];
      c2.read(storeProvider.notifier).messages.listen(got2.add);
      await c2.read(storeProvider.notifier).buy('coin_500');
      await pumpEventQueue();
      expect(got2.single.kind, StoreMessageKind.productMissing);
    });

    test('restore asks the store', () async {
      final (c, store) = await setup(now: t0);
      await c.read(storeProvider.notifier).restore();
      expect(store.restoreCalled, isTrue);
    });

    test('localised prices from the store are exposed', () async {
      final (c, _) = await setup(now: t0);
      c.read(storeProvider.notifier).refreshPrices();
      expect(c.read(storeProvider).prices['coin_500'], 'USD 8');
    });
  });

  testWidgets('shop shows store prices, the bonus and the starter offer; tapping buys', (tester) async {
    final (c, store) = await setup(now: DateTime.now());
    c.read(storeProvider.notifier).refreshPrices();
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: ShopSheet()),
      ),
    ));
    expect(find.text('Starter pack'), findsOneWidget);
    expect(find.text('USD 8'), findsOneWidget); // coin_500 price from the store
    expect(find.text('+500 bonus coins'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
    await tester.tap(find.text('USD 8'));
    await tester.pump();
    expect(store.started, ['coin_500:c']);
    // (pumpEventQueue would wait on real timers inside a widget test.)
    store.controller.add(const PurchaseEvent(kind: PurchaseEventKind.canceled, productId: 'coin_500'));
    await tester.pump();
    await tester.tap(find.text('Restore purchases'));
    await tester.pump();
    expect(store.restoreCalled, isTrue);
  });
}
