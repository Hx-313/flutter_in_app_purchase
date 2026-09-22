import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/subscription_bloc.dart';
import '../bloc/subscription_state.dart';

/// Rebuilds a custom canvas from the package's immutable subscription state.
class SubscriptionBuilder extends StatelessWidget {
  const SubscriptionBuilder({
    super.key,
    required this.builder,
  });

  final Widget Function(BuildContext context, SubscriptionSnapshot state)
  builder;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SubscriptionBloc, SubscriptionSnapshot>(
        builder: builder,
      );
}
