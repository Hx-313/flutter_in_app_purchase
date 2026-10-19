import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import 'package:flutter_in_app_purchase_example/templates/subscription_page.dart';
import 'package:flutter_in_app_purchase_example/templates/subscription_plan_content.dart';

class _MemoryStorage implements SubscriptionStorage {
  @override
  Future<void> initialize(String keyPrefix) async {}

  @override
  Future<Map<String, Entitlement>> loadEntitlements() async => const {};

  @override
  Future<void> saveEntitlement(Entitlement entitlement) async {}

  @override
  Future<void> removeEntitlement(String entitlementId) async {}

  @override
  Future<List<ConsumableDelivery>> loadPendingConsumables() async => const [];

  @override
  Future<void> savePendingConsumable(ConsumableDelivery delivery) async {}

  @override
  Future<void> acknowledgeConsumable(String purchaseId) async {}

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) async => false;

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {}

  @override
  Future<void> dispose() async {}
}

class _Store implements SubscriptionStore {
  _Store([List<StoreProduct>? productList])
    : products =
          productList ??
          const [
            StoreProduct(
              id: 'pro',
              title: 'Pro Lifetime',
              description: 'Unlock everything',
              price: r'$9.99',
              rawPrice: 9.99,
              currencyCode: 'USD',
            ),
          ];

  final _updates = StreamController<StorePurchase>.broadcast();

  @override
  bool isAvailable = true;

  @override
  List<StoreProduct> products;

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
    await _withPage(
      tester,
      const [
        ProductDefinition(
          id: 'pro',
          type: ProductType.lifetime,
          entitlementId: 'premium',
        ),
      ],
      (service) async {
        expect(find.text('Pro Lifetime'), findsOneWidget);
        expect(find.text(r'$9.99'), findsOneWidget);
        expect(find.text('Restore purchases'), findsOneWidget);
      },
    );
  });

  testWidgets('rendersPlanContentOverrides', (tester) async {
    await _withPage(
      tester,
      const [
        ProductDefinition(
          id: 'pro',
          type: ProductType.lifetime,
          entitlementId: 'premium',
        ),
      ],
      (service) async {
        expect(find.text('Studio plan'), findsOneWidget);
        expect(find.text('For creative work'), findsOneWidget);
        expect(find.text('Unlimited projects'), findsOneWidget);
        expect(find.text('Priority support'), findsOneWidget);
        expect(find.text('Best value'), findsOneWidget);
        expect(find.text('Unlock Studio'), findsOneWidget);
        expect(find.text(r'$9.99'), findsOneWidget);
      },
      planContent: [
        SubscriptionPlanContent(
          productId: 'pro',
          title: 'Studio plan',
          description: 'For creative work',
          perks: const ['Unlimited projects', 'Priority support'],
          badge: 'Best value',
          purchaseLabel: 'Unlock Studio',
        ),
      ],
    );
  });

  testWidgets('fallsBackToDefinitionAndStoreMetadata', (tester) async {
    await _withPage(
      tester,
      const [
        ProductDefinition(
          id: 'pro',
          type: ProductType.lifetime,
          entitlementId: 'premium',
          displayName: 'Configured Pro',
        ),
      ],
      (service) async {
        expect(find.text('Configured Pro'), findsOneWidget);
        expect(find.text('Store description'), findsOneWidget);
      },
      storeProducts: const [
        StoreProduct(
          id: 'pro',
          title: 'Store Pro',
          description: 'Store description',
          price: r'$9.99',
          rawPrice: 9.99,
          currencyCode: 'USD',
        ),
      ],
      planContent: [SubscriptionPlanContent(productId: 'pro')],
    );
  });

  testWidgets('sortsByPriorityStably', (tester) async {
    await _withPage(
      tester,
      const [
        ProductDefinition(
          id: 'starter',
          type: ProductType.lifetime,
          entitlementId: 'starter_access',
          priority: 1,
        ),
        ProductDefinition(
          id: 'team',
          type: ProductType.lifetime,
          entitlementId: 'team_access',
          priority: 2,
        ),
        ProductDefinition(
          id: 'studio',
          type: ProductType.lifetime,
          entitlementId: 'studio_access',
          priority: 2,
        ),
      ],
      (service) async {
        final teamY = tester.getTopLeft(find.text('Team')).dy;
        final studioY = tester.getTopLeft(find.text('Studio')).dy;
        final starterY = tester.getTopLeft(find.text('Starter')).dy;
        expect(teamY, lessThan(studioY));
        expect(studioY, lessThan(starterY));
      },
      storeProducts: const [
        StoreProduct(
          id: 'starter',
          title: 'Starter',
          description: '',
          price: r'$1.00',
          rawPrice: 1,
          currencyCode: 'USD',
        ),
        StoreProduct(
          id: 'team',
          title: 'Team',
          description: '',
          price: r'$2.00',
          rawPrice: 2,
          currencyCode: 'USD',
        ),
        StoreProduct(
          id: 'studio',
          title: 'Studio',
          description: '',
          price: r'$3.00',
          rawPrice: 3,
          currencyCode: 'USD',
        ),
      ],
    );
  });
}

Future<void> _withPage(
  WidgetTester tester,
  List<ProductDefinition> products,
  Future<void> Function(SubscriptionService service) verify, {
  List<StoreProduct> storeProducts = const [],
  List<SubscriptionPlanContent> planContent = const [],
}) async {
  final service = SubscriptionModule.createService(
    config: SubscriptionConfig(products: products),
    store: _Store(storeProducts.isEmpty ? null : storeProducts),
    storage: _MemoryStorage(),
  );
  await service.initialize();
  try {
    await tester.pumpWidget(
      MaterialApp(
        home: SubscriptionPage(service: service, planContent: planContent),
      ),
    );
    await tester.pumpAndSettle();
    await verify(service);
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(service.dispose);
  }
}
