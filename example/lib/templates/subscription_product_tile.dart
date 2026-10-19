import 'package:flutter/material.dart';

import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';
import 'subscription_plan_content.dart';
import 'subscription_strings.dart';
import 'subscription_theme.dart';

/// Default product selection tile used by [SubscriptionPage].
class SubscriptionProductTile extends StatelessWidget {
  const SubscriptionProductTile({
    super.key,
    required this.product,
    required this.onPurchase,
    required this.strings,
    required this.theme,
    this.content,
    this.busy = false,
  });

  final StoreProduct product;
  final VoidCallback onPurchase;
  final SubscriptionStrings strings;
  final SubscriptionTheme theme;
  final SubscriptionPlanContent? content;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title =
        content?.title ?? product.definition?.displayName ?? product.title;
    final description = content?.description ?? product.description;
    final purchaseLabel = content?.purchaseLabel ?? strings.purchase;
    return Card(
      color: theme.card(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.cardRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (content?.badge case final badge?
                      when badge.isNotEmpty) ...[
                    Chip(
                      label: Text(badge),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description),
                  ],
                  if (content?.perks.isNotEmpty == true) ...[
                    const SizedBox(height: 8),
                    ...content!.perks.map(
                      (perk) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: theme.accent(context),
                            ),
                            const SizedBox(width: 6),
                            Expanded(child: Text(perk)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    product.price,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: theme.accent(context),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: busy ? null : onPurchase,
              style: FilledButton.styleFrom(
                backgroundColor: theme.accent(context),
                foregroundColor: colorScheme.onPrimary,
              ),
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(purchaseLabel),
            ),
          ],
        ),
      ),
    );
  }
}
