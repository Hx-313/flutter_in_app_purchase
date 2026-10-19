import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_in_app_purchase_example/demo/demo_subscription_host.dart';
import 'package:flutter_in_app_purchase_example/screens/showcase_home_screen.dart';

void main() {
  testWidgets('home shows three templates and a locked feature entry', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final service = SubscriptionModule.createService(
      config: demoSubscriptionConfig,
      store: TestStore(),
      storage: SharedPreferencesSubscriptionStorageDataSource(),
    );
    await service.initialize();
    PaywallTemplate? selectedTemplate;
    var openedLockedFeature = false;

    await tester.pumpWidget(
      MaterialApp(
        home: ShowcaseHomeScreen(
          service: service,
          onOpenTemplate: (template) => selectedTemplate = template,
          onOpenLockedFeature: () => openedLockedFeature = true,
        ),
      ),
    );

    expect(find.text('SIMULATED STORE'), findsOneWidget);
    expect(find.text('01  Full-screen paywall'), findsOneWidget);
    expect(find.text('02  Paywall dialog'), findsOneWidget);
    expect(find.text('03  Paywall bottom sheet'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Try a locked feature'), findsOneWidget);

    await tester.tap(find.text('02  Paywall dialog'));
    expect(selectedTemplate, PaywallTemplate.dialog);
    await tester.tap(find.text('Try a locked feature'));
    expect(openedLockedFeature, isTrue);

    await tester.runAsync(service.dispose);
  });
}

class TestStore implements StoreDataSource {
  final _events = Stream<StorePurchase>.empty();

  @override
  bool get isAvailable => true;

  @override
  List<StoreProduct> get products => demoSubscriptionConfig.products
      .map(
        (definition) => StoreProduct(
          id: definition.id,
          title: definition.displayName ?? definition.id,
          description: 'Demo plan',
          price: r'$4.99',
          rawPrice: 4.99,
          currencyCode: 'USD',
        ),
      )
      .toList(growable: false);

  @override
  Stream<StorePurchase> get purchaseStream => _events;

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
  Future<void> dispose() async {}
}
