import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_in_app_purchase_example/demo/demo_subscription_host.dart';
import 'package:flutter_in_app_purchase_example/demo/simulated_store_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('host initializes and exposes its local demo service', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    late SubscriptionService service;
    await tester.pumpWidget(
      DemoSubscriptionHost(
        builder: (context, value) {
          service = value;
          return MaterialApp(
            home: SubscriptionBuilder(
              service: value,
              builder: (context, snapshot) =>
                  Text('${snapshot.phase.name}:${snapshot.products.length}'),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ready:3'), findsOneWidget);
    expect(service.config.storageKeyPrefix, 'ithx.example.demo');

    await tester.runAsync(service.dispose);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test(
    'simulated purchase survives service recreation and restores access',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = SimulatedStoreDataSource();
      final service = _createService(store);
      await service.initialize();
      expect(service.products, hasLength(3));

      final success = service.purchaseResultStream.firstWhere(
        (result) => result.status == PurchaseStatus.success,
      );
      await service.purchase('pro_lifetime');
      await success.timeout(const Duration(seconds: 1));
      expect(service.hasAccess, isTrue);
      expect(store.completionCount, 1);
      await service.dispose();

      final restoredService = _createService(SimulatedStoreDataSource());
      await restoredService.initialize();
      final result = await restoredService.restore();

      expect(result.status, RestoreStatus.restored);
      expect(restoredService.hasAccess, isTrue);
      await restoredService.dispose();
    },
  );
}

SubscriptionService _createService(SimulatedStoreDataSource store) =>
    SubscriptionModule.createService(
      config: demoSubscriptionConfig,
      store: store,
      storage: SharedPreferencesSubscriptionStorageDataSource(),
    );
