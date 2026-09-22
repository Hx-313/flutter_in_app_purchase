import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/subscription_types.dart';
import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_event.dart';
import '../bloc/subscription_state.dart';
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
    required this.strings,
    required this.theme,
    this.onManageSubscription,
  });

  final SubscriptionStrings strings;
  final SubscriptionTheme theme;
  final VoidCallback? onManageSubscription;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionSnapshot>(
        builder: (context, state) {
          if (state.phase == SubscriptionPhase.idle ||
              state.phase == SubscriptionPhase.initializing) {
            return SubscriptionLoadingShimmer(
              padding: theme.contentPadding,
            );
          }

          if (state.phase == SubscriptionPhase.unavailable) {
            return SubscriptionMessageState(
              message: strings.storeUnavailable,
              actionLabel: strings.retry,
              onAction: () => context.read<SubscriptionBloc>().add(
                const SubscriptionInitializeRequested(),
              ),
            );
          }
          if (state.phase == SubscriptionPhase.failure) {
            return SubscriptionMessageState(
              message: state.errorMessage ?? strings.purchaseError,
              actionLabel: strings.retry,
              onAction: () => context.read<SubscriptionBloc>().add(
                const SubscriptionInitializeRequested(),
              ),
            );
          }

          final defaultEntitlement = state.defaultEntitlementId == null
              ? null
              : state.entitlements[state.defaultEntitlementId];
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
                ...state.products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SubscriptionProductTile(
                      product: product,
                      strings: strings,
                      theme: theme,
                      busy: state.isPurchasing,
                      onPurchase: () => context.read<SubscriptionBloc>().add(
                        SubscriptionPurchaseRequested(product.id),
                      ),
                    ),
                  ),
                ),
              OutlinedButton(
                onPressed: state.isRestoring
                    ? null
                    : () => context.read<SubscriptionBloc>().add(
                        const SubscriptionRestoreRequested(),
                      ),
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
