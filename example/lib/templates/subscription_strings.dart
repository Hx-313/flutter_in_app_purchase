import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

/// Default English copy used by the bundled UI.
final class SubscriptionStrings {
  const SubscriptionStrings({
    this.title = 'Choose your plan',
    this.restorePurchases = 'Restore purchases',
    this.restoringPurchases = 'Restoring purchases…',
    this.active = 'Active',
    this.expired = 'Expired',
    this.gracePeriod = 'Grace period',
    this.paused = 'Paused',
    this.canceled = 'Canceled',
    this.refunded = 'Refunded',
    this.inactive = 'Inactive',
    this.expiryUnknown = 'Renewal status is managed by the store.',
    this.manageSubscription = 'Manage subscription',
    this.purchase = 'Purchase',
    this.loading = 'Loading subscriptions…',
    this.storeUnavailable = 'The store is unavailable.',
    this.noProducts = 'No subscription products are available.',
    this.retry = 'Retry',
    this.restoreNone = 'No purchases were found to restore.',
    this.restoreSuccess = 'Purchases restored successfully.',
    this.purchasePending = 'Your purchase is pending.',
    this.purchaseCanceled = 'Purchase canceled.',
    this.purchaseSuccess = 'Purchase successful.',
    this.purchaseError = 'Purchase could not be completed.',
  });

  final String title;
  final String restorePurchases;
  final String restoringPurchases;
  final String active;
  final String expired;
  final String gracePeriod;
  final String paused;
  final String canceled;
  final String refunded;
  final String inactive;
  final String expiryUnknown;
  final String manageSubscription;
  final String purchase;
  final String loading;
  final String storeUnavailable;
  final String noProducts;
  final String retry;
  final String restoreNone;
  final String restoreSuccess;
  final String purchasePending;
  final String purchaseCanceled;
  final String purchaseSuccess;
  final String purchaseError;

  String resultMessage(PurchaseResult result, {RestoreStatus? restoreStatus}) =>
      result.message ??
      (switch (result.status) {
        PurchaseStatus.pending => purchasePending,
        PurchaseStatus.canceled => purchaseCanceled,
        PurchaseStatus.restored =>
          restoreStatus == RestoreStatus.none ? restoreNone : restoreSuccess,
        PurchaseStatus.success => purchaseSuccess,
        _ => purchaseError,
      });

  String expiresAt(DateTime value) => 'Expires $value';
}
