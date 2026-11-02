import 'package:flutter/material.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import '../ithx_theme.dart';

/// Premium content gated with `PremiumGate`.
///
/// The screen declares which entitlement unlocks the content and what to show
/// when it is missing; access checks, loading, and refresh stay in the package.
class LockedFeatureScreen extends StatelessWidget {
  const LockedFeatureScreen({super.key, required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Private reflections')),
    body: SafeArea(
      child: PremiumGate(
        entitlementId: 'premium',
        child: const _UnlockedBody(),
        locked: (context) => _LockedBody(onUnlock: onUnlock),
      ),
    ),
  );
}

class _LockedBody extends StatelessWidget {
  const _LockedBody({required this.onUnlock});

  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) => _Body(
    children: [
      const Icon(
        Icons.lock_outline_rounded,
        size: 58,
        color: IthxPalette.forest,
        semanticLabel: 'Feature locked',
      ),
      const SizedBox(height: 18),
      Text(
        'A quieter space for you',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: IthxPalette.forest,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Private reflections are part of ITHX Premium. Preview the paywall and unlock this feature with the local simulator.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: IthxPalette.muted, height: 1.5),
      ),
      const SizedBox(height: 24),
      FilledButton.icon(
        onPressed: onUnlock,
        icon: const Icon(Icons.workspace_premium_outlined),
        label: const Text('See unlock options'),
      ),
    ],
  );
}

class _UnlockedBody extends StatelessWidget {
  const _UnlockedBody();

  @override
  Widget build(BuildContext context) => _Body(
    children: [
      const Icon(
        Icons.lock_open_rounded,
        size: 58,
        color: IthxPalette.forest,
        semanticLabel: 'Feature unlocked',
      ),
      const SizedBox(height: 18),
      Text(
        'Your space is ready',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: IthxPalette.forest,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'Premium access is active. Your private reflections are unlocked on this device.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: IthxPalette.muted, height: 1.5),
      ),
      const SizedBox(height: 24),
      const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 30),
              SizedBox(height: 10),
              Text('Unlocked sample content'),
              SizedBox(height: 8),
              Text(
                'Take a breath. Write what matters. Choose one kind next step.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _Body extends StatelessWidget {
  const _Body({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    ),
  );
}
