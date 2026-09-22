import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:in_app_purchase_android/in_app_purchase_android.dart' as android;
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart' as storekit;
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart' as wrappers;

import '../../domain/entities/product_definition.dart';
import '../../domain/entities/store_product.dart';
import '../../domain/entities/store_purchase.dart';
import 'store_data_source.dart';

/// Adapter over Flutter's Android Billing and Apple StoreKit APIs.
final class InAppPurchaseStoreDataSource implements StoreDataSource {
  InAppPurchaseStoreDataSource({iap.InAppPurchase? instance})
    : _iap = instance ?? iap.InAppPurchase.instance;

  final iap.InAppPurchase _iap;
  final _purchaseController = StreamController<StorePurchase>.broadcast();
  final _nativePurchases = <String, iap.PurchaseDetails>{};
  final _detailsById = <String, iap.ProductDetails>{};
  final _definitionsById = <String, ProductDefinition>{};

  StreamSubscription<List<iap.PurchaseDetails>>? _purchaseSubscription;
  wrappers.SKPaymentQueueDelegateWrapper? _paymentQueueDelegate;
  List<StoreProduct> _products = const <StoreProduct>[];
  bool _isAvailable = false;
  bool _disposed = false;

  @override
  bool get isAvailable => _isAvailable;

  @override
  List<StoreProduct> get products => List.unmodifiable(_products);

  @override
  Stream<StorePurchase> get purchaseStream => _purchaseController.stream;

  @override
  Future<void> initialize(List<ProductDefinition> products) async {
    _ensureSupportedPlatform();
    if (_purchaseSubscription != null) return;

    _definitionsById
      ..clear()
      ..addEntries(products.map((product) => MapEntry(product.id, product)));

    _purchaseSubscription = _iap.purchaseStream.listen((purchases) {
      for (final purchase in purchases) {
        _publish(purchase);
      }
    });

    if (_isApple) {
      _paymentQueueDelegate = _PaymentQueueDelegate();
      await _iap
          .getPlatformAddition<storekit.InAppPurchaseStoreKitPlatformAddition>()
          .setDelegate(_paymentQueueDelegate);
    }

    _isAvailable = await _iap.isAvailable();
    if (!_isAvailable) return;

    final response = await _iap.queryProductDetails(
      products.map((product) => product.id).toSet(),
    );
    if (response.error != null) {
      throw StateError(response.error!.message);
    }
    if (response.notFoundIDs.isNotEmpty && response.productDetails.isEmpty) {
      throw StateError(
        'No configured products were found: ${response.notFoundIDs.join(', ')}',
      );
    }

    _detailsById
      ..clear()
      ..addEntries(
        response.productDetails.map((product) => MapEntry(product.id, product)),
      );
    _products = response.productDetails
        .map(
          (product) => StoreProduct(
            id: product.id,
            title: product.title,
            description: product.description,
            price: product.price,
            rawPrice: product.rawPrice,
            currencyCode: product.currencyCode,
            definition: _definitionsById[product.id],
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> purchase(String productId) async {
    _ensureAvailable();
    final details = _detailsById[productId];
    if (details == null) throw StateError('Product is not loaded: $productId');

    final definition = _definitionsById[productId];
    final purchaseParam = _isAndroid
        ? android.GooglePlayPurchaseParam(
            productDetails: details,
            changeSubscriptionParam: null,
          )
        : iap.PurchaseParam(productDetails: details);

    final accepted = definition?.isConsumable == true
        ? await _iap.buyConsumable(purchaseParam: purchaseParam)
        : await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    if (!accepted) throw StateError('The store rejected the purchase request');
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  @override
  Future<List<StorePurchase>> queryExistingPurchases() async {
    if (!_isAndroid || !_isAvailable) return const <StorePurchase>[];
    final addition = _iap
        .getPlatformAddition<android.InAppPurchaseAndroidPlatformAddition>();
    final response = await addition.queryPastPurchases();
    if (response.error != null) throw StateError(response.error!.message);
    return response.pastPurchases.map((purchase) {
      final mapped = _mapPurchase(purchase);
      _nativePurchases[_key(mapped)] = purchase;
      return mapped;
    }).toList(growable: false);
  }

  @override
  Future<void> complete(StorePurchase purchase) async {
    final native = _nativePurchases[_key(purchase)];
    if (native == null || !native.pendingCompletePurchase) return;
    await _iap.completePurchase(native);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    if (_isApple) {
      await _iap
          .getPlatformAddition<storekit.InAppPurchaseStoreKitPlatformAddition>()
          .setDelegate(null);
      _paymentQueueDelegate = null;
    }
    await _purchaseController.close();
  }

  void _publish(iap.PurchaseDetails purchase) {
    final mapped = _mapPurchase(purchase);
    _nativePurchases[_key(mapped)] = purchase;
    if (!_purchaseController.isClosed) _purchaseController.add(mapped);
  }

  StorePurchase _mapPurchase(iap.PurchaseDetails purchase) => StorePurchase(
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
    errorCode: purchase.error?.code,
    errorMessage: purchase.error?.message,
  );

  String _key(StorePurchase purchase) =>
      purchase.purchaseId ?? '${purchase.productId}:${purchase.transactionDate}';

  DateTime? _parseDate(String? value) {
    if (value == null) return null;
    final milliseconds = int.tryParse(value);
    return milliseconds == null
        ? DateTime.tryParse(value)
        : DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }

  void _ensureSupportedPlatform() {
    if (!_isAndroid && !_isApple) {
      throw UnsupportedError(
        'In-app purchases are supported on Android, iOS, and macOS only.',
      );
    }
  }

  void _ensureAvailable() {
    if (!_isAvailable) throw StateError('The store is unavailable');
  }

  bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;
  bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}

/// Backward-compatible public name for the default store adapter.
typedef InAppPurchaseStore = InAppPurchaseStoreDataSource;

final class _PaymentQueueDelegate implements wrappers.SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    wrappers.SKPaymentTransactionWrapper transaction,
    wrappers.SKStorefrontWrapper storefront,
  ) => true;

  @override
  bool shouldShowPriceConsent() => false;
}
