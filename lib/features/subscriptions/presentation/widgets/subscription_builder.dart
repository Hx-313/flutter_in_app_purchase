import 'package:flutter/widgets.dart';

import '../../domain/entities/subscription_snapshot.dart';
import '../../domain/usecases/subscription_service.dart';

/// Rebuilds a host-designed widget from the latest service snapshot.
class SubscriptionBuilder extends StatelessWidget {
  const SubscriptionBuilder({
    super.key,
    required this.service,
    required this.builder,
  });

  final SubscriptionService service;
  final Widget Function(BuildContext context, SubscriptionSnapshot state)
  builder;

  @override
  Widget build(BuildContext context) => StreamBuilder<SubscriptionSnapshot>(
    stream: service.snapshotStream,
    initialData: service.snapshot,
    builder: (context, asyncSnapshot) =>
        builder(context, asyncSnapshot.data ?? service.snapshot),
  );
}
