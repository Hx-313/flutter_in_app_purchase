import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_in_app_purchase_example/demo/demo_subscription_host.dart';
import 'package:flutter_in_app_purchase_example/demo/simulated_store_data_source.dart';
import 'package:flutter_in_app_purchase_example/templates/bottom_sheet_paywall.dart';
import 'package:flutter_in_app_purchase_example/templates/dialog_paywall.dart';
import 'package:flutter_in_app_purchase_example/templates/full_screen_paywall.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('all templates fit narrow screens at increased text scale', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final kind in ['screen', 'dialog', 'sheet']) {
      final service = _service();
      await service.initialize();
      var closed = false;
      try {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(1.65)),
                child: switch (kind) {
                  'screen' => FullScreenPaywall(
                    service: service,
                    onClose: () => closed = true,
                  ),
                  'dialog' => DialogPaywall(
                    service: service,
                    onClose: () => closed = true,
                  ),
                  _ => BottomSheetPaywall(
                    service: service,
                    onClose: () => closed = true,
                  ),
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Unlock premium'), findsOneWidget, reason: kind);
        expect(find.text('Restore purchases'), findsOneWidget, reason: kind);
        expect(
          find.bySemanticsLabel(RegExp('Select Annual plan')),
          findsOneWidget,
        );
        final layoutError = tester.takeException();
        expect(layoutError, isNull, reason: kind);

        await tester.ensureVisible(find.byTooltip('Close paywall'));
        await tester.tap(find.byTooltip('Close paywall'));
        expect(closed, isTrue, reason: kind);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(service.dispose);
      }
    }
  });
}

SubscriptionService _service() => SubscriptionModule.createService(
  config: demoSubscriptionConfig,
  store: SimulatedStoreDataSource(),
  storage: SharedPreferencesSubscriptionStorageDataSource(),
);
