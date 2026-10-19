import 'package:flutter/material.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import '../ithx_theme.dart';
import 'paywall_offer_panel.dart';

class FullScreenPaywall extends StatelessWidget {
  const FullScreenPaywall({
    super.key,
    required this.service,
    required this.onClose,
    this.onAccessGranted,
  });

  final SubscriptionService service;
  final VoidCallback onClose;
  final VoidCallback? onAccessGranted;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: IthxPalette.deepForest,
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
            children: [
              PaywallOfferPanel(
                service: service,
                onClose: onClose,
                onAccessGranted: onAccessGranted,
                dark: true,
              ),
              const SizedBox(height: 10),
              Text(
                'ACT ETHICALLY · ITHX',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: IthxPalette.mutedOnDark,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
