import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import 'support/subscription_test_fakes.dart';

void main() {
  testWidgets(
    'first render uses the service state from earlier initialization',
    (tester) async {
      final service = createTestSubscriptionService();
      try {
        await service.initialize();
        await tester.pumpWidget(
          MaterialApp(
            home: SubscriptionBuilder(
              service: service,
              builder: (context, snapshot) => Text(snapshot.phase.name),
            ),
          ),
        );

        expect(find.text('ready'), findsOneWidget);
      } finally {
        await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
        await tester.runAsync(service.dispose);
      }
    },
  );

  testWidgets('rebuilds from service state and stops after widget removal', (
    tester,
  ) async {
    final service = createTestSubscriptionService();
    var buildCount = 0;
    try {
      await service.initialize();
      await tester.pumpWidget(
        MaterialApp(
          home: SubscriptionBuilder(
            service: service,
            builder: (context, snapshot) {
              buildCount++;
              return Text(snapshot.lastResult?.status.name ?? 'idle');
            },
          ),
        ),
      );
      expect(find.text('idle'), findsOneWidget);

      await service.purchase('not-configured');
      await tester.pump();
      expect(find.text('notAvailable'), findsOneWidget);

      final buildsBeforeRemoval = buildCount;
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await service.purchase('still-not-configured');
      await tester.pump();
      expect(buildCount, buildsBeforeRemoval);
    } finally {
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.runAsync(service.dispose);
    }
  });
}
