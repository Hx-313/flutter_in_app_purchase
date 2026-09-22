import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/entities/subscription_config.dart';
import '../domain/entities/verification.dart';
import '../domain/repositories/subscription_repository.dart';
import '../subscription_module.dart';
import 'bloc/subscription_bloc.dart';
import 'bloc/subscription_event.dart';

/// Creates, initializes, exposes, and disposes the feature BLoC.
class SubscriptionScope extends StatelessWidget {
  const SubscriptionScope({
    super.key,
    required this.config,
    required this.child,
    this.repository,
    this.verifier,
  });

  final SubscriptionConfig config;
  final SubscriptionRepository? repository;
  final PurchaseVerifier? verifier;
  final Widget child;

  static SubscriptionBloc of(BuildContext context) =>
      context.read<SubscriptionBloc>();

  @override
  Widget build(BuildContext context) => BlocProvider<SubscriptionBloc>(
    create: (_) {
      final bloc = SubscriptionModule.createBloc(
        config: config,
        repository: repository,
        verifier: verifier,
      );
      bloc.add(const SubscriptionInitializeRequested());
      return bloc;
    },
    child: child,
  );
}
