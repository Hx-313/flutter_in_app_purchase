import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

class _MemoryStorage implements SubscriptionStorage {
  final entitlements = <String, Entitlement>{};
  final processed = <String>{};

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
  Future<bool> isPurchaseProcessed(String purchaseId) async =>
      processed.contains(purchaseId);

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {
    processed.add(purchaseId);
  }

  @override
  Future<void> dispose() async {}
}

class _ScopeStore implements SubscriptionStore {
  _ScopeStore(this._products);

  final List<StoreProduct> _products;
  final _updates = StreamController<StorePurchase>.broadcast();
  bool disposed = false;

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
  Future<void> restore() async {}

  @override
  Future<List<StorePurchase>> queryExistingPurchases() async => const [];

  @override
  Future<void> complete(StorePurchase purchase) async {}

  @override
  Future<void> dispose() async {
    disposed = true;
    await _updates.close();
  }
}

void main() {
  testWidgets('scope initializes and exposes ready controller state', (
    tester,
  ) async {
    final store = _ScopeStore([
      const StoreProduct(
        id: 'pro',
        title: 'Pro',
        description: 'Full access',
        price: r'$9.99',
        rawPrice: 9.99,
        currencyCode: 'USD',
      ),
    ]);

    await tester.pumpWidget(
      SubscriptionScope(
        config: SubscriptionConfig(
          products: const [
            ProductDefinition(
              id: 'pro',
              type: ProductType.lifetime,
              entitlementId: 'premium',
            ),
          ],
        ),
        repository: SubscriptionRepositoryImpl(
          store: store,
          storage: _MemoryStorage(),
        ),
        child: Builder(
          builder: (context) => Text(
            SubscriptionScope.of(context).state.phase.name,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('ready'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(store.disposed, isTrue);
  });
}
