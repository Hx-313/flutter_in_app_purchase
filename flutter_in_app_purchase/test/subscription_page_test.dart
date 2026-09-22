import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

class _Storage implements SubscriptionStorage {
  @override
  Future<void> initialize(String keyPrefix) async {}

  @override
  Future<Map<String, Entitlement>> loadEntitlements() async => const {};

  @override
  Future<void> saveEntitlement(Entitlement entitlement) async {}

  @override
  Future<void> removeEntitlement(String entitlementId) async {}

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) async => false;

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {}

  @override
  Future<void> dispose() async {}
}

class _Store implements SubscriptionStore {
  final _updates = StreamController<StorePurchase>.broadcast();

  @override
  bool isAvailable = true;

  @override
  List<StoreProduct> products = const [
    StoreProduct(
      id: 'pro',
      title: 'Pro Lifetime',
      description: 'Unlock everything',
      price: r'$9.99',
      rawPrice: 9.99,
      currencyCode: 'USD',
    ),
  ];

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
  Future<void> dispose() => _updates.close();
}

void main() {
  testWidgets('renders configured products and restore action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SubscriptionScope(
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
            store: _Store(),
            storage: _Storage(),
          ),
          child: const SubscriptionPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Pro Lifetime'), findsOneWidget);
    expect(find.text(r'$9.99'), findsOneWidget);
    expect(find.text('Restore purchases'), findsOneWidget);
  });
}
