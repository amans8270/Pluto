import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dio/dio.dart';

import '../network/dio_client.dart';
import 'cache_service.dart';
import 'secure_storage_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    Supabase.instance.client,
    ref.watch(dioProvider),
    ref.watch(cacheServiceProvider),
    ref.watch(secureStorageServiceProvider),
  );
});

class AuthService {
  final SupabaseClient _supabase;
  final Dio _dio;
  final CacheService _cache;
  final SecureStorageService _secureStorage;

  AuthService(this._supabase, this._dio, this._cache, this._secureStorage);

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
    await _supabase.auth.signOut();
    await _clearSessionData();
  }

  /// Delete account
  Future<void> deleteAccount() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _dio.delete('auth/account');
      await _supabase.auth.signOut();
      await _clearSessionData();
    }
  }

  /// Get current user ID
  String? get currentUserId => _supabase.auth.currentUser?.id;

  /// Check if user is signed in
  bool get isSignedIn => _supabase.auth.currentUser != null;
}
