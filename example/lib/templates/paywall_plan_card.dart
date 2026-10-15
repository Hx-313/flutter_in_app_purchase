import 'package:flutter/material.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import '../ithx_theme.dart';

class PaywallPlanCard extends StatelessWidget {
  const PaywallPlanCard({
    super.key,
    required this.product,
    required this.selected,
    required this.onSelected,
    this.dark = false,
  });

  final StoreProduct product;
  final bool selected;
  final bool dark;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final title = product.definition?.displayName ?? product.title;
    final description = product.description;
    final foreground = dark ? IthxPalette.cream : IthxPalette.forest;
    final border = dark ? IthxPalette.forestBorder : IthxPalette.canvasBorder;
    final background = dark ? IthxPalette.forest : Colors.white;

    return Semantics(
      button: true,
      selected: selected,
      label: 'Select $title plan, ${product.price}',
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onSelected,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: selected ? background : background.withValues(alpha: .6),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? IthxPalette.cream : border,
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: dark ? IthxPalette.cream : IthxPalette.forest,
                        semanticLabel: selected ? 'Selected' : 'Not selected',
                      ),
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: dark
                            ? IthxPalette.mutedOnDark
                            : IthxPalette.muted,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    product.price,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
