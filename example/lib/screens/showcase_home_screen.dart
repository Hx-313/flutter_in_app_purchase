import 'package:flutter/material.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import '../ithx_theme.dart';

enum PaywallTemplate { fullScreen, dialog, bottomSheet }

class ShowcaseHomeScreen extends StatelessWidget {
  const ShowcaseHomeScreen({
    super.key,
    required this.service,
    required this.onOpenTemplate,
    required this.onOpenLockedFeature,
  });

  final SubscriptionService service;
  final ValueChanged<PaywallTemplate> onOpenTemplate;
  final VoidCallback onOpenLockedFeature;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: SubscriptionBuilder(
        service: service,
        builder: (context, snapshot) => ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
          children: [
            Semantics(
              image: true,
              label: 'ITHX ACT ETHICALLY wordmark',
              child: Image.asset(
                'assets/branding/ithx-wordmark-horizontal-lockup.png',
                height: 76,
                alignment: Alignment.centerLeft,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _Badge(
                  label: 'SIMULATED STORE',
                  foreground: IthxPalette.forest,
                  background: IthxPalette.cream,
                ),
                const SizedBox(width: 10),
                _Badge(
                  label: snapshot.hasAccess('premium')
                      ? 'PREMIUM ACTIVE'
                      : 'PREMIUM LOCKED',
                  foreground: snapshot.hasAccess('premium')
                      ? IthxPalette.success
                      : IthxPalette.muted,
                  background: Colors.white,
                ),
              ],
            ),
            const SizedBox(height: 26),
            Text(
              'Build your paywall',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: IthxPalette.forest,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Three app-owned layouts. One shared entitlement flow. Choose a template to preview.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: IthxPalette.muted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            _TemplateCard(
              number: '01',
              title: 'Full-screen paywall',
              description: 'A complete destination for plan comparison.',
              icon: Icons.fullscreen_rounded,
              onTap: () => onOpenTemplate(PaywallTemplate.fullScreen),
            ),
            _TemplateCard(
              number: '02',
              title: 'Paywall dialog',
              description: 'A focused offer over the current screen.',
              icon: Icons.web_asset_rounded,
              onTap: () => onOpenTemplate(PaywallTemplate.dialog),
            ),
            _TemplateCard(
              number: '03',
              title: 'Paywall bottom sheet',
              description: 'A compact offer that keeps context visible.',
              icon: Icons.vertical_align_top_rounded,
              onTap: () => onOpenTemplate(PaywallTemplate.bottomSheet),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onOpenLockedFeature,
              icon: const Icon(Icons.lock_outline_rounded),
              label: const Text('Try a locked feature'),
              style: OutlinedButton.styleFrom(
                foregroundColor: IthxPalette.forest,
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: IthxPalette.forestBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _stateDescription(snapshot),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: IthxPalette.muted),
            ),
          ],
        ),
      ),
    ),
  );

  String _stateDescription(SubscriptionSnapshot snapshot) {
    if (snapshot.phase == SubscriptionPhase.initializing ||
        snapshot.phase == SubscriptionPhase.idle) {
      return 'Loading demo products…';
    }
    if (snapshot.phase == SubscriptionPhase.failure) {
      return snapshot.errorMessage ?? 'Demo products could not be loaded.';
    }
    return snapshot.hasAccess('premium')
        ? 'Premium access is active on this device.'
        : 'Purchases run locally and unlock this sample feature.';
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String number;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: IthxPalette.forest,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: IthxPalette.cream),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$number  $title',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: IthxPalette.muted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 17),
          ],
        ),
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: IthxPalette.canvasBorder),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: foreground,
        letterSpacing: 0.7,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}
