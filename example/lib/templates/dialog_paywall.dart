import 'package:flutter/material.dart';

import '../ithx_theme.dart';
import 'paywall_offer_panel.dart';

class DialogPaywall extends StatelessWidget {
  const DialogPaywall({
    super.key,
    required this.onClose,
    this.onAccessGranted,
  });

  final VoidCallback onClose;
  final VoidCallback? onAccessGranted;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      backgroundColor: IthxPalette.canvas,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 460, maxHeight: height * .88),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
          child: PaywallOfferPanel(
            onClose: onClose,
            onAccessGranted: onAccessGranted,
            compact: true,
          ),
        ),
      ),
    );
  }
}
