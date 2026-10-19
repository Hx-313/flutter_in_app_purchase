import 'package:flutter/material.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import 'demo/demo_subscription_host.dart';
import 'ithx_theme.dart';
import 'screens/locked_feature_screen.dart';
import 'screens/showcase_home_screen.dart';
import 'screens/splash_screen.dart';
import 'templates/bottom_sheet_paywall.dart';
import 'templates/dialog_paywall.dart';
import 'templates/full_screen_paywall.dart';

void main() {
  runApp(
    DemoSubscriptionHost(
      builder: (context, service) => MaterialApp(
        title: 'ITHX · ACT ETHICALLY',
        theme: buildIthxTheme(),
        home: SplashScreen(
          nextScreenBuilder: (_) => _ShowcaseRouter(service: service),
        ),
      ),
    ),
  );
}

class _ShowcaseRouter extends StatelessWidget {
  const _ShowcaseRouter({required this.service});

  final SubscriptionService service;

  @override
  Widget build(BuildContext context) => ShowcaseHomeScreen(
    service: service,
    onOpenTemplate: (template) => _openTemplate(context, template),
    onOpenLockedFeature: () => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => LockedFeatureScreen(
          service: service,
          onUnlock: () => _openTemplate(context, PaywallTemplate.fullScreen),
        ),
      ),
    ),
  );

  void _openTemplate(BuildContext context, PaywallTemplate template) {
    switch (template) {
      case PaywallTemplate.fullScreen:
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (routeContext) => FullScreenPaywall(
              service: service,
              onClose: () => Navigator.of(routeContext).pop(),
              onAccessGranted: () => Navigator.of(routeContext).pop(),
            ),
          ),
        );
      case PaywallTemplate.dialog:
        showDialog<void>(
          context: context,
          builder: (dialogContext) => DialogPaywall(
            service: service,
            onClose: () => Navigator.of(dialogContext).pop(),
            onAccessGranted: () => Navigator.of(dialogContext).pop(),
          ),
        );
      case PaywallTemplate.bottomSheet:
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => BottomSheetPaywall(
            service: service,
            onClose: () => Navigator.of(sheetContext).pop(),
            onAccessGranted: () => Navigator.of(sheetContext).pop(),
          ),
        );
    }
  }
}
