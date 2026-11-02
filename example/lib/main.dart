import 'package:flutter/material.dart';

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
      builder: (context, _) => MaterialApp(
        title: 'ITHX · ACT ETHICALLY',
        theme: buildIthxTheme(),
        home: const SplashScreen(nextScreenBuilder: _buildShowcaseRouter),
      ),
    ),
  );
}

Widget _buildShowcaseRouter(BuildContext context) => const _ShowcaseRouter();

class _ShowcaseRouter extends StatelessWidget {
  const _ShowcaseRouter();

  @override
  Widget build(BuildContext context) => ShowcaseHomeScreen(
    onOpenTemplate: (template) => _openTemplate(context, template),
    onOpenLockedFeature: () => Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => LockedFeatureScreen(
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
              onClose: () => Navigator.of(routeContext).pop(),
              onAccessGranted: () => Navigator.of(routeContext).pop(),
            ),
          ),
        );
      case PaywallTemplate.dialog:
        showDialog<void>(
          context: context,
          builder: (dialogContext) => DialogPaywall(
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
            onClose: () => Navigator.of(sheetContext).pop(),
            onAccessGranted: () => Navigator.of(sheetContext).pop(),
          ),
        );
    }
  }
}
