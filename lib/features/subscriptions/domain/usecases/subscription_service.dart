import 'dart:async';

import 'package:equatable/equatable.dart';

import '../entities/entitlement.dart';
import '../entities/consumable_delivery.dart';
import '../entities/product_definition.dart';
import '../entities/purchase_result.dart';
import '../entities/subscription_config.dart';
import '../entities/subscription_types.dart';
import '../entities/store_product.dart';
import '../entities/store_purchase.dart';
import '../entities/subscription_snapshot.dart';
import '../entities/verification.dart';
import '../repositories/subscription_repository.dart';

/// Result returned by a restore operation.
final class RestoreResult extends Equatable {
  const RestoreResult({required this.status, this.entitlement, this.message});

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
  final _consumableDeliveryController =
      StreamController<List<ConsumableDelivery>>.broadcast();
  final _snapshotController =
      StreamController<SubscriptionSnapshot>.broadcast();

  StreamSubscription<StorePurchase>? _purchaseSubscription;
  Timer? _expiryTimer;
  Future<void>? _processing;
  final Set<String> _reconciliationPurchaseIds = <String>{};
  Map<String, Entitlement> _entitlements = <String, Entitlement>{};
  List<ConsumableDelivery> _pendingConsumables = const [];
  List<StoreProduct> _products = const <StoreProduct>[];
  bool _initialized = false;
  bool _disposed = false;
  bool _isPurchasing = false;
  bool _isRestoring = false;
  bool _isRefreshing = false;
  bool _restoreFoundPurchase = false;
  String? _restoreFailureMessage;
  Entitlement? _restoredEntitlement;
  SubscriptionPhase _phase = SubscriptionPhase.idle;
  PurchaseResult? _lastResult;
  RestoreStatus? _lastRestoreStatus;
  String? _errorMessage;
  late SubscriptionSnapshot _snapshot = SubscriptionSnapshot(
    defaultEntitlementId: config.effectiveDefaultEntitlementId,
    isStoreAvailable: repository.isAvailable,
  );

  bool get isInitialized => _initialized;
  bool get isPurchasing => _isPurchasing;
  bool get isRestoring => _isRestoring;
  bool get isStoreAvailable => repository.isAvailable;
  List<StoreProduct> get products => List.unmodifiable(_products);
  Map<String, Entitlement> get entitlements => Map.unmodifiable(_entitlements);
  Stream<Map<String, Entitlement>> get entitlementStream =>
      _entitlementController.stream;
  Stream<PurchaseResult> get purchaseResultStream => _resultController.stream;
  Stream<List<ConsumableDelivery>> get consumableDeliveryStream =>
      _consumableDeliveryController.stream;
  SubscriptionSnapshot get snapshot => _snapshot;
  Stream<SubscriptionSnapshot> get snapshotStream => _snapshotController.stream;
  List<ConsumableDelivery> get pendingConsumables =>
      List.unmodifiable(_pendingConsumables);

  Entitlement? get currentEntitlement =>
      config.effectiveDefaultEntitlementId == null
      ? null
      : _entitlements[config.effectiveDefaultEntitlementId];

  bool get hasAccess => currentEntitlement?.hasAccess ?? false;

  Future<void> initialize() async {
    _ensureNotDisposed();
    if (_initialized) return;

    _purchaseSubscription ??= repository.purchaseStream.listen(_queuePurchase);
    _phase = SubscriptionPhase.initializing;
    _errorMessage = null;
    _emitSnapshot();
    try {
      await repository.initialize(config.products, config.storageKeyPrefix);
      if (!repository.isAvailable) {
        _products = const <StoreProduct>[];
        _phase = SubscriptionPhase.unavailable;
        _emitSnapshot();
        return;
      }
      _entitlements = await repository.loadEntitlements();
      _pendingConsumables = await repository.loadPendingConsumables();
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
      _phase = SubscriptionPhase.ready;
      _expiryTimer = Timer.periodic(config.expiryCheckInterval, (_) {
        unawaited(_checkExpiry().catchError((Object _) {}));
      });
      _emitSnapshot();
      _emitEntitlements();
      _emitPendingConsumables();
    } catch (error) {
      _phase = SubscriptionPhase.failure;
      _errorMessage = '$error';
      _emitSnapshot();
      rethrow;
    }
  }

  Future<bool> purchase(String productId) async {
    _ensureNotDisposed();
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
    _ensureInitialized();
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
    _errorMessage = null;
    _emitSnapshot();
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
    _lastRestoreStatus = null;
    _errorMessage = null;
    _reconciliationPurchaseIds.clear();
    _restoreFoundPurchase = false;
    _restoreFailureMessage = null;
    _restoredEntitlement = null;
    _emitSnapshot();
    late final RestoreResult result;
    try {
      await repository.restore();
      final existing = await repository.queryExistingPurchases();
      for (final purchase in existing) {
        _queuePurchase(purchase);
      }
      await _drainProcessing();
      final failureMessage = _restoreFailureMessage;
      if (failureMessage != null) {
        result = RestoreResult(
          status: RestoreStatus.failure,
          message: failureMessage,
        );
      } else {
        final entitlement = _restoredEntitlement ?? currentEntitlement;
        if (_restoreFoundPurchase && entitlement != null) {
          result = RestoreResult(
            status: RestoreStatus.restored,
            entitlement: entitlement,
          );
        } else {
          result = const RestoreResult(status: RestoreStatus.none);
        }
      }
    } catch (error) {
      result = RestoreResult(status: RestoreStatus.failure, message: '$error');
    } finally {
      _isRestoring = false;
      _restoreFailureMessage = null;
      _reconciliationPurchaseIds.clear();
      _lastRestoreStatus = result.status;
      _errorMessage = result.message;
      _lastResult = PurchaseResult(
        status: result.status == RestoreStatus.restored
            ? PurchaseStatus.restored
            : PurchaseStatus.error,
        message: result.message,
        entitlement: result.entitlement,
      );
      _emitSnapshot();
    }
    return result;
  }

  Future<void> refresh() async {
    _ensureInitialized();
    _isRefreshing = true;
    _errorMessage = null;
    _emitSnapshot();
    _reconciliationPurchaseIds.clear();
    try {
      if (config.verificationMode == VerificationMode.serverVerified) {
        await repository.restore();
      } else {
        final existing = await repository.queryExistingPurchases();
        for (final purchase in existing) {
          _queuePurchase(purchase);
        }
      }
      await _drainProcessing();
    } finally {
      _isRefreshing = false;
      _reconciliationPurchaseIds.clear();
      _emitSnapshot();
    }
  }

  Future<void> _drainProcessing() async {
    while (true) {
      final processing = _processing;
      if (processing == null) return;
      await processing;
      if (identical(processing, _processing)) return;
    }
  }

  Future<void> acknowledgeConsumablePurchase(String purchaseId) async {
    _ensureInitialized();
    await repository.acknowledgeConsumable(purchaseId);
    _pendingConsumables = _pendingConsumables
        .where((delivery) => delivery.purchaseId != purchaseId)
        .toList(growable: false);
    _emitPendingConsumables();
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
      _isPurchasing = false;
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.notAvailable,
          productId: purchase.productId,
          message: 'The purchase product is not configured.',
        ),
      );
      return;
    }

    if (purchase.status == StorePurchaseStatus.pending) {
      _isPurchasing = false;
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.pending,
          productId: purchase.productId,
        ),
      );
      return;
    }

    if (purchase.status == StorePurchaseStatus.canceled) {
      _isPurchasing = false;
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.canceled,
          productId: purchase.productId,
        ),
      );
      await _completeIfNeeded(purchase);
      return;
    }
    if (purchase.status == StorePurchaseStatus.error) {
      _recordRestoreFailure(
        purchase.errorMessage ?? 'The store reported a purchase error.',
      );
      _isPurchasing = false;
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.error,
          productId: purchase.productId,
          errorCode: purchase.errorCode,
          message: purchase.errorMessage,
        ),
      );
      await _completeIfNeeded(purchase);
      return;
    }

    final purchaseId = _purchaseId(purchase);
    if (purchaseId == null) {
      _recordRestoreFailure(
        'The store did not provide a stable purchase identifier.',
      );
      _isPurchasing = false;
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.error,
          productId: purchase.productId,
          message: 'The store did not provide a stable purchase identifier.',
        ),
      );
      return;
    }

    final isProcessed = await repository.isPurchaseProcessed(purchaseId);
    if (isProcessed) {
      if (config.verificationMode == VerificationMode.serverVerified &&
          definition.grantsEntitlement &&
          (_isRefreshing || _isRestoring)) {
        final verification = await _verify(definition, purchase);
        if (verification.status == VerificationStatus.unavailable) {
          _recordRestoreFailure(
            verification.message ?? 'Purchase verification is unavailable.',
          );
          _isPurchasing = false;
          _emitResult(
            PurchaseResult(
              status: PurchaseStatus.verificationFailed,
              productId: purchase.productId,
              storePurchaseId: purchaseId,
              message: verification.message,
            ),
          );
          return;
        }
        await _persistVerification(definition, purchase, verification);
        if (_isRestoring) {
          _restoreFoundPurchase = true;
          _restoredEntitlement = _entitlements[definition.entitlementId];
        }
      } else if (_isRestoring) {
        _restoreFoundPurchase = true;
        _restoredEntitlement = definition.entitlementId == null
            ? null
            : _entitlements[definition.entitlementId];
      }
      _isPurchasing = false;
      await _completeIfNeeded(purchase);
      _emitSnapshot();
      return;
    }

    final verification = await _verify(definition, purchase);
    if (verification.status == VerificationStatus.unavailable) {
      _recordRestoreFailure(
        verification.message ?? 'Purchase verification is unavailable.',
      );
      _isPurchasing = false;
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.verificationFailed,
          productId: purchase.productId,
          storePurchaseId: purchaseId,
          message: verification.message,
        ),
      );
      return;
    }

    if (verification.status == VerificationStatus.invalid) {
      await _persistVerification(definition, purchase, verification);
      await repository.markPurchaseProcessed(purchaseId);
      _isPurchasing = false;
      _recordRestoreFailure(
        verification.message ?? 'Purchase verification failed.',
      );
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.verificationFailed,
          productId: purchase.productId,
          storePurchaseId: purchaseId,
          message: verification.message,
        ),
      );
      await _completeIfNeeded(purchase);
      return;
    }

    await _persistVerification(definition, purchase, verification);
    if (definition.isConsumable) {
      await repository.savePendingConsumable(
        ConsumableDelivery(
          purchaseId: purchaseId,
          productId: purchase.productId,
          purchasedAt: purchase.transactionDate ?? DateTime.now(),
        ),
      );
      _pendingConsumables = await repository.loadPendingConsumables();
      _emitPendingConsumables();
    }
    await repository.markPurchaseProcessed(purchaseId);

    final entitlement = definition.entitlementId == null
        ? null
        : _entitlements[definition.entitlementId];
    if (_isRestoring) {
      _restoreFoundPurchase = true;
      _restoredEntitlement = entitlement;
    }
    _isPurchasing = false;
    if (!_shouldSuppressSuccess) {
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
    await _completeIfNeeded(purchase);
  }

  Future<void> _persistVerification(
    ProductDefinition definition,
    StorePurchase purchase,
    VerificationResult verification,
  ) async {
    final entitlementId = definition.entitlementId;
    if (entitlementId == null) return;

    if (verification.status == VerificationStatus.invalid) {
      final existing = _entitlements[entitlementId];
      if (existing == null) return;
      final revoked = existing.copyWith(
        isActive: false,
        state: verification.state,
        isExpiryKnown: true,
        lastVerifiedAt: DateTime.now(),
      );
      await repository.saveEntitlement(revoked);
      _entitlements = {..._entitlements, revoked.id: revoked};
      _emitEntitlements();
      return;
    }

    final entitlement = _createEntitlement(definition, verification, purchase);
    await repository.saveEntitlement(entitlement);
    _entitlements = {..._entitlements, entitlement.id: entitlement};
    _emitEntitlements();
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
        expiresAt: (purchase.transactionDate ?? DateTime.now()).add(
          definition.duration!,
        ),
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
    final expiresAt = verification.expiresAt;
    final hasExpired =
        verification.isExpiryKnown &&
        expiresAt != null &&
        !expiresAt.isAfter(DateTime.now());
    final state = hasExpired && verification.state.hasAccess
        ? SubscriptionState.expired
        : verification.state;
    return Entitlement(
      id: definition.entitlementId!,
      productId: definition.id,
      productType: definition.type,
      isActive: state.hasAccess,
      state: state,
      expiresAt: expiresAt,
      isExpiryKnown: verification.isExpiryKnown,
      willRenew:
          verification.willRenew || definition.type == ProductType.autoRenewing,
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
    if (_shouldSuppressSuccess &&
        (purchase.status == StorePurchaseStatus.purchased ||
            purchase.status == StorePurchaseStatus.restored)) {
      final purchaseId = _purchaseId(purchase);
      if (purchaseId != null && !_reconciliationPurchaseIds.add(purchaseId)) {
        return;
      }
    }
    final previous = _processing ?? Future<void>.value();
    _processing = previous.then((_) => _processPurchase(purchase)).catchError((
      Object error,
      StackTrace stackTrace,
    ) {
      _recordRestoreFailure('$error');
      _isPurchasing = false;
      _emitResult(
        PurchaseResult(
          status: PurchaseStatus.error,
          productId: purchase.productId,
          message: '$error',
        ),
      );
    });
  }

  void _recordRestoreFailure(String message) {
    if (_isRestoring) _restoreFailureMessage ??= message;
  }

  Future<void> _completeIfNeeded(StorePurchase purchase) async {
    if (purchase.pendingCompletePurchase) {
      await repository.complete(purchase);
    }
  }

  String? _purchaseId(StorePurchase purchase) {
    final storeId = purchase.purchaseId?.trim();
    if (storeId != null && storeId.isNotEmpty) return storeId;
    final transactionDate = purchase.transactionDate;
    if (transactionDate == null) return null;
    return '${purchase.productId}:${transactionDate.toUtc().microsecondsSinceEpoch}';
  }

  void _emitEntitlements() {
    if (!_entitlementController.isClosed) {
      _entitlementController.add(Map.unmodifiable(_entitlements));
    }
    _emitSnapshot();
  }

  void _emitPendingConsumables() {
    if (!_consumableDeliveryController.isClosed) {
      _consumableDeliveryController.add(List.unmodifiable(_pendingConsumables));
    }
    _emitSnapshot();
  }

  void _emitResult(PurchaseResult result) {
    _lastResult = result;
    _lastRestoreStatus = null;
    _errorMessage = result.status.isError ? result.message : null;
    if (!_resultController.isClosed) _resultController.add(result);
    _emitSnapshot();
  }

  void _emitSnapshot() {
    _snapshot = SubscriptionSnapshot(
      phase: _phase,
      products: _products,
      entitlements: _entitlements,
      pendingConsumables: _pendingConsumables,
      defaultEntitlementId: config.effectiveDefaultEntitlementId,
      isPurchasing: _isPurchasing,
      isRestoring: _isRestoring,
      lastResult: _lastResult,
      lastRestoreStatus: _lastRestoreStatus,
      errorMessage: _errorMessage,
      isStoreAvailable: repository.isAvailable,
    );
    if (!_snapshotController.isClosed) _snapshotController.add(_snapshot);
  }

  bool get _shouldSuppressSuccess => _isRestoring || _isRefreshing;

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
    _phase = SubscriptionPhase.disposed;
    _emitSnapshot();
    _expiryTimer?.cancel();
    await _purchaseSubscription?.cancel();
    final processing = _processing;
    if (processing != null) await processing;
    await repository.dispose();
    await _entitlementController.close();
    await _resultController.close();
    await _consumableDeliveryController.close();
    await _snapshotController.close();
    _initialized = false;
  }
}
