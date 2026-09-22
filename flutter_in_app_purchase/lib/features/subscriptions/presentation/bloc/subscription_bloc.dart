import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entitlement.dart';
import '../../domain/entities/purchase_result.dart';
import '../../domain/entities/subscription_types.dart';
import '../../domain/usecases/subscription_service.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

/// BLoC translating subscription use-case streams and commands into UI state.
final class SubscriptionBloc
    extends Bloc<SubscriptionEvent, SubscriptionSnapshot> {
  SubscriptionBloc({required this.service})
    : super(
        SubscriptionSnapshot(
          defaultEntitlementId: service.config.effectiveDefaultEntitlementId,
        ),
      ) {
    on<SubscriptionInitializeRequested>(_onInitialize);
    on<SubscriptionPurchaseRequested>(_onPurchase);
    on<SubscriptionRestoreRequested>(_onRestore);
    on<SubscriptionRefreshRequested>(_onRefresh);
    on<SubscriptionEntitlementsChanged>(_onEntitlementsChanged);
    on<SubscriptionResultReceived>(_onResultReceived);

    _entitlementSubscription = service.entitlementStream.listen((_) {
      if (!isClosed) add(const SubscriptionEntitlementsChanged());
    });
    _resultSubscription = service.purchaseResultStream.listen((result) {
      if (!isClosed) add(SubscriptionResultReceived(result));
    });
  }

  final SubscriptionService service;
  StreamSubscription<Map<String, Entitlement>>? _entitlementSubscription;
  StreamSubscription<PurchaseResult>? _resultSubscription;

  Future<void> _onInitialize(
    SubscriptionInitializeRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    if (state.phase == SubscriptionPhase.initializing) return;
    emit(
      state.copyWith(
        phase: SubscriptionPhase.initializing,
        errorMessage: null,
      ),
    );
    try {
      await service.initialize();
      emit(_syncedState(SubscriptionPhase.ready));
    } catch (error) {
      emit(
        state.copyWith(
          phase: SubscriptionPhase.failure,
          errorMessage: '$error',
          isStoreAvailable: service.isStoreAvailable,
        ),
      );
    }
  }

  Future<void> _onPurchase(
    SubscriptionPurchaseRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    emit(state.copyWith(isPurchasing: true));
    await service.purchase(event.productId);
    emit(_syncedState(state.phase));
  }

  Future<void> _onRestore(
    SubscriptionRestoreRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    emit(state.copyWith(isRestoring: true));
    final result = await service.restore();
    emit(
      _syncedState(state.phase).copyWith(
        isRestoring: false,
        lastRestoreStatus: result.status,
        lastResult: PurchaseResult(
          status: result.status == RestoreStatus.restored
              ? PurchaseStatus.restored
              : PurchaseStatus.error,
          message: result.message,
          entitlement: result.entitlement,
        ),
      ),
    );
  }

  Future<void> _onRefresh(
    SubscriptionRefreshRequested event,
    Emitter<SubscriptionSnapshot> emit,
  ) async {
    await service.refresh();
    emit(_syncedState(state.phase));
  }

  void _onEntitlementsChanged(
    SubscriptionEntitlementsChanged event,
    Emitter<SubscriptionSnapshot> emit,
  ) => emit(_syncedState(state.phase));

  void _onResultReceived(
    SubscriptionResultReceived event,
    Emitter<SubscriptionSnapshot> emit,
  ) => emit(
    _syncedState(state.phase).copyWith(
      lastResult: event.result,
      lastRestoreStatus: null,
    ),
  );

  SubscriptionSnapshot _syncedState(SubscriptionPhase phase) =>
      state.copyWith(
        phase: phase,
        products: service.products,
        entitlements: service.entitlements,
        isPurchasing: service.isPurchasing,
        isRestoring: service.isRestoring,
        isStoreAvailable: service.isStoreAvailable,
      );

  @override
  Future<void> close() async {
    await _entitlementSubscription?.cancel();
    await _resultSubscription?.cancel();
    await service.dispose();
    return super.close();
  }
}
