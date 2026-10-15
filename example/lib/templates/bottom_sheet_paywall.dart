import 'package:flutter/material.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import '../ithx_theme.dart';
import 'paywall_offer_panel.dart';

class BottomSheetPaywall extends StatelessWidget {
  const BottomSheetPaywall({
    super.key,
    required this.service,
    required this.onClose,
    this.onAccessGranted,
  });

  final SubscriptionService service;
  final VoidCallback onClose;
  final VoidCallback? onAccessGranted;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: height * .92),
        child: Material(
          color: IthxPalette.canvas,
          clipBehavior: Clip.antiAlias,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: IthxPalette.canvasBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                PaywallOfferPanel(
                  service: service,
                  onClose: onClose,
                  onAccessGranted: onAccessGranted,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
