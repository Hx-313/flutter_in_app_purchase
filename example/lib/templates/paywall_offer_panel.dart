import 'package:flutter/material.dart';
import 'package:smart_inapp_purchase/smart_inapp_purchase.dart';

import '../ithx_theme.dart';
import 'paywall_plan_card.dart';

/// Paywall UI built with the hands-off `SubscriptionView` API.
///
/// The panel renders state and calls guarded commands; it never creates,
/// initializes, listens to, or disposes a service.
class PaywallOfferPanel extends StatefulWidget {
  const PaywallOfferPanel({
    super.key,
    required this.onClose,
    this.dark = false,
    this.compact = false,
    this.onAccessGranted,
  });

  final VoidCallback onClose;
  final VoidCallback? onAccessGranted;
  final bool dark;
  final bool compact;

  @override
  State<PaywallOfferPanel> createState() => _PaywallOfferPanelState();
}

class _PaywallOfferPanelState extends State<PaywallOfferPanel> {
  String? _selectedProductId;

  @override
  Widget build(BuildContext context) => SubscriptionView(
    builder: (context, state) {
      final products = state.products.toList()
        ..sort(
          (a, b) => (b.definition?.priority ?? 0).compareTo(
            a.definition?.priority ?? 0,
          ),
        );
      final selectedProduct = products.cast<StoreProduct?>().firstWhere(
        (product) => product?.id == _selectedProductId,
        orElse: () => products.cast<StoreProduct?>().firstWhere(
          (product) => product?.id == 'pro_annual',
          orElse: () => products.firstOrNull,
        ),
      );
      final foreground = widget.dark ? IthxPalette.cream : IthxPalette.forest;
      final muted = widget.dark ? IthxPalette.mutedOnDark : IthxPalette.muted;
      final accessActive = state.hasAccessTo('premium');
      final statusMessage = state.statusMessage;
      final statusIsError = state.lastResult?.status.isError ?? false;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _WordmarkChip(dark: widget.dark)),
              IconButton(
                tooltip: 'Close paywall',
                onPressed: widget.onClose,
                icon: Icon(Icons.close_rounded, color: foreground),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            accessActive ? 'You’re unlocked.' : 'Make room for your best work.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: foreground,
              height: 1.12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            accessActive
                ? 'Premium is active on this device. Your sample feature is ready.'
                : 'Thoughtful tools for clearer choices, calmer focus, and meaningful progress.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: muted, height: 1.45),
          ),
          if (!widget.compact) ...[
            const SizedBox(height: 18),
            _BenefitLine(
              label: 'One subscription powers every template',
              dark: widget.dark,
            ),
            _BenefitLine(
              label: 'Restore access on this device',
              dark: widget.dark,
            ),
          ],
          const SizedBox(height: 18),
          if (products.isEmpty)
            Text(
              'Demo plans are still loading.',
              style: TextStyle(color: muted),
            )
          else
            for (final product in products) ...[
              PaywallPlanCard(
                product: product,
                selected:
                    (selectedProduct?.id ?? products.first.id) == product.id,
                dark: widget.dark,
                onSelected: () =>
                    setState(() => _selectedProductId = product.id),
              ),
              const SizedBox(height: 9),
            ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: accessActive
                ? (widget.onAccessGranted ?? widget.onClose)
                : state.isBusy || selectedProduct == null
                ? null
                : () => state.purchase(selectedProduct.id),
            style: FilledButton.styleFrom(
              backgroundColor: widget.dark
                  ? IthxPalette.cream
                  : IthxPalette.forest,
              foregroundColor: widget.dark
                  ? IthxPalette.forest
                  : IthxPalette.cream,
              minimumSize: const Size.fromHeight(54),
            ),
            child: state.isPurchasing
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(accessActive ? 'Continue to feature' : 'Unlock premium'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: state.isBusy ? null : state.restore,
            child: Text(
              state.isRestoring ? 'Restoring…' : 'Restore purchases',
              style: TextStyle(color: foreground),
            ),
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 6),
            Semantics(
              liveRegion: true,
              child: Text(
                statusMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusIsError
                      ? (widget.dark
                            ? const Color(0xFFFFB4AB)
                            : IthxPalette.danger)
                      : muted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            'Simulated store · No real payment is made',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: muted, letterSpacing: .3),
          ),
        ],
      );
    },
  );
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine({required this.label, required this.dark});

  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(
      children: [
        Icon(
          Icons.check_circle_rounded,
          size: 18,
          color: dark ? IthxPalette.cream : IthxPalette.success,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: dark ? IthxPalette.mutedOnDark : IthxPalette.muted,
            ),
          ),
        ),
      ],
    ),
  );
}

class _WordmarkChip extends StatelessWidget {
  const _WordmarkChip({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(
        Icons.auto_awesome_rounded,
        size: 18,
        color: IthxPalette.success,
      ),
      const SizedBox(width: 7),
      Flexible(
        child: Text(
          'ITHX PREMIUM',
          softWrap: true,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: dark ? IthxPalette.cream : IthxPalette.forest,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}
