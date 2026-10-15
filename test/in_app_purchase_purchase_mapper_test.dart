import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:flutter_in_app_purchase/features/subscriptions/data/datasources/in_app_purchase_purchase_mapper.dart';
import 'package:flutter_in_app_purchase/flutter_in_app_purchase.dart';

void main() {
  test('mapsPurchaseStatusesAndMetadata', () {
    final transactionDate = DateTime.utc(2026, 10, 14, 12, 30);
    final verificationData = iap.PurchaseVerificationData(
      localVerificationData: 'local-receipt',
      serverVerificationData: 'server-receipt',
      source: 'app_store',
    );
    final mapper = InAppPurchasePurchaseMapper();
    final purchases = [
      iap.PurchaseDetails(
        productID: 'pending-product',
        purchaseID: 'pending-id',
        transactionDate: null,
        status: iap.PurchaseStatus.pending,
        verificationData: verificationData,
      ),
      iap.PurchaseDetails(
        productID: 'purchased-product',
        purchaseID: 'purchased-id',
        transactionDate: '${transactionDate.millisecondsSinceEpoch}',
        status: iap.PurchaseStatus.purchased,
        verificationData: verificationData,
      )..pendingCompletePurchase = true,
      iap.PurchaseDetails(
        productID: 'restored-product',
        purchaseID: 'restored-id',
        transactionDate: null,
        status: iap.PurchaseStatus.restored,
        verificationData: verificationData,
      ),
      iap.PurchaseDetails(
        productID: 'canceled-product',
        purchaseID: null,
        transactionDate: null,
        status: iap.PurchaseStatus.canceled,
        verificationData: verificationData,
      ),
      iap.PurchaseDetails(
          productID: 'error-product',
          purchaseID: 'error-id',
          transactionDate: 'not-a-date',
          status: iap.PurchaseStatus.error,
          verificationData: verificationData,
        )
        ..error = iap.IAPError(
          source: 'google_play',
          code: 'billing-error',
          message: 'Billing unavailable',
          details: {'reason': 'network-unavailable'},
        ),
    ];

    final mapped = purchases.map(mapper.map).toList();

    expect(mapped.map((purchase) => purchase.status), [
      StorePurchaseStatus.pending,
      StorePurchaseStatus.purchased,
      StorePurchaseStatus.restored,
      StorePurchaseStatus.canceled,
      StorePurchaseStatus.error,
    ]);
    expect(mapped[0].productId, 'pending-product');
    expect(mapped[1].purchaseId, 'purchased-id');
    expect(mapped[1].transactionDate?.toUtc(), transactionDate);
    expect(mapped[1].pendingCompletePurchase, isTrue);
    expect(
      mapped[1].verificationData,
      const PurchaseVerificationData(
        source: 'app_store',
        serverData: 'server-receipt',
        localData: 'local-receipt',
      ),
    );
    expect(mapped[3].purchaseId, isNull);
    expect(mapped[4].transactionDate, isNull);
    expect(mapped[4].errorCode, 'billing-error');
    expect(mapped[4].errorMessage, 'Billing unavailable');
    expect(mapped[4].errorSource, 'google_play');
    expect(mapped[4].errorDetails, {'reason': 'network-unavailable'});
  });
}
