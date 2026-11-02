import 'package:flutter/widgets.dart';

import '../entities/subscription_view_state.dart';
import 'subscription_provider.dart';

/// Rebuilds host-designed UI from the nearest [SubscriptionProvider] state.
///
/// This widget owns no subscription logic. It is a pure consumer: the provider
/// handles initialization, listening, purchases, restores, and disposal.
class SubscriptionView extends StatelessWidget {
  const SubscriptionView({super.key, required this.builder});

  /// Builds the host UI from an immutable, guarded state.
  final Widget Function(BuildContext context, SubscriptionViewState state)
  builder;

  @override
  Widget build(BuildContext context) {
    final controller = SubscriptionProvider.of(context);
    return ValueListenableBuilder<SubscriptionViewState>(
      valueListenable: controller.state,
      builder: (context, state, _) => builder(context, state),
    );
  }
}
