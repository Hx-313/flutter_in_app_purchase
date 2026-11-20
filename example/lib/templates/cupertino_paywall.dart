import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Tooltip;
import 'package:flutter/services.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import '../ithx_theme.dart';

/// Native iOS-style Cupertino Paywall template.
///
/// Demonstrates iOS 17/18 Human Interface Guidelines (HIG):
/// - Inset grouped list style for subscription plans
/// - Cupertino dynamic colors and SF-style typography
/// - Native [CupertinoButton.filled] call-to-action
/// - Haptic feedback on plan selection
class CupertinoPaywall extends StatefulWidget {
  const CupertinoPaywall({
    super.key,
    required this.onClose,
    this.onAccessGranted,
  });

  final VoidCallback onClose;
  final VoidCallback? onAccessGranted;

  @override
  State<CupertinoPaywall> createState() => _CupertinoPaywallState();
}

class _CupertinoPaywallState extends State<CupertinoPaywall> {
  String? _selectedProductId;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return CupertinoTheme(
      data: const CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: IthxPalette.forest,
      ),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: height * .92),
          child: Container(
            decoration: const BoxDecoration(
              color: CupertinoColors.systemGroupedBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                20 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: SubscriptionView(
                builder: (context, state) {
                  final products = state.products.toList()
                    ..sort(
                      (a, b) => (b.definition?.priority ?? 0).compareTo(
                        a.definition?.priority ?? 0,
                      ),
                    );
                  final selectedProduct = products
                      .cast<StoreProduct?>()
                      .firstWhere(
                        (product) => product?.id == _selectedProductId,
                        orElse: () => products.cast<StoreProduct?>().firstWhere(
                          (product) => product?.id == 'pro_annual',
                          orElse: () => products.firstOrNull,
                        ),
                      );
                  final accessActive = state.hasAccessTo('premium');
                  final statusMessage = state.statusMessage;
                  final statusIsError =
                      state.lastResult?.status.isError ?? false;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey4,
                            borderRadius: BorderRadius.circular(2.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CupertinoIcons.sparkles,
                                  color: IthxPalette.forest,
                                  size: 20,
                                ),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'ITHX PREMIUM',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: IthxPalette.forest,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Tooltip(
                            message: 'Close paywall',
                            child: CupertinoButton(
                              padding: EdgeInsets.zero,
                              onPressed: widget.onClose,
                              child: const Icon(
                                CupertinoIcons.xmark_circle_fill,
                                color: CupertinoColors.systemGrey3,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        accessActive
                            ? 'You’re unlocked.'
                            : 'Upgrade to Unlimited',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.label,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        accessActive
                            ? 'Premium access is active on this device.'
                            : 'Full access to all templates, priority updates, and cloud sync.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (products.isNotEmpty) ...[
                        for (final product in products) ...[
                          _buildPlanItem(
                            product: product,
                            isSelected:
                                (selectedProduct?.id ?? products.first.id) ==
                                product.id,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                      const SizedBox(height: 12),
                      CupertinoButton.filled(
                        borderRadius: BorderRadius.circular(14),
                        onPressed: accessActive
                            ? (widget.onAccessGranted ?? widget.onClose)
                            : state.isBusy || selectedProduct == null
                            ? null
                            : () => state.purchase(selectedProduct.id),
                        child: state.isPurchasing
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : Text(
                                accessActive
                                    ? 'Continue to feature'
                                    : 'Unlock premium',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: state.isBusy ? null : state.restore,
                        child: state.isRestoring
                            ? const CupertinoActivityIndicator()
                            : const Text(
                                'Restore purchases',
                                style: TextStyle(
                                  color: IthxPalette.forest,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                      if (statusMessage != null) ...[
                        const SizedBox(height: 6),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            statusMessage,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: statusIsError
                                  ? CupertinoColors.destructiveRed
                                  : CupertinoColors.secondaryLabel,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      const Text(
                        'Simulated store · No real payment is made',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: CupertinoColors.tertiaryLabel,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanItem({
    required StoreProduct product,
    required bool isSelected,
  }) {
    final title = product.definition?.displayName ?? product.title;
    return Semantics(
      button: true,
      selected: isSelected,
      label: 'Select $title plan, ${product.price}',
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedProductId = product.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? IthxPalette.forest
                  : CupertinoColors.systemGrey5,
              width: isSelected ? 2 : 1,
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
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: CupertinoColors.label,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isSelected
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.circle,
                    color: isSelected
                        ? IthxPalette.forest
                        : CupertinoColors.systemGrey3,
                    size: 22,
                  ),
                ],
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                product.price,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
