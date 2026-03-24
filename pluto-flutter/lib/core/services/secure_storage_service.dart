import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});

class SecureStorageService {
  final FlutterSecureStorage _storage;

  const SecureStorageService(this._storage);

  static const String _tokenKey = 'auth_token';
  static const String _fcmTokenKey = 'fcm_token';

  // ── Tokens ────────────────────────────────────────────────────────────────
  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);
  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ── FCM ───────────────────────────────────────────────────────────────────
  Future<void> saveFCMToken(String token) => _storage.write(key: _fcmTokenKey, value: token);
  Future<String?> getFCMToken() => _storage.read(key: _fcmTokenKey);

  // ── Generic ───────────────────────────────────────────────────────────────
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  Future<String?> read(String key) => _storage.read(key: key);
  Future<void> delete(String key) => _storage.delete(key: key);
  Future<void> deleteAll() => _storage.deleteAll();
}
