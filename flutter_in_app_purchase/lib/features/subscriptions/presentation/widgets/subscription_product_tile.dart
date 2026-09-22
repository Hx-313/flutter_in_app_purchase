import 'package:flutter/material.dart';

import '../../domain/entities/store_product.dart';
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
    this.busy = false,
  });

  final StoreProduct product;
  final VoidCallback onPurchase;
  final SubscriptionStrings strings;
  final SubscriptionTheme theme;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
                  Text(
                    product.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (product.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(product.description),
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
                  : Text(strings.purchase),
            ),
          ],
        ),
      ),
    );
  }
}
