import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'cache_service.dart';
import 'secure_storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    FirebaseAuth.instance,
    ref.watch(cacheServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

class AuthService {
  final FirebaseAuth _auth;
  final CacheService _cache;
  final SecureStorageService _secureStorage;

  AuthService(this._auth, this._cache, this._secureStorage);

  Future<void> signOut() async {
    // 1. Clear Firebase Auth
    await _auth.signOut();
    
    // 2. Clear Local Cache (General preferences, API responses)
    await _cache.clear();
    
    // 3. Clear Secure Storage (Tokens, sensitive data)
    await _secureStorage.deleteAll();
  }

  // Add more auth methods here if needed (e.g. deleteAccount)
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.delete();
      await _cache.clear();
      await _secureStorage.deleteAll();
    }
  }
}
