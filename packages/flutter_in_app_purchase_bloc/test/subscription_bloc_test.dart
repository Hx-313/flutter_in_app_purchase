import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';
import 'package:smart_inapp_purchase_bloc/smart_inapp_purchase_bloc.dart';

class _Storage implements SubscriptionStorage {
  final pending = <String, ConsumableDelivery>{};
  int acknowledgementCount = 0;

  @override
  Future<void> initialize(String keyPrefix) async {}

  @override
  Future<Map<String, Entitlement>> loadEntitlements() async => const {};

  @override
  Future<void> saveEntitlement(Entitlement entitlement) async {}

  @override
  Future<void> removeEntitlement(String entitlementId) async {}

  @override
  Future<List<ConsumableDelivery>> loadPendingConsumables() async =>
      pending.values.toList();

  @override
  Future<void> savePendingConsumable(ConsumableDelivery delivery) async {
    pending.putIfAbsent(delivery.purchaseId, () => delivery);
  }

  @override
  Future<void> acknowledgeConsumable(String purchaseId) async {
    acknowledgementCount++;
    pending.remove(purchaseId);
  }

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) async => false;

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {}

  @override
  Future<void> dispose() async {}
}

class _Store implements SubscriptionStore {
  _Store(this.product);

  final StoreProduct product;
  final _updates = StreamController<StorePurchase>.broadcast();
  @override
  bool isAvailable = true;
  int initializeCount = 0;
  int purchaseCount = 0;
  int restoreCount = 0;
  int queryCount = 0;
  Completer<void>? queryCalled;
  bool disposed = false;

  @override
  List<StoreProduct> get products => [product];

  @override
  Stream<StorePurchase> get purchaseStream => _updates.stream;

  @override
  Future<void> initialize(List<ProductDefinition> products) async {
    initializeCount++;
  }

  @override
  Future<void> purchase(String productId) async {
    purchaseCount++;
  }

  @override
  Future<void> restore() async {
    restoreCount++;
  }

  @override
  Future<List<StorePurchase>> queryExistingPurchases() async {
    queryCount++;
    if (queryCalled case final completer?) {
      if (!completer.isCompleted) completer.complete();
    }
    return const [];
  }

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<void> dispose() async {
    disposed = true;
    await _updates.close();
  }
}

const _plan = ProductDefinition(
  id: 'pro',
  type: ProductType.lifetime,
  entitlementId: 'premium',
);

SubscriptionBloc _bloc(_Store store, {_Storage? storage}) => SubscriptionBloc(
  service: SubscriptionService(
    config: SubscriptionConfig(products: const [_plan]),
    repository: SubscriptionRepositoryImpl(
      store: store,
      storage: storage ?? _Storage(),
    ),
  ),
);

Future<SubscriptionSnapshot> _phase(
  SubscriptionBloc bloc,
  SubscriptionPhase phase,
) => bloc.stream.firstWhere((state) => state.phase == phase);

void main() {
  test('initialize_unavailableStoreEmitsUnavailable', () async {
    final store = _Store(_product('pro'))..isAvailable = false;
    final bloc = _bloc(store);
    final unavailable = _phase(bloc, SubscriptionPhase.unavailable);
    bloc.add(const SubscriptionInitializeRequested());

    final state = await unavailable;

    expect(state.isStoreAvailable, isFalse);
    expect(state.products, isEmpty);
    await bloc.close();
  });

  test('initialize_retriesAfterStoreBecomesAvailable', () async {
    final store = _Store(_product('pro'))..isAvailable = false;
    final bloc = _bloc(store);
    final unavailable = _phase(bloc, SubscriptionPhase.unavailable);
    bloc.add(const SubscriptionInitializeRequested());
    await unavailable;

    store.isAvailable = true;
    final ready = _phase(bloc, SubscriptionPhase.ready);
    bloc.add(const SubscriptionInitializeRequested());
    final state = await ready;

    expect(state.products, hasLength(1));
    expect(state.isStoreAvailable, isTrue);
    expect(store.initializeCount, 2);
    await bloc.close();
  });

  test('purchase_dispatchesPurchaseRequested', () async {
    final store = _Store(_product('pro'));
    final bloc = _bloc(store);
    final ready = _phase(bloc, SubscriptionPhase.ready);
    bloc.add(const SubscriptionInitializeRequested());
    await ready;
    final purchasing = bloc.stream.firstWhere((_) => store.purchaseCount == 1);

    bloc.purchase('pro');
    await purchasing;

    expect(store.purchaseCount, 1);
    await bloc.close();
    expect(store.disposed, isTrue);
  });

  test('restore_dispatchesRestoreRequested', () async {
    final store = _Store(_product('pro'));
    final bloc = _bloc(store);
    final ready = _phase(bloc, SubscriptionPhase.ready);
    bloc.add(const SubscriptionInitializeRequested());
    await ready;
    final restored = bloc.stream.firstWhere(
      (state) => state.lastRestoreStatus == RestoreStatus.none,
    );

    bloc.restore();
    await restored;

    expect(store.restoreCount, 1);
    await bloc.close();
  });

  test('refresh_dispatchesRefreshRequested', () async {
    final store = _Store(_product('pro'));
    final bloc = _bloc(store);
    final ready = _phase(bloc, SubscriptionPhase.ready);
    bloc.add(const SubscriptionInitializeRequested());
    await ready;
    final queryCalled = store.queryCalled = Completer<void>();

    bloc.refresh();
    await queryCalled.future.timeout(const Duration(seconds: 1));

    expect(store.queryCount, 1);
    await bloc.close();
  });

  test('acknowledgeConsumable_updatesSnapshot', () async {
    final storage = _Storage()
      ..pending['coins-order-1'] = ConsumableDelivery(
        purchaseId: 'coins-order-1',
        productId: 'coins_100',
        purchasedAt: DateTime.utc(2026, 10, 14),
      );
    final store = _Store(_product('pro'));
    final bloc = _bloc(store, storage: storage);
    final ready = _phase(bloc, SubscriptionPhase.ready);
    bloc.add(const SubscriptionInitializeRequested());
    final initialized = await ready;
    expect(initialized.pendingConsumables.single.purchaseId, 'coins-order-1');
    final acknowledged = bloc.stream.firstWhere(
      (state) => state.pendingConsumables.isEmpty,
    );

    bloc.acknowledgeConsumablePurchase('coins-order-1');
    final state = await acknowledged;

    expect(state.pendingConsumables, isEmpty);
    expect(storage.acknowledgementCount, 1);
    await bloc.close();
  });
}

StoreProduct _product(String id) => StoreProduct(
  id: id,
  title: id,
  description: '',
  price: r'$1.00',
  rawPrice: 1,
  currencyCode: 'USD',
);
