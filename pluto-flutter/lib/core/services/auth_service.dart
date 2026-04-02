import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import 'cache_service.dart';
import 'secure_storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    FirebaseAuth.instance,
    ref.watch(dioProvider),
    ref.watch(cacheServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

class AuthService {
  final FirebaseAuth _auth;
  final Dio _dio;
  final CacheService _cache;
  final SecureStorageService _secureStorage;

  AuthService(this._auth, this._dio, this._cache, this._secureStorage);

  Future<void> _clearSessionData() async {
    final hasSeenOnboarding = _cache.getBool('has_seen_onboarding') ?? false;
    await _cache.clear();
    if (hasSeenOnboarding) {
      await _cache.setBool('has_seen_onboarding', true);
    }
    await _secureStorage.deleteAll();
  }

  /// Sign out and clear all local data
  Future<void> signOut() async {
    await _auth.signOut();
    await _clearSessionData();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final userId = _auth.currentUser?.uid;
    if (userId != null) {
      await _dio.delete('auth/account');
      await _auth.signOut();
      await _clearSessionData();
    }
  }

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;
}
