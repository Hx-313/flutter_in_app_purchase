import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

class _MemoryStorage implements SubscriptionStorage {
  final entitlements = <String, Entitlement>{};
  final processed = <String>{};
  final pendingConsumables = <String, ConsumableDelivery>{};

  @override
  Future<void> initialize(String keyPrefix) async {}

  @override
  Future<Map<String, Entitlement>> loadEntitlements() async =>
      Map.of(entitlements);

  @override
  Future<void> saveEntitlement(Entitlement entitlement) async {
    entitlements[entitlement.id] = entitlement;
  }

  @override
  Future<void> removeEntitlement(String entitlementId) async {
    entitlements.remove(entitlementId);
  }

  @override
  Future<List<ConsumableDelivery>> loadPendingConsumables() async =>
      pendingConsumables.values.toList();

  @override
  Future<void> savePendingConsumable(ConsumableDelivery delivery) async {
    pendingConsumables.putIfAbsent(delivery.purchaseId, () => delivery);
  }

  @override
  Future<void> acknowledgeConsumable(String purchaseId) async {
    pendingConsumables.remove(purchaseId);
  }

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) async =>
      processed.contains(purchaseId);

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {
    processed.add(purchaseId);
  }

  @override
  Future<void> dispose() async {}
}

class _FakeStore implements SubscriptionStore {
  _FakeStore(this._products);

  final List<StoreProduct> _products;
  final _updates = StreamController<StorePurchase>.broadcast();
  int completeCount = 0;

  @override
  bool isAvailable = true;

  @override
  List<StoreProduct> get products => _products;

  @override
  Stream<StorePurchase> get purchaseStream => _updates.stream;

  @override
  Future<void> initialize(List<ProductDefinition> products) async {}

  @override
  Future<void> purchase(String productId) async {
    _updates.add(
      StorePurchase(
        productId: productId,
        purchaseId: 'purchase-$productId',
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
  }

  @override
  Future<void> restore() async {}

  @override
  Future<List<StorePurchase>> queryExistingPurchases() async => const [];

  @override
  Future<void> complete(StorePurchase purchase) async => completeCount++;

  @override
  Future<void> dispose() async => _updates.close();

  void emit(StorePurchase purchase) => _updates.add(purchase);
}

class _RejectingVerifier implements PurchaseVerifier {
  @override
  Future<VerificationResult> verify(
    PurchaseVerificationRequest request,
  ) async => const VerificationResult.invalid(message: 'Rejected by verifier');
}

void main() {
  test(
    'consumable purchase emits success without creating entitlement',
    () async {
      final store = _FakeStore([
        const StoreProduct(
          id: 'coins_100',
          title: '100 coins',
          description: 'A coin pack',
          price: r'$1.99',
          rawPrice: 1.99,
          currencyCode: 'USD',
        ),
      ]);
      final service = SubscriptionService(
        config: SubscriptionConfig(
          products: const [
            ProductDefinition(id: 'coins_100', type: ProductType.consumable),
          ],
        ),
        repository: SubscriptionRepositoryImpl(
          store: store,
          storage: _MemoryStorage(),
        ),
      );
      final results = <PurchaseResult>[];
      final subscription = service.purchaseResultStream.listen(results.add);

      await service.initialize();
      await service.purchase('coins_100');
      await Future<void>.delayed(Duration.zero);

      expect(results.single.status, PurchaseStatus.success);
      expect(results.single.entitlement, isNull);
      expect(service.entitlements, isEmpty);
      expect(store.completeCount, 1);

      await subscription.cancel();
      await service.dispose();
    },
  );

  test(
    'local auto-renewing purchase exposes active access with unknown expiry',
    () async {
      final store = _FakeStore([
        const StoreProduct(
          id: 'pro_monthly',
          title: 'Monthly',
          description: 'Monthly access',
          price: r'$4.99',
          rawPrice: 4.99,
          currencyCode: 'USD',
        ),
      ]);
      final service = SubscriptionService(
        config: SubscriptionConfig(
          products: const [
            ProductDefinition(
              id: 'pro_monthly',
              type: ProductType.autoRenewing,
              entitlementId: 'premium',
            ),
          ],
        ),
        repository: SubscriptionRepositoryImpl(
          store: store,
          storage: _MemoryStorage(),
        ),
      );

      await service.initialize();
      await service.purchase('pro_monthly');
      await Future<void>.delayed(Duration.zero);

      final entitlement = service.currentEntitlement;
      expect(entitlement?.hasAccess, isTrue);
      expect(entitlement?.state, SubscriptionState.active);
      expect(entitlement?.isExpiryKnown, isFalse);
      expect(entitlement?.hasDetailedLifecycle, isFalse);

      await service.dispose();
    },
  );

  test(
    'verified mode does not grant access after invalid verification',
    () async {
      final store = _FakeStore([
        const StoreProduct(
          id: 'pro_monthly',
          title: 'Monthly',
          description: 'Monthly access',
          price: r'$4.99',
          rawPrice: 4.99,
          currencyCode: 'USD',
        ),
      ]);
      final service = SubscriptionService(
        config: SubscriptionConfig(
          products: const [
            ProductDefinition(
              id: 'pro_monthly',
              type: ProductType.autoRenewing,
              entitlementId: 'premium',
            ),
          ],
          verificationMode: VerificationMode.serverVerified,
        ),
        repository: SubscriptionRepositoryImpl(
          store: store,
          storage: _MemoryStorage(),
        ),
        verifier: _RejectingVerifier(),
      );
      final results = <PurchaseResult>[];
      final subscription = service.purchaseResultStream.listen(results.add);

      await service.initialize();
      await service.purchase('pro_monthly');
      await Future<void>.delayed(Duration.zero);

      expect(service.hasAccess, isFalse);
      expect(results.single.status, PurchaseStatus.verificationFailed);

      await subscription.cancel();
      await service.dispose();
    },
  );

  test('verified refund revokes an existing entitlement', () async {
    final store = _FakeStore([
      const StoreProduct(
        id: 'pro_monthly',
        title: 'Monthly',
        description: 'Monthly access',
        price: r'$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
      ),
    ]);
    final storage = _MemoryStorage()
      ..entitlements['premium'] = Entitlement.active(
        id: 'premium',
        productId: 'pro_monthly',
        productType: ProductType.autoRenewing,
        isExpiryKnown: false,
      );
    final service = SubscriptionService(
      config: SubscriptionConfig(
        products: const [
          ProductDefinition(
            id: 'pro_monthly',
            type: ProductType.autoRenewing,
            entitlementId: 'premium',
          ),
        ],
        verificationMode: VerificationMode.serverVerified,
      ),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
      verifier: _RejectingVerifier(),
    );

    await service.initialize();
    store.emit(
      const StorePurchase(
        productId: 'pro_monthly',
        purchaseId: 'refund-1',
        status: StorePurchaseStatus.purchased,
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(service.hasAccess, isFalse);
    expect(service.currentEntitlement?.state, SubscriptionState.refunded);

    await service.dispose();
  });
}
