import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// What happened to a purchase.
enum PurchaseEventKind {
  /// Paid for just now: deliver the goods.
  purchased,

  /// Re-delivered by "Restore purchases" (only non-consumables come back).
  restored,

  /// The store reported an error; the player was not charged.
  failed,

  /// The player closed the payment sheet.
  canceled,
}

/// One result coming out of the store.
class PurchaseEvent {
  /// Creates an event. [complete] must be called once the goods are delivered
  /// (it finishes the store transaction); until then the store keeps
  /// re-delivering the purchase at every launch.
  const PurchaseEvent({
    required this.kind,
    required this.productId,
    this.transactionId,
    this.complete = _noop,
  });

  /// Outcome.
  final PurchaseEventKind kind;

  /// Store product id.
  final String productId;

  /// Store transaction id, used to never deliver the same purchase twice.
  final String? transactionId;

  /// Finishes the store transaction.
  final Future<void> Function() complete;

  static Future<void> _noop() async {}
}

/// The part of the app that talks to the App Store.
abstract class PurchaseService {
  /// The store can be used (signed in, purchases allowed, plugin supported).
  bool get available;

  /// Purchase results, including ones left over from earlier launches.
  Stream<PurchaseEvent> get events;

  /// Connects and loads product prices for [productIds]. Never throws.
  Future<void> init(Set<String> productIds);

  /// Whether the store knows [productId] (it exists in App Store Connect).
  bool knows(String productId);

  /// Localised price text of [productId], or null while unknown.
  String? priceOf(String productId);

  /// Opens the payment sheet. Returns false if it could not be started.
  Future<bool> buy(String productId, {required bool consumable});

  /// Asks the store to re-deliver non-consumable purchases.
  Future<void> restore();
}

/// Used when there is no store (tests, desktop, Android until it is set up).
class UnavailablePurchaseService implements PurchaseService {
  @override
  bool get available => false;

  @override
  Stream<PurchaseEvent> get events => const Stream.empty();

  @override
  Future<void> init(Set<String> productIds) async {}

  @override
  bool knows(String productId) => false;

  @override
  String? priceOf(String productId) => null;

  @override
  Future<bool> buy(String productId, {required bool consumable}) async => false;

  @override
  Future<void> restore() async {}
}

/// StoreKit (App Store) implementation on top of the `in_app_purchase` plugin.
class StoreKitPurchaseService implements PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  final StreamController<PurchaseEvent> _events = StreamController.broadcast();
  final Map<String, ProductDetails> _products = {};
  StreamSubscription<List<PurchaseDetails>>? _sub;
  bool _available = false;

  @override
  bool get available => _available;

  @override
  Stream<PurchaseEvent> get events => _events.stream;

  @override
  Future<void> init(Set<String> productIds) async {
    // Listen first: unfinished transactions are delivered as soon as we do.
    _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (Object e) => debugPrint('IAP stream: $e'));
    try {
      _available = await _iap.isAvailable();
      if (!_available) return;
      final response = await _iap.queryProductDetails(productIds);
      for (final p in response.productDetails) {
        _products[p.id] = p;
      }
      if (response.notFoundIDs.isNotEmpty) {
        debugPrint('IAP products not in App Store Connect yet: ${response.notFoundIDs}');
      }
    } on Object catch (e) {
      debugPrint('IAP init failed: $e');
    }
  }

  void _onPurchases(List<PurchaseDetails> purchases) {
    for (final p in purchases) {
      Future<void> finish() async {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      }

      switch (p.status) {
        case PurchaseStatus.pending:
          break; // e.g. "Ask to Buy": the result arrives later.
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _events.add(PurchaseEvent(
            kind: p.status == PurchaseStatus.purchased ? PurchaseEventKind.purchased : PurchaseEventKind.restored,
            productId: p.productID,
            transactionId: p.purchaseID,
            complete: finish,
          ));
        case PurchaseStatus.error:
          unawaited(finish());
          _events.add(PurchaseEvent(kind: PurchaseEventKind.failed, productId: p.productID));
        case PurchaseStatus.canceled:
          unawaited(finish());
          _events.add(PurchaseEvent(kind: PurchaseEventKind.canceled, productId: p.productID));
      }
    }
  }

  @override
  bool knows(String productId) => _products.containsKey(productId);

  @override
  String? priceOf(String productId) => _products[productId]?.price;

  @override
  Future<bool> buy(String productId, {required bool consumable}) async {
    final product = _products[productId];
    if (!_available || product == null) return false;
    final param = PurchaseParam(productDetails: product);
    try {
      return consumable
          ? await _iap.buyConsumable(purchaseParam: param)
          : await _iap.buyNonConsumable(purchaseParam: param);
    } on Object catch (e) {
      debugPrint('IAP buy failed: $e');
      return false;
    }
  }

  @override
  Future<void> restore() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } on Object catch (e) {
      debugPrint('IAP restore failed: $e');
    }
  }
}

/// Store provider (overridden with [StoreKitPurchaseService] on iOS).
final purchaseServiceProvider = Provider<PurchaseService>((ref) => UnavailablePurchaseService());
