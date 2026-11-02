import 'dart:async';

import '../../domain/entities/consumable_delivery.dart';
import '../../domain/entities/purchase_result.dart';
import '../../domain/usecases/subscription_service.dart' show RestoreResult;
import 'subscription_view_state.dart';

/// Builds host-facing text for a purchase result, for localization or tone.
typedef SubscriptionMessageBuilder = String Function(PurchaseResult result);

/// Lifecycle hooks for [SubscriptionProvider].
///
/// Every callback is optional. A host that only sells subscriptions can pass
/// none of them and still get correct behavior and state.
final class SubscriptionCallbacks {
  const SubscriptionCallbacks({
    this.onReady,
    this.onStoreUnavailable,
    this.onInitializationFailed,
    this.beforePurchase,
    this.onPurchaseSuccess,
    this.onPurchasePending,
    this.onPurchaseCanceled,
    this.onPurchaseError,
    this.onRestoreFinished,
    this.onConsumablePurchased,
    this.onAccessChanged,
  });

  /// Fired once the service is initialized and the store is available.
  final void Function(SubscriptionViewState state)? onReady;

  /// Fired when the platform store is unavailable on this device.
  final void Function()? onStoreUnavailable;

  /// Fired when service initialization throws.
  final void Function(Object error, StackTrace stackTrace)?
  onInitializationFailed;

  /// Veto hook evaluated before the store is contacted.
  ///
  /// Return `false` to cancel the purchase before anything is charged.
  final FutureOr<bool> Function(String productId)? beforePurchase;

  /// Fired for a completed purchase or restore.
  final void Function(PurchaseResult result)? onPurchaseSuccess;

  /// Fired when the store defers the payment (for example Ask to Buy).
  final void Function(PurchaseResult result)? onPurchasePending;

  /// Fired when the user cancels a purchase.
  final void Function(PurchaseResult result)? onPurchaseCanceled;

  /// Fired for a store error or a failed verification.
  final void Function(PurchaseResult result)? onPurchaseError;

  /// Fired when a `restore()` call finishes.
  final void Function(RestoreResult result)? onRestoreFinished;

  /// Fulfills a staged consumable delivery.
  ///
  /// Return `true` after the item has been granted so the package
  /// acknowledges, consumes, and finishes the store transaction. Return
  /// `false`, or throw, to keep the delivery pending so it is retried on a
  /// later launch (or through `SubscriptionController.retryPendingConsumables`).
  final FutureOr<bool> Function(ConsumableDelivery delivery)?
  onConsumablePurchased;

  /// Fired when the default entitlement's access changes.
  final void Function(bool hasAccess)? onAccessChanged;
}
