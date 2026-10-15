import 'package:flutter/material.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import '../ithx_theme.dart';

class LockedFeatureScreen extends StatelessWidget {
  const LockedFeatureScreen({
    super.key,
    required this.service,
    required this.onUnlock,
  });

  final SubscriptionService service;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Private reflections')),
    body: SafeArea(
      child: SubscriptionBuilder(
        service: service,
        builder: (context, snapshot) {
          final unlocked = snapshot.hasAccess('premium');
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      unlocked
                          ? Icons.lock_open_rounded
                          : Icons.lock_outline_rounded,
                      size: 58,
                      color: IthxPalette.forest,
                      semanticLabel: unlocked
                          ? 'Feature unlocked'
                          : 'Feature locked',
                    ),
                    const SizedBox(height: 18),
                    Text(
                      unlocked
                          ? 'Your space is ready'
                          : 'A quieter space for you',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: IthxPalette.forest,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      unlocked
                          ? 'Premium access is active. Your private reflections are unlocked on this device.'
                          : 'Private reflections are part of ITHX Premium. Preview the paywall and unlock this feature with the local simulator.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: IthxPalette.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (unlocked)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: const [
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
                      )
                    else
                      FilledButton.icon(
                        onPressed: onUnlock,
                        icon: const Icon(Icons.workspace_premium_outlined),
                        label: const Text('See unlock options'),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
