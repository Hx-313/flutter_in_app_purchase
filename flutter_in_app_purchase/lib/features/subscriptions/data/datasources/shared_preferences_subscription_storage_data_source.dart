import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/entitlement.dart';
import 'subscription_storage_data_source.dart';

/// SharedPreferences-backed default storage.
final class SharedPreferencesSubscriptionStorageDataSource
    implements SubscriptionStorageDataSource {
  SharedPreferences? _preferences;
  late String _prefix;

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
    await _prefs.setString(
      _entitlementKey(entitlement.id),
      jsonEncode(entitlement.toJson()),
    );
  }

  @override
  Future<void> removeEntitlement(String entitlementId) async {
    await _prefs.remove(_entitlementKey(entitlementId));
  }

  @override
  Future<bool> isPurchaseProcessed(String purchaseId) async =>
      (_prefs.getStringList(_processedKey) ?? const <String>[]).contains(
        purchaseId,
      );

  @override
  Future<void> markPurchaseProcessed(String purchaseId) async {
    final values = (_prefs.getStringList(_processedKey) ?? <String>[]).toSet()
      ..add(purchaseId);
    await _prefs.setStringList(_processedKey, values.toList(growable: false));
  }

  @override
  Future<void> dispose() async {}
}

/// Backward-compatible public name for the default storage adapter.
typedef SharedPreferencesSubscriptionStorage =
    SharedPreferencesSubscriptionStorageDataSource;
