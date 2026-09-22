import 'dart:async';

import 'package:equatable/equatable.dart';

import '../entities/entitlement.dart';
import '../entities/product_definition.dart';
import '../entities/purchase_result.dart';
import '../entities/subscription_config.dart';
import '../entities/subscription_types.dart';
import '../entities/store_product.dart';
import '../entities/store_purchase.dart';
import '../entities/verification.dart';
import '../repositories/subscription_repository.dart';

/// Result returned by a restore operation.
final class RestoreResult extends Equatable {
  const RestoreResult({
    required this.status,
    this.entitlement,
    this.message,
  });

  final RestoreStatus status;
  final Entitlement? entitlement;
  final String? message;

  bool get restored => status == RestoreStatus.restored;

  @override
  List<Object?> get props => [status, entitlement, message];
}

/// Domain use case coordinating store events, verification, and entitlements.
final class SubscriptionService {
  SubscriptionService({
    required this.config,
    required this.repository,
    this.verifier,
  });

  final SubscriptionConfig config;
  final SubscriptionRepository repository;
  final PurchaseVerifier? verifier;

  final _entitlementController =
      StreamController<Map<String, Entitlement>>.broadcast();
  final _resultController = StreamController<PurchaseResult>.broadcast();

  StreamSubscription<StorePurchase>? _purchaseSubscription;
  Timer? _expiryTimer;
  Future<void> _processing = Future<void>.value();
  Map<String, Entitlement> _entitlements = <String, Entitlement>{};
  List<StoreProduct> _products = const <StoreProduct>[];
  bool _initialized = false;
  bool _disposed = false;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  bool _isRefreshing = false;
  bool _restoreFoundPurchase = false;
  Entitlement? _restoredEntitlement;

  bool get isInitialized => _initialized;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoring => _isRestoring;
  bool get isStoreAvailable => repository.isAvailable;
  List<StoreProduct> get products => List.unmodifiable(_products);
  Map<String, Entitlement> get entitlements => Map.unmodifiable(_entitlements);
  Stream<Map<String, Entitlement>> get entitlementStream =>
      _entitlementController.stream;
  Stream<PurchaseResult> get purchaseResultStream =>
      _resultController.stream;

  Entitlement? get currentEntitlement =>
      config.effectiveDefaultEntitlementId == null
      ? null
      : _entitlements[config.effectiveDefaultEntitlementId];

  bool get hasAccess => currentEntitlement?.hasAccess ?? false;

  Future<void> initialize() async {
    _ensureNotDisposed();
    if (_initialized) return;

    _purchaseSubscription = repository.purchaseStream.listen(_queuePurchase);
    try {
      await repository.initialize(
        config.products,
        config.storageKeyPrefix,
      );
      _entitlements = await repository.loadEntitlements();
      await _checkExpiry();
      _products = repository.products
          .map((product) {
            final definition = config.getProduct(product.id);
            return definition == null
                ? null
                : product.withDefinition(definition);
          })
          .whereType<StoreProduct>()
          .toList(growable: false);

      _initialized = true;
      _expiryTimer = Timer.periodic(config.expiryCheckInterval, (_) {
        unawaited(_checkExpiry());
      });
      _emitEntitlements();
    } catch (_) {
      await _purchaseSubscription?.cancel();
      _purchaseSubscription = null;
      rethrow;
    }
  }

  Future<bool> purchase(String productId) async {
    _ensureInitialized();
    final definition = config.getProduct(productId);
    if (definition == null) {
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.notAvailable,
          productId: productId,
          message: 'Product is not configured.',
        ),
      );
      return false;
    }
    if (!isStoreAvailable) {
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.notAvailable,
          productId: productId,
          message: 'The store is unavailable.',
        ),
      );
      return false;
    }
    final entitlementId = definition.entitlementId;
    if (entitlementId != null &&
        _entitlements[entitlementId]?.hasAccess == true) {
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.alreadyOwned,
          productId: productId,
          entitlement: _entitlements[entitlementId],
          message: 'The entitlement is already active.',
        ),
      );
      return false;
    }

    _isPurchasing = true;
    try {
      await repository.purchase(productId);
      return true;
    } catch (error) {
      _isPurchasing = false;
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.error,
          productId: productId,
          message: error.toString(),
        ),
      );
      return false;
    }
  }

  Future<RestoreResult> restore() async {
    _ensureInitialized();
    _isRestoring = true;
    _restoreFoundPurchase = false;
    _restoredEntitlement = null;
    try {
      await repository.restore();
      final existing = await repository.queryExistingPurchases();
      for (final purchase in existing) {
        _queuePurchase(purchase);
      }
      if (config.restoreSettleTimeout > Duration.zero) {
        await Future<void>.delayed(config.restoreSettleTimeout);
      } else {
        await Future<void>.delayed(Duration.zero);
      }
      await _processing;
      final entitlement = _restoredEntitlement ?? currentEntitlement;
      if (_restoreFoundPurchase && entitlement != null) {
        return RestoreResult(
          status: RestoreStatus.restored,
          entitlement: entitlement,
        );
      }
      return const RestoreResult(status: RestoreStatus.none);
    } catch (error) {
      return RestoreResult(status: RestoreStatus.failure, message: '$error');
    } finally {
      _isRestoring = false;
    }
  }

  Future<void> refresh() async {
    _ensureInitialized();
    _isRefreshing = true;
    try {
      final existing = await repository.queryExistingPurchases();
      for (final purchase in existing) {
        _queuePurchase(purchase);
      }
      await _processing;
    } finally {
      _isRefreshing = false;
    }
  }

  StoreProduct? getProduct(String productId) {
    for (final product in _products) {
      if (product.id == productId) return product;
    }
    return null;
  }

  Entitlement? getEntitlement(String entitlementId) =>
      _entitlements[entitlementId];

  Future<void> _processPurchase(StorePurchase purchase) async {
    final definition = config.getProduct(purchase.productId);
    if (definition == null) {
      await _completeIfNeeded(purchase);
      return;
    }

    if (purchase.status == StorePurchaseStatus.pending) {
      if (!_shouldSuppressResults) {
        _emitResult(
          PurchaseResult(
            status: PurchaseStatus.pending,
            productId: purchase.productId,
          ),
        );
      }
      return;
    }

    try {
      if (purchase.status == StorePurchaseStatus.canceled) {
        _isPurchasing = false;
        if (!_shouldSuppressResults) {
          _emitResult(
            PurchaseResult(
              status: PurchaseStatus.canceled,
              productId: purchase.productId,
            ),
          );
        }
        return;
      }
      if (purchase.status == StorePurchaseStatus.error) {
        _isPurchasing = false;
        if (!_shouldSuppressResults) {
          _emitResult(
            PurchaseResult(
              status: PurchaseStatus.error,
              productId: purchase.productId,
              errorCode: purchase.errorCode,
              message: purchase.errorMessage,
            ),
          );
        }
        return;
      }

      final purchaseId = _purchaseId(purchase);
      if (await repository.isPurchaseProcessed(purchaseId)) return;

      final verification = await _verify(definition, purchase);
      if (verification.status != VerificationStatus.valid) {
        if (verification.status == VerificationStatus.invalid &&
            definition.entitlementId != null) {
          final existing = _entitlements[definition.entitlementId];
          if (existing != null) {
            final revoked = existing.copyWith(
              isActive: false,
              state: verification.state,
              isExpiryKnown: true,
              lastVerifiedAt: DateTime.now(),
            );
            _entitlements = <String, Entitlement>{
              ..._entitlements,
              revoked.id: revoked,
            };
            await repository.saveEntitlement(revoked);
            _emitEntitlements();
          }
        }
        _isPurchasing = false;
        if (!_shouldSuppressResults) {
          _emitResult(
            PurchaseResult(
              status: PurchaseStatus.verificationFailed,
              productId: purchase.productId,
              storePurchaseId: purchaseId,
              message: verification.message,
            ),
          );
        }
        return;
      }

      await repository.markPurchaseProcessed(purchaseId);
      Entitlement? entitlement;
      if (definition.grantsEntitlement) {
        entitlement = _createEntitlement(definition, verification, purchase);
        _entitlements = <String, Entitlement>{
          ..._entitlements,
          entitlement.id: entitlement,
        };
        await repository.saveEntitlement(entitlement);
        _emitEntitlements();
        if (_isRestoring) _restoredEntitlement = entitlement;
      }
      _restoreFoundPurchase = _restoreFoundPurchase || _isRestoring;
      _isPurchasing = false;
      if (!_shouldSuppressResults) {
        _emitResult(
          PurchaseResult(
            status: purchase.status == StorePurchaseStatus.restored
                ? PurchaseStatus.restored
                : PurchaseStatus.success,
            productId: purchase.productId,
            entitlement: entitlement,
            storePurchaseId: purchaseId,
          ),
        );
      }
    } finally {
      await _completeIfNeeded(purchase);
    }
  }

  Future<VerificationResult> _verify(
    ProductDefinition definition,
    StorePurchase purchase,
  ) async {
    if (config.verificationMode == VerificationMode.serverVerified) {
      final configuredVerifier = verifier;
      if (configuredVerifier == null) {
        return const VerificationResult.unavailable(
          message: 'A purchase verifier is required in server-verified mode.',
        );
      }
      return configuredVerifier.verify(
        PurchaseVerificationRequest(product: definition, purchase: purchase),
      );
    }

    if (definition.isPermanent) {
      return const VerificationResult.valid(isExpiryKnown: true);
    }
    if (definition.type == ProductType.nonRenewing) {
      return VerificationResult.valid(
        expiresAt: DateTime.now().add(definition.duration!),
        isExpiryKnown: true,
      );
    }
    if (definition.type == ProductType.autoRenewing) {
      return const VerificationResult.valid(isExpiryKnown: false);
    }
    return const VerificationResult.valid(isExpiryKnown: false);
  }

  Entitlement _createEntitlement(
    ProductDefinition definition,
    VerificationResult verification,
    StorePurchase purchase,
  ) {
    final state = verification.state;
    return Entitlement(
      id: definition.entitlementId!,
      productId: definition.id,
      productType: definition.type,
      isActive: state.hasAccess,
      state: state,
      expiresAt: verification.expiresAt,
      isExpiryKnown: verification.isExpiryKnown,
      willRenew: verification.willRenew ||
          definition.type == ProductType.autoRenewing,
      grantedAt: purchase.transactionDate ?? DateTime.now(),
      lastVerifiedAt: config.verificationMode == VerificationMode.serverVerified
          ? DateTime.now()
          : null,
    );
  }

  Future<void> _checkExpiry() async {
    if (_entitlements.isEmpty) return;
    final now = DateTime.now();
    var changed = false;
    final updated = <String, Entitlement>{..._entitlements};
    for (final entry in _entitlements.entries) {
      final entitlement = entry.value;
      if (entitlement.isActive &&
          entitlement.isExpiryKnown &&
          entitlement.expiresAt != null &&
          now.isAfter(entitlement.expiresAt!)) {
        updated[entry.key] = entitlement.copyWith(
          isActive: false,
          state: SubscriptionState.expired,
        );
        await repository.saveEntitlement(updated[entry.key]!);
        changed = true;
      }
    }
    if (changed) {
      _entitlements = updated;
      _emitEntitlements();
    }
  }

  void _queuePurchase(StorePurchase purchase) {
    _processing = _processing.then((_) => _processPurchase(purchase)).catchError(
      (Object error, StackTrace stackTrace) {
        _isPurchasing = false;
        if (!_shouldSuppressResults) {
          _emitResult(
            PurchaseResult(
              status: PurchaseStatus.error,
              productId: purchase.productId,
              message: '$error',
            ),
          );
        }
      },
    );
  }

  Future<void> _completeIfNeeded(StorePurchase purchase) async {
    if (purchase.pendingCompletePurchase) {
      await repository.complete(purchase);
    }
  }

  String _purchaseId(StorePurchase purchase) =>
      purchase.purchaseId ??
      '${purchase.productId}:${purchase.transactionDate?.microsecondsSinceEpoch ?? 0}';

  void _emitEntitlements() {
    if (!_entitlementController.isClosed) {
      _entitlementController.add(Map.unmodifiable(_entitlements));
    }
  }

  void _emitResult(PurchaseResult result) {
    if (!_resultController.isClosed) _resultController.add(result);
  }

  bool get _shouldSuppressResults => _isRestoring || _isRefreshing;

  void _ensureInitialized() {
    _ensureNotDisposed();
    if (!_initialized) {
      throw StateError('SubscriptionService is not initialized');
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) throw StateError('SubscriptionService is disposed');
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _expiryTimer?.cancel();
    await _purchaseSubscription?.cancel();
    await _processing;
    await repository.dispose();
    await _entitlementController.close();
    await _resultController.close();
    _initialized = false;
  }
}
