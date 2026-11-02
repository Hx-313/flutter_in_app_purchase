import 'package:flutter/widgets.dart';

import 'subscription_view.dart';

/// Shows [child] only while its entitlement grants access.
///
/// A host drops this around premium content and supplies the locked UI; no
/// access checks, loading states, or refresh logic are needed.
class PremiumGate extends StatelessWidget {
  const PremiumGate({
    super.key,
    required this.child,
    this.entitlementId,
    this.locked,
    this.loading,
  });

  /// Content shown while access is granted.
  final Widget child;

  /// Entitlement to check. Defaults to the provider's default entitlement.
  final String? entitlementId;

  /// Content shown while access is missing.
  final WidgetBuilder? locked;

  /// Content shown while the service is still initializing.
  final WidgetBuilder? loading;

  @override
  Widget build(BuildContext context) => SubscriptionView(
    builder: (context, state) {
      if (state.isLoading) {
        return loading?.call(context) ?? const SizedBox.shrink();
      }
      final id = entitlementId ?? state.defaultEntitlementId;
      if (id != null && state.hasAccessTo(id)) return child;
      return locked?.call(context) ?? const SizedBox.shrink();
    },
  );
}
