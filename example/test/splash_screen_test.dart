import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_in_app_purchase_example/screens/splash_screen.dart';

void main() {
  testWidgets('branded splash shows icon and ACT ETHICALLY then continues', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          duration: const Duration(milliseconds: 500),
          nextScreenBuilder: (_) => const Scaffold(body: Text('Showcase home')),
        ),
      ),
    );

    expect(find.text('ACT ETHICALLY'), findsOneWidget);
    expect(find.bySemanticsLabel('ITHX app icon'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Showcase home'), findsOneWidget);
  });
}
