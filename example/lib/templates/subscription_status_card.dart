import 'package:flutter/material.dart';

import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';
import 'subscription_strings.dart';
import 'subscription_theme.dart';

/// Displays current durable access and verified lifecycle details.
class SubscriptionStatusCard extends StatelessWidget {
  const SubscriptionStatusCard({
    super.key,
    required this.entitlement,
    required this.strings,
    required this.theme,
    this.onManageSubscription,
  });

  final Entitlement entitlement;
  final SubscriptionStrings strings;
  final SubscriptionTheme theme;
  final VoidCallback? onManageSubscription;

  @override
  Widget build(BuildContext context) {
    final stateLabel = switch (entitlement.state) {
      SubscriptionState.active => strings.active,
      SubscriptionState.expired => strings.expired,
      SubscriptionState.gracePeriod => strings.gracePeriod,
      SubscriptionState.paused => strings.paused,
      SubscriptionState.canceled => strings.canceled,
      SubscriptionState.refunded => strings.refunded,
      SubscriptionState.none => strings.inactive,
    };
    final detail = entitlement.hasDetailedLifecycle
        ? entitlement.expiresAt == null
              ? null
              : strings.expiresAt(entitlement.expiresAt!)
        : strings.expiryUnknown;

    return Card(
      color: theme.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stateLabel, style: Theme.of(context).textTheme.titleLarge),
            if (detail != null) ...[const SizedBox(height: 8), Text(detail)],
            if (onManageSubscription != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onManageSubscription,
                child: Text(strings.manageSubscription),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
