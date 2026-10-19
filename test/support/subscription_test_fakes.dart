import 'dart:async';

import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

const testLifetimeDefinition = ProductDefinition(
  id: 'pro_lifetime',
  type: ProductType.lifetime,
  entitlementId: 'premium',
);

const testConsumableDefinition = ProductDefinition(
  id: 'coins_100',
  type: ProductType.consumable,
);

const testLifetimeProduct = StoreProduct(
  id: 'pro_lifetime',
  title: 'Lifetime',
  description: 'Lifetime access',
  price: r'$29.99',
  rawPrice: 29.99,
  currencyCode: 'USD',
);

const testConsumableProduct = StoreProduct(
  id: 'coins_100',
  title: '100 coins',
  description: 'A coin pack',
  price: r'$1.99',
  rawPrice: 1.99,
  currencyCode: 'USD',
);

final class TestSubscriptionStorage implements SubscriptionStorageDataSource {
  final Map<String, Entitlement> entitlements = {};
  final Set<String> processedPurchases = {};
  final Map<String, ConsumableDelivery> pending = {};

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
      List.of(pending.values);

  @override
  Future<void> savePendingConsumable(ConsumableDelivery delivery) async {
    pending.putIfAbsent(delivery.purchaseId, () => delivery);
  }

  @override
  Future<void> acknowledgeConsumable(String purchaseId) async {
    pending.remove(purchaseId);
  }

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) async =>
      processedPurchases.contains(purchaseId);

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {
    processedPurchases.add(purchaseId);
  }

  @override
  Future<void> dispose() async {}
}

final class TestSubscriptionStore implements StoreDataSource {
  TestSubscriptionStore({this.available = true});

  bool available;
  bool failInitialization = false;
  Completer<void>? restoreGate;
  List<StorePurchase> restorePurchases = const [];
  List<StorePurchase> existingPurchases = const [];
  int completionCount = 0;

  final _updates = StreamController<StorePurchase>.broadcast();

  @override
  bool get isAvailable => available;

  @override
  List<StoreProduct> products = const [
    testLifetimeProduct,
    testConsumableProduct,
  ];

  @override
  Stream<StorePurchase> get purchaseStream => _updates.stream;

  @override
  Future<void> initialize(List<ProductDefinition> products) async {
    if (failInitialization) throw StateError('initialization failed');
  }

  @override
  Future<void> purchase(String productId) async {}

  @override
  Future<void> restore() async {
    await restoreGate?.future;
    for (final purchase in restorePurchases) {
      _updates.add(purchase);
    }
  }

  @override
  Future<List<StorePurchase>> queryExistingPurchases() async =>
      existingPurchases;

  @override
  Future<void> complete(StorePurchase purchase) async {
    completionCount++;
  }

  @override
  Future<void> dispose() => _updates.close();

  void emit(StorePurchase purchase) => _updates.add(purchase);
}

SubscriptionService createTestSubscriptionService({
  TestSubscriptionStore? store,
  TestSubscriptionStorage? storage,
  List<ProductDefinition>? products,
}) {
  return SubscriptionService(
    config: SubscriptionConfig(
      products: products ?? const [testLifetimeDefinition],
    ),
    repository: SubscriptionRepositoryImpl(
      store: store ?? TestSubscriptionStore(),
      storage: storage ?? TestSubscriptionStorage(),
    ),
  );
}

Future<void> flushSubscriptionEvents() => Future<void>.delayed(Duration.zero);
