import 'package:equatable/equatable.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

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

final class SubscriptionConsumableAcknowledgementRequested
    extends SubscriptionEvent {
  const SubscriptionConsumableAcknowledgementRequested(this.purchaseId);

  final String purchaseId;

  @override
  List<Object?> get props => [purchaseId];
}

final class SubscriptionSnapshotChanged extends SubscriptionEvent {
  const SubscriptionSnapshotChanged(this.snapshot);

  final SubscriptionSnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}
