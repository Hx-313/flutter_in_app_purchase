import 'package:in_app_purchase/in_app_purchase.dart' as iap;

import '../../domain/entities/store_purchase.dart';

/// Maps plugin purchase details into the package's store-neutral value.
final class InAppPurchasePurchaseMapper {
  const InAppPurchasePurchaseMapper();

  StorePurchase map(iap.PurchaseDetails purchase) => StorePurchase(
    productId: purchase.productID,
    purchaseId: purchase.purchaseID,
    transactionDate: _parseDate(purchase.transactionDate),
    status: switch (purchase.status) {
      iap.PurchaseStatus.pending => StorePurchaseStatus.pending,
      iap.PurchaseStatus.purchased => StorePurchaseStatus.purchased,
      iap.PurchaseStatus.restored => StorePurchaseStatus.restored,
      iap.PurchaseStatus.canceled => StorePurchaseStatus.canceled,
      iap.PurchaseStatus.error => StorePurchaseStatus.error,
    },
    verificationData: PurchaseVerificationData(
      source: purchase.verificationData.source,
      serverData: purchase.verificationData.serverVerificationData,
      localData: purchase.verificationData.localVerificationData,
    ),
    pendingCompletePurchase: purchase.pendingCompletePurchase,
    errorSource: purchase.error?.source,
    errorCode: purchase.error?.code,
    errorMessage: purchase.error?.message,
    errorDetails: purchase.error?.details,
  );

  DateTime? _parseDate(String? value) {
    if (value == null) return null;
    final milliseconds = int.tryParse(value);
    return milliseconds == null
        ? DateTime.tryParse(value)
        : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
}
