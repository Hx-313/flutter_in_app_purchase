import 'package:equatable/equatable.dart';

import '../../domain/entities/purchase_result.dart';

/// Events accepted by [SubscriptionBloc].
sealed class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();
}

final class SubscriptionInitializeRequested extends SubscriptionEvent {
  const SubscriptionInitializeRequested();

  @override
  List<Object?> get props => const [];
}

final class SubscriptionPurchaseRequested extends SubscriptionEvent {
  const SubscriptionPurchaseRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

final class SubscriptionRestoreRequested extends SubscriptionEvent {
  const SubscriptionRestoreRequested();

  @override
  List<Object?> get props => const [];
}

final class SubscriptionRefreshRequested extends SubscriptionEvent {
  const SubscriptionRefreshRequested();

  @override
  List<Object?> get props => const [];
}

/// Internal event used to bridge the use-case entitlement stream into BLoC.
final class SubscriptionEntitlementsChanged extends SubscriptionEvent {
  const SubscriptionEntitlementsChanged();

  @override
  List<Object?> get props => const [];
}

/// Internal event used to bridge purchase results into BLoC state.
final class SubscriptionResultReceived extends SubscriptionEvent {
  const SubscriptionResultReceived(this.result);

  final PurchaseResult result;

  @override
  List<Object?> get props => [result];
}
