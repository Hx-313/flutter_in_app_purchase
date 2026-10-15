import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

import 'subscription_event.dart';

/// Translates subscription service commands into optional BLoC state.
final class SubscriptionBloc
    extends Bloc<SubscriptionEvent, SubscriptionSnapshot> {
  SubscriptionBloc({required this.service}) : super(service.snapshot) {
    on<SubscriptionInitializeRequested>(_onInitialize);
    on<SubscriptionPurchaseRequested>(_onPurchase);
    on<SubscriptionRestoreRequested>(_onRestore);
    on<SubscriptionRefreshRequested>(_onRefresh);
    on<SubscriptionConsumableAcknowledgementRequested>(_onAcknowledge);
    on<SubscriptionSnapshotChanged>((event, emit) => emit(event.snapshot));

    _snapshotSubscription = service.snapshotStream.listen((snapshot) {
      if (!isClosed) add(SubscriptionSnapshotChanged(snapshot));
    });
  }

  final SubscriptionService service;
  late final StreamSubscription<SubscriptionSnapshot> _snapshotSubscription;

  /// Dispatches a purchase request.
  void purchase(String productId) =>
      add(SubscriptionPurchaseRequested(productId));

  /// Dispatches a restore request.
  void restore() => add(const SubscriptionRestoreRequested());

  /// Dispatches a store reconciliation request.
  void refresh() => add(const SubscriptionRefreshRequested());

  /// Acknowledges a consumable after the host has fulfilled it.
  void acknowledgeConsumablePurchase(String purchaseId) =>
      add(SubscriptionConsumableAcknowledgementRequested(purchaseId));

  Future<void> _onInitialize(
    SubscriptionInitializeRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    try {
      await service.initialize();
    } catch (_) {
      // The service publishes failure details through its snapshot stream.
    }
  }

  Future<void> _onPurchase(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    await service.purchase(event.productId);
  }

  Future<void> _onRestore(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    await service.restore();
  }

  Future<void> _onRefresh(
    SubscriptionRefreshRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    try {
      await service.refresh();
    } catch (error) {
      emit(state.copyWith(errorMessage: '$error'));
    }
  }

  Future<void> _onAcknowledge(
    SubscriptionConsumableAcknowledgementRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    try {
      await service.acknowledgeConsumablePurchase(event.purchaseId);
    } catch (error) {
      emit(state.copyWith(errorMessage: '$error'));
    }
  }

  @override
  Future<void> close() async {
    await _snapshotSubscription.cancel();
    await service.dispose();
    await super.close();
  }
}
