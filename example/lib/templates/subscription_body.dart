import 'package:flutter/material.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import 'subscription_plan_content.dart';
import 'subscription_loading_shimmer.dart';
import 'subscription_message_state.dart';
import 'subscription_product_tile.dart';
import 'subscription_status_card.dart';
import 'subscription_strings.dart';
import 'subscription_theme.dart';

/// Orchestrates the subscription page layout from BLoC state.
class SubscriptionBody extends StatelessWidget {
  const SubscriptionBody({
    super.key,
    required this.service,
    required this.strings,
    required this.theme,
    this.onManageSubscription,
    this.planContent = const [],
  });

  final SubscriptionService service;
  final SubscriptionStrings strings;
  final SubscriptionTheme theme;
  final VoidCallback? onManageSubscription;
  final List<SubscriptionPlanContent> planContent;

  @override
  Widget build(BuildContext context) => SubscriptionBuilder(
    service: service,
    builder: (context, state) {
      if (state.phase == SubscriptionPhase.idle ||
          state.phase == SubscriptionPhase.initializing) {
        return SubscriptionLoadingShimmer(padding: theme.contentPadding);
      }

      if (state.phase == SubscriptionPhase.unavailable) {
        return SubscriptionMessageState(
          message: strings.storeUnavailable,
          actionLabel: strings.retry,
          onAction: () => _retry(service),
        );
      }
      if (state.phase == SubscriptionPhase.failure) {
        return SubscriptionMessageState(
          message: state.errorMessage ?? strings.purchaseError,
          actionLabel: strings.retry,
          onAction: () => _retry(service),
        );
      }

      final defaultEntitlement = state.defaultEntitlementId == null
          ? null
          : state.entitlements[state.defaultEntitlementId];
      final products = state.products.asMap().entries.toList()
        ..sort((first, second) {
          final firstPriority = first.value.definition?.priority ?? 0;
          final secondPriority = second.value.definition?.priority ?? 0;
          final priorityOrder = secondPriority.compareTo(firstPriority);
          return priorityOrder != 0
              ? priorityOrder
              : first.key.compareTo(second.key);
        });
      final contentByProductId = <String, SubscriptionPlanContent>{};
      for (final content in planContent) {
        contentByProductId.putIfAbsent(content.productId, () => content);
      }
      return ListView(
        padding: theme.contentPadding,
        children: [
          Text(
            strings.title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (defaultEntitlement != null) ...[
            const SizedBox(height: 16),
            SubscriptionStatusCard(
              entitlement: defaultEntitlement,
              strings: strings,
              theme: theme,
              onManageSubscription: onManageSubscription,
            ),
          ],
          if (state.lastResult != null) ...[
            const SizedBox(height: 12),
            Text(
              strings.resultMessage(
                state.lastResult!,
                restoreStatus: state.lastRestoreStatus,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (state.products.isEmpty)
            Text(strings.noProducts)
          else
            ...products.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SubscriptionProductTile(
                  content: contentByProductId[entry.value.id],
                  product: entry.value,
                  strings: strings,
                  theme: theme,
                  busy: state.isPurchasing,
                  onPurchase: () => service.purchase(entry.value.id),
                ),
              ),
            ),
          OutlinedButton(
            onPressed: state.isRestoring ? null : () => service.restore(),
            child: Text(
              state.isRestoring
                  ? strings.restoringPurchases
                  : strings.restorePurchases,
            ),
          ),
        ],
      );
    },
  );
}

Future<void> _retry(SubscriptionService service) async {
  try {
    await service.initialize();
  } catch (_) {
    // The service snapshot already contains the initialization failure.
  }
}
