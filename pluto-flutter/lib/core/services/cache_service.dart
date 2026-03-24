import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main()');
});

class CacheService {
  final SharedPreferences _prefs;

  CacheService(this._prefs);

  // ── Basic Getters/Setters ──────────────────────────────────────────────────
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  bool? getBool(String key) => _prefs.getBool(key);

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  // ── JSON Object Caching ────────────────────────────────────────────────────
  Future<bool> setObject(String key, Map<String, dynamic> value) {
    return _prefs.setString(key, jsonEncode(value));
  }

  Map<String, dynamic>? getObject(String key) {
    final data = _prefs.getString(key);
    if (data == null) return null;
    try {
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ── Removal ────────────────────────────────────────────────────────────────
  Future<bool> remove(String key) => _prefs.remove(key);
  Future<bool> clear() => _prefs.clear();

  // ── Cache Expiration Helper (Optional) ─────────────────────────────────────
  Future<void> setWithTimestamp(String key, String value, Duration ttl) async {
    final expiry = DateTime.now().add(ttl).millisecondsSinceEpoch;
    await _prefs.setString('${key}_data', value);
    await _prefs.setInt('${key}_expiry', expiry);
  }

  String? getIfValid(String key) {
    final expiry = _prefs.getInt('${key}_expiry');
    if (expiry == null || DateTime.now().millisecondsSinceEpoch > expiry) {
      return null;
    }
    return _prefs.getString('${key}_data');
  }
}
