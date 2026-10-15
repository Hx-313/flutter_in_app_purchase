import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/consumable_delivery.dart';
import '../../domain/entities/entitlement.dart';
import 'subscription_storage_data_source.dart';

/// SharedPreferences-backed default storage.
final class SharedPreferencesSubscriptionStorageDataSource
    implements SubscriptionStorageDataSource {
  SharedPreferences? _preferences;
  late String _prefix;
  Future<void> _pendingConsumableQueue = Future<void>.value();

  @override
  Future<void> initialize(String keyPrefix) async {
    _prefix = '$keyPrefix.';
    _preferences ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _prefs {
    final preferences = _preferences;
    if (preferences == null) {
      throw StateError('Subscription storage is not initialized');
    }
    return preferences;
  }

  String _entitlementKey(String id) => '${_prefix}entitlement.$id';
  String get _processedKey => '${_prefix}processed';
  String get _pendingConsumablesKey => '${_prefix}pendingConsumables';

  Future<void> _requireWrite(Future<bool> write, String key) async {
    if (!await write) {
      throw StateError('Could not persist subscription data at key "$key"');
    }
  }

  Future<T> _serializePendingConsumables<T>(Future<T> Function() action) {
    final result = Completer<T>();
    _pendingConsumableQueue = _pendingConsumableQueue.then((_) async {
      try {
        result.complete(await action());
      } on Object catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }

  @override
  Future<Map<String, Entitlement>> loadEntitlements() async {
    final result = <String, Entitlement>{};
    for (final key in _prefs.getKeys()) {
      if (!key.startsWith('${_prefix}entitlement.')) continue;
      final value = _prefs.getString(key);
      if (value == null) continue;
      try {
        final entitlement = Entitlement.fromJson(
          jsonDecode(value) as Map<String, dynamic>,
        );
        result[entitlement.id] = entitlement;
      } on Object {
        await _prefs.remove(key);
      }
    }
    return result;
  }

  @override
  Future<void> saveEntitlement(Entitlement entitlement) async {
    final key = _entitlementKey(entitlement.id);
    await _requireWrite(
      _prefs.setString(key, jsonEncode(entitlement.toJson())),
      key,
    );
  }

  @override
  Future<void> removeEntitlement(String entitlementId) async {
    final key = _entitlementKey(entitlementId);
    await _requireWrite(_prefs.remove(key), key);
  }

  Future<List<ConsumableDelivery>> _readPendingConsumables() async {
    final key = _pendingConsumablesKey;
    final encoded = _prefs.getString(key);
    if (encoded == null) return const [];

    var needsCleanup = false;
    final deliveries = <ConsumableDelivery>[];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List<Object?>) {
        await _writePendingConsumables(const []);
        return const [];
      }
      for (final record in decoded) {
        try {
          if (record is! Map<String, dynamic>) {
            needsCleanup = true;
            continue;
          }
          final purchaseId = record['purchaseId'];
          final productId = record['productId'];
          final purchasedAt = record['purchasedAt'];
          if (purchaseId is! String ||
              purchaseId.trim().isEmpty ||
              productId is! String ||
              productId.trim().isEmpty ||
              purchasedAt is! String) {
            needsCleanup = true;
            continue;
          }
          deliveries.add(
            ConsumableDelivery(
              purchaseId: purchaseId,
              productId: productId,
              purchasedAt: DateTime.parse(purchasedAt),
            ),
          );
        } on Object {
          needsCleanup = true;
        }
      }
    } on Object {
      needsCleanup = true;
    }

    if (needsCleanup) await _writePendingConsumables(deliveries);
    return List.unmodifiable(deliveries);
  }

  Future<void> _writePendingConsumables(
    List<ConsumableDelivery> deliveries,
  ) async {
    final key = _pendingConsumablesKey;
    await _requireWrite(
      _prefs.setString(
        key,
        jsonEncode(
          deliveries
              .map(
                (delivery) => {
                  'purchaseId': delivery.purchaseId,
                  'productId': delivery.productId,
                  'purchasedAt': delivery.purchasedAt.toIso8601String(),
                },
              )
              .toList(growable: false),
        ),
      ),
      key,
    );
  }

  @override
  Future<List<ConsumableDelivery>> loadPendingConsumables() =>
      _serializePendingConsumables(_readPendingConsumables);

  @override
  Future<void> savePendingConsumable(ConsumableDelivery delivery) =>
      _serializePendingConsumables(() async {
        final pending = await _readPendingConsumables();
        if (pending.any((item) => item.purchaseId == delivery.purchaseId)) {
          return;
        }
        await _writePendingConsumables([...pending, delivery]);
      });

  @override
  Future<void> acknowledgeConsumable(String purchaseId) =>
      _serializePendingConsumables(() async {
        final pending = await _readPendingConsumables();
        final remaining = pending
            .where((delivery) => delivery.purchaseId != purchaseId)
            .toList(growable: false);
        if (remaining.length != pending.length) {
          await _writePendingConsumables(remaining);
        }
      });

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) async =>
      (_prefs.getStringList(_processedKey) ?? const <String>[]).contains(
        purchaseId,
      );

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {
    final values = (_prefs.getStringList(_processedKey) ?? <String>[]).toSet()
      ..add(purchaseId);
    await _requireWrite(
      _prefs.setStringList(_processedKey, values.toList(growable: false)),
      _processedKey,
    );
  }

  @override
  Future<void> dispose() async {}
}

/// Backward-compatible public name for the default storage adapter.
typedef SharedPreferencesSubscriptionStorage =
    SharedPreferencesSubscriptionStorageDataSource;
