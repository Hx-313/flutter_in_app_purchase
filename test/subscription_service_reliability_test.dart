import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

class _MemoryStorage implements SubscriptionStorage {
  final entitlements = <String, Entitlement>{};
  final processed = <String>{};
  final pendingConsumables = <String, ConsumableDelivery>{};
  final calls = <String>[];
  bool failSavingEntitlement = false;
  bool failMarkingPurchase = false;

  @override
  Future<void> initialize(String keyPrefix) async {}

  @override
  Future<Map<String, Entitlement>> loadEntitlements() async =>
      Map.of(entitlements);

  @override
  Future<void> saveEntitlement(Entitlement entitlement) async {
    calls.add('saveEntitlement');
    if (failSavingEntitlement) throw StateError('entitlement write failed');
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
    calls.add('savePendingConsumable');
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
    calls.add('markPurchaseProcessed');
    if (failMarkingPurchase) throw StateError('marker write failed');
    processed.add(purchaseId);
  }

  @override
  Future<void> dispose() async {}
}

class _FakeStore implements SubscriptionStore {
  _FakeStore(this._products);

  final List<StoreProduct> _products;
  final _updates = StreamController<StorePurchase>.broadcast();
  final calls = <String>[];
  List<StorePurchase> existingPurchases = const [];
  List<StorePurchase> restorePurchases = const [];
  Object? restoreFailure;
  int completeFailuresRemaining = 0;
  @override
  bool isAvailable = true;

  @override
  List<StoreProduct> get products => _products;

  @override
  Stream<StorePurchase> get purchaseStream => _updates.stream;

  @override
  Future<void> initialize(List<ProductDefinition> products) async {}

  @override
  Future<void> purchase(String productId) async {}

  @override
  Future<void> restore() async {
    if (restoreFailure case final error?) throw error;
    for (final purchase in restorePurchases) {
      _updates.add(purchase);
    }
  }

  @override
  Future<List<StorePurchase>> queryExistingPurchases() async =>
      existingPurchases;

  @override
  Future<void> complete(StorePurchase purchase) async {
    calls.add('complete');
    if (completeFailuresRemaining > 0) {
      completeFailuresRemaining--;
      throw StateError('completion failed');
    }
  }

  @override
  Future<void> dispose() async => _updates.close();

  void emit(StorePurchase purchase) => _updates.add(purchase);
}

class _FakeVerifier implements PurchaseVerifier {
  _FakeVerifier(this.onVerify);

  final Future<VerificationResult> Function(PurchaseVerificationRequest request)
  onVerify;
  int calls = 0;

  @override
  Future<VerificationResult> verify(PurchaseVerificationRequest request) {
    calls++;
    return onVerify(request);
  }
}

const _lifetime = ProductDefinition(
  id: 'pro_lifetime',
  type: ProductType.lifetime,
  entitlementId: 'premium',
);

const _consumable = ProductDefinition(
  id: 'coins_100',
  type: ProductType.consumable,
);

StoreProduct _product(String id) => StoreProduct(
  id: id,
  title: id,
  description: '',
  price: r'$1.00',
  rawPrice: 1,
  currencyCode: 'USD',
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'processPurchase_persistsEntitlementBeforeMarkerAndCompletion',
    () async {
      final storage = _MemoryStorage();
      final store = _FakeStore([_product(_lifetime.id)]);
      final service = SubscriptionService(
        config: SubscriptionConfig(products: const [_lifetime]),
        repository: SubscriptionRepositoryImpl(store: store, storage: storage),
      );
      await service.initialize();
      storage.calls.clear();
      final purchase = const StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-1',
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      );
      store.emit(purchase);

      await _flush();

      expect(storage.calls, ['saveEntitlement', 'markPurchaseProcessed']);
      expect(store.calls, ['complete']);
      expect(service.hasAccess, isTrue);
      await service.dispose();
    },
  );

  test('processPurchase_doesNotCompleteWhenVerifierUnavailable', () async {
    final storage = _MemoryStorage();
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(
        products: const [_lifetime],
        verificationMode: VerificationMode.serverVerified,
      ),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
    );
    final results = <PurchaseResult>[];
    final resultSubscription = service.purchaseResultStream.listen(results.add);
    await service.initialize();
    store.emit(
      const StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-1',
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
    await _flush();

    expect(results.single.status, PurchaseStatus.verificationFailed);
    expect(storage.processed, isEmpty);
    expect(store.calls, isEmpty);
    expect(service.hasAccess, isFalse);
    await resultSubscription.cancel();
    await service.dispose();
  });

  test('processPurchase_doesNotCompleteWhenVerifierThrows', () async {
    final storage = _MemoryStorage();
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(
        products: const [_lifetime],
        verificationMode: VerificationMode.serverVerified,
      ),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
      verifier: _FakeVerifier((_) async => throw StateError('backend offline')),
    );
    final results = <PurchaseResult>[];
    final subscription = service.purchaseResultStream.listen(results.add);
    await service.initialize();
    store.emit(
      const StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-1',
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
    await _flush();

    expect(results.single.status, PurchaseStatus.error);
    expect(storage.processed, isEmpty);
    expect(store.calls, isEmpty);
    expect(service.hasAccess, isFalse);
    await subscription.cancel();
    await service.dispose();
  });

  test('processPurchase_doesNotCompleteWhenStorageSaveFails', () async {
    final storage = _MemoryStorage()..failSavingEntitlement = true;
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
    );
    final results = <PurchaseResult>[];
    final resultSubscription = service.purchaseResultStream.listen(results.add);
    await service.initialize();
    store.emit(
      const StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-1',
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
    await _flush();

    expect(storage.processed, isEmpty);
    expect(store.calls, isEmpty);
    expect(service.hasAccess, isFalse);
    expect(results.single.status, PurchaseStatus.error);
    await resultSubscription.cancel();
    await service.dispose();
  });

  test('processPurchase_withoutStableIdEmitsErrorWithoutMarking', () async {
    final storage = _MemoryStorage();
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
    );
    final results = <PurchaseResult>[];
    final resultSubscription = service.purchaseResultStream.listen(results.add);
    await service.initialize();
    store.emit(
      const StorePurchase(
        productId: 'pro_lifetime',
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
    await _flush();

    expect(results.single.status, PurchaseStatus.error);
    expect(storage.processed, isEmpty);
    expect(store.calls, isEmpty);
    await resultSubscription.cancel();
    await service.dispose();
  });

  test('processPurchase_usesTransactionDateWhenStoreIdIsMissing', () async {
    final storage = _MemoryStorage();
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
    );
    final transactionDate = DateTime.utc(2026, 10, 14);
    await service.initialize();
    store.emit(
      StorePurchase(
        productId: _lifetime.id,
        transactionDate: transactionDate,
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
    await _flush();

    expect(storage.processed, {
      '${_lifetime.id}:${transactionDate.microsecondsSinceEpoch}',
    });
    expect(store.calls, ['complete']);
    await service.dispose();
  });

  test('processPurchase_emitsPendingWithoutCompleting', () async {
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(
        store: store,
        storage: _MemoryStorage(),
      ),
    );
    final results = <PurchaseResult>[];
    final subscription = service.purchaseResultStream.listen(results.add);
    await service.initialize();
    store.emit(
      const StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-pending',
        status: StorePurchaseStatus.pending,
        pendingCompletePurchase: true,
      ),
    );
    await _flush();

    expect(results.single.status, PurchaseStatus.pending);
    expect(store.calls, isEmpty);
    expect(service.hasAccess, isFalse);
    await subscription.cancel();
    await service.dispose();
  });

  test('processPurchase_emitsCanceledWithoutGranting', () async {
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(
        store: store,
        storage: _MemoryStorage(),
      ),
    );
    final results = <PurchaseResult>[];
    final subscription = service.purchaseResultStream.listen(results.add);
    await service.initialize();
    store.emit(
      const StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-canceled',
        status: StorePurchaseStatus.canceled,
      ),
    );
    await _flush();

    expect(results.single.status, PurchaseStatus.canceled);
    expect(service.hasAccess, isFalse);
    await subscription.cancel();
    await service.dispose();
  });

  test('processPurchase_emitsErrorWithoutGranting', () async {
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(
        store: store,
        storage: _MemoryStorage(),
      ),
    );
    final results = <PurchaseResult>[];
    final subscription = service.purchaseResultStream.listen(results.add);
    await service.initialize();
    store.emit(
      const StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-error',
        status: StorePurchaseStatus.error,
        errorCode: 'store-error',
      ),
    );
    await _flush();

    expect(results.single.status, PurchaseStatus.error);
    expect(service.hasAccess, isFalse);
    await subscription.cancel();
    await service.dispose();
  });

  test('processPurchase_stagesConsumableBeforeCompletion', () async {
    final storage = _MemoryStorage();
    final store = _FakeStore([_product(_consumable.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_consumable]),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
    );
    await service.initialize();
    store.emit(
      StorePurchase(
        productId: _consumable.id,
        purchaseId: 'coins-order-1',
        transactionDate: DateTime.utc(2026, 10, 14),
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
    await _flush();

    expect(service.pendingConsumables.single.purchaseId, 'coins-order-1');
    expect(storage.calls, ['savePendingConsumable', 'markPurchaseProcessed']);
    expect(store.calls, ['complete']);
    await service.dispose();
  });

  test('restore_nonRenewingUsesTransactionDateForExpiry', () async {
    final transactionDate = DateTime.now().subtract(const Duration(minutes: 1));
    final product = ProductDefinition(
      id: 'pro_30_days',
      type: ProductType.nonRenewing,
      entitlementId: 'premium',
      duration: const Duration(days: 30),
    );
    final store = _FakeStore([_product(product.id)])
      ..restorePurchases = [
        StorePurchase(
          productId: product.id,
          purchaseId: 'old-order',
          transactionDate: transactionDate,
          status: StorePurchaseStatus.restored,
        ),
      ];
    final service = SubscriptionService(
      config: SubscriptionConfig(products: [product]),
      repository: SubscriptionRepositoryImpl(
        store: store,
        storage: _MemoryStorage(),
      ),
    );
    await service.initialize();

    final result = await service.restore();

    expect(result.restored, isTrue);
    expect(
      result.entitlement?.expiresAt,
      transactionDate.add(product.duration!),
    );
    expect(result.entitlement?.hasAccess, isTrue);
    await service.dispose();
  });

  test('restore_expiredNonRenewingIsInactiveImmediately', () async {
    final transactionDate = DateTime.now().subtract(const Duration(days: 60));
    final product = ProductDefinition(
      id: 'pro_30_days',
      type: ProductType.nonRenewing,
      entitlementId: 'premium',
      duration: const Duration(days: 30),
    );
    final store = _FakeStore([_product(product.id)])
      ..restorePurchases = [
        StorePurchase(
          productId: product.id,
          purchaseId: 'old-order',
          transactionDate: transactionDate,
          status: StorePurchaseStatus.restored,
        ),
      ];
    final service = SubscriptionService(
      config: SubscriptionConfig(products: [product]),
      repository: SubscriptionRepositoryImpl(
        store: store,
        storage: _MemoryStorage(),
      ),
    );
    await service.initialize();

    final result = await service.restore();

    expect(result.restored, isTrue);
    expect(service.currentEntitlement?.state, SubscriptionState.expired);
    expect(service.hasAccess, isFalse);
    await service.dispose();
  });

  test('initialize_replaysConsumableUntilAcknowledged', () async {
    final storage = _MemoryStorage()
      ..processed.add('coins-order-1')
      ..pendingConsumables['coins-order-1'] = ConsumableDelivery(
        purchaseId: 'coins-order-1',
        productId: _consumable.id,
        purchasedAt: DateTime.utc(2026, 10, 14),
      );
    final store = _FakeStore([_product(_consumable.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_consumable]),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
    );
    await service.initialize();
    expect(service.pendingConsumables.single.purchaseId, 'coins-order-1');
    store.emit(
      StorePurchase(
        productId: _consumable.id,
        purchaseId: 'coins-order-1',
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      ),
    );
    await _flush();
    expect(service.pendingConsumables, hasLength(1));
    expect(store.calls, ['complete']);

    await service.acknowledgeConsumablePurchase('coins-order-1');

    expect(service.pendingConsumables, isEmpty);
    expect(storage.pendingConsumables, isEmpty);
    await service.dispose();
  });

  test('restore_noPurchasesReturnsNone', () async {
    final store = _FakeStore([_product(_lifetime.id)]);
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(
        store: store,
        storage: _MemoryStorage(),
      ),
    );
    await service.initialize();

    expect((await service.restore()).status, RestoreStatus.none);
    await service.dispose();
  });

  test('restore_storeFailureReturnsFailure', () async {
    final store = _FakeStore([_product(_lifetime.id)])
      ..restoreFailure = StateError('restore failed');
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(
        store: store,
        storage: _MemoryStorage(),
      ),
    );
    await service.initialize();

    final result = await service.restore();

    expect(result.status, RestoreStatus.failure);
    expect(result.message, contains('restore failed'));
    await service.dispose();
  });

  test('restore_verifierUnavailableReturnsFailure', () async {
    final store = _FakeStore([_product(_lifetime.id)])
      ..restorePurchases = [
        const StorePurchase(
          productId: 'pro_lifetime',
          purchaseId: 'purchase-restore',
          status: StorePurchaseStatus.restored,
          pendingCompletePurchase: true,
        ),
      ];
    final service = SubscriptionService(
      config: SubscriptionConfig(
        products: const [_lifetime],
        verificationMode: VerificationMode.serverVerified,
      ),
      repository: SubscriptionRepositoryImpl(
        store: store,
        storage: _MemoryStorage(),
      ),
    );
    await service.initialize();

    final result = await service.restore();

    expect(result.status, RestoreStatus.failure);
    expect(result.message, contains('verifier'));
    expect(store.calls, isEmpty);
    await service.dispose();
  });

  test('restore_rejectedPurchaseReturnsFailureAndRevokesAccess', () async {
    final storage = _MemoryStorage()
      ..entitlements['premium'] = Entitlement.active(
        id: 'premium',
        productId: _lifetime.id,
        productType: ProductType.lifetime,
      );
    final store = _FakeStore([_product(_lifetime.id)])
      ..restorePurchases = [
        const StorePurchase(
          productId: 'pro_lifetime',
          purchaseId: 'purchase-rejected',
          status: StorePurchaseStatus.restored,
        ),
      ];
    final service = SubscriptionService(
      config: SubscriptionConfig(
        products: const [_lifetime],
        verificationMode: VerificationMode.serverVerified,
      ),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
      verifier: _FakeVerifier(
        (_) async => const VerificationResult.invalid(
          message: 'Purchase rejected by verifier.',
        ),
      ),
    );
    await service.initialize();

    final result = await service.restore();

    expect(result.status, RestoreStatus.failure);
    expect(result.message, contains('rejected by verifier'));
    expect(service.hasAccess, isFalse);
    await service.dispose();
  });

  test('restore_storageFailureReturnsFailure', () async {
    final store = _FakeStore([_product(_lifetime.id)])
      ..restorePurchases = [
        const StorePurchase(
          productId: 'pro_lifetime',
          purchaseId: 'purchase-restore',
          status: StorePurchaseStatus.restored,
          pendingCompletePurchase: true,
        ),
      ];
    final storage = _MemoryStorage()..failSavingEntitlement = true;
    final service = SubscriptionService(
      config: SubscriptionConfig(products: const [_lifetime]),
      repository: SubscriptionRepositoryImpl(store: store, storage: storage),
    );
    await service.initialize();

    final result = await service.restore();

    expect(result.status, RestoreStatus.failure);
    expect(result.message, contains('entitlement write failed'));
    expect(storage.processed, isEmpty);
    expect(store.calls, isEmpty);
    await service.dispose();
  });

  test(
    'processPurchase_reportsDurableSuccessWhenCompletionIsRetried',
    () async {
      final store = _FakeStore([_product(_lifetime.id)])
        ..completeFailuresRemaining = 1;
      final service = SubscriptionService(
        config: SubscriptionConfig(products: const [_lifetime]),
        repository: SubscriptionRepositoryImpl(
          store: store,
          storage: _MemoryStorage(),
        ),
      );
      final results = <PurchaseResult>[];
      final subscription = service.purchaseResultStream.listen(results.add);
      await service.initialize();
      const purchase = StorePurchase(
        productId: 'pro_lifetime',
        purchaseId: 'purchase-completion-retry',
        status: StorePurchaseStatus.purchased,
        pendingCompletePurchase: true,
      );
      store.emit(purchase);
      await _flush();

      expect(service.hasAccess, isTrue);
      expect(results.map((result) => result.status), [
        PurchaseStatus.success,
        PurchaseStatus.error,
      ]);

      store.existingPurchases = [purchase];
      await service.refresh();

      expect(store.calls, ['complete', 'complete']);
      expect(
        results.where((result) => result.status == PurchaseStatus.success),
        hasLength(1),
      );
      await subscription.cancel();
      await service.dispose();
    },
  );

  test(
    'refresh_reverifiesProcessedDurablePurchaseWithoutDuplicateSuccess',
    () async {
      final expiry = DateTime.utc(2027, 1, 1);
      final storage = _MemoryStorage()
        ..processed.add('purchase-1')
        ..entitlements['premium'] = Entitlement.active(
          id: 'premium',
          productId: _lifetime.id,
          productType: ProductType.lifetime,
        );
      final store = _FakeStore([_product(_lifetime.id)])
        ..restorePurchases = [
          const StorePurchase(
            productId: 'pro_lifetime',
            purchaseId: 'purchase-1',
            status: StorePurchaseStatus.purchased,
          ),
          const StorePurchase(
            productId: 'pro_lifetime',
            purchaseId: 'purchase-1',
            status: StorePurchaseStatus.purchased,
          ),
        ];
      final verifier = _FakeVerifier(
        (_) async => VerificationResult.valid(expiresAt: expiry),
      );
      final service = SubscriptionService(
        config: SubscriptionConfig(
          products: const [_lifetime],
          verificationMode: VerificationMode.serverVerified,
        ),
        repository: SubscriptionRepositoryImpl(store: store, storage: storage),
        verifier: verifier,
      );
      final results = <PurchaseResult>[];
      final subscription = service.purchaseResultStream.listen(results.add);
      await service.initialize();

      await service.refresh();

      expect(verifier.calls, 1);
      expect(service.currentEntitlement?.expiresAt, expiry);
      expect(results, isEmpty);
      await subscription.cancel();
      await service.dispose();
    },
  );
}
