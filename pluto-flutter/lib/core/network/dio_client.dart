import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../services/cache_service.dart';

final dioProvider = Provider<Dio>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ),
  );

  // ── Cache Interceptor: Simple GET response caching ─────────────────────────
  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) async {
        if (response.requestOptions.method == 'GET') {
          final path = response.requestOptions.path;
          // Simple rule: cache for 5 minutes
          await cacheService.setWithTimestamp(
            'api_cache_$path', 
            jsonEncode(response.data), 
            const Duration(minutes: 5),
          );
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        // Fallback to cache on network failure for GET requests
        if (error.requestOptions.method == 'GET') {
          final path = error.requestOptions.path;
          final cachedData = cacheService.getIfValid('api_cache_$path');
          if (cachedData != null) {
            final decoded = jsonDecode(cachedData);
            return handler.resolve(Response(
              requestOptions: error.requestOptions,
              data: decoded,
              statusCode: 200,
            ));
          }
        }
        
        // Final fallback for 401
        if (error.response?.statusCode == 401) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final freshToken = await user.getIdToken(true);
            error.requestOptions.headers['Authorization'] = 'Bearer $freshToken';
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        handler.next(error);
      },
    ),
  );

  // ── Auth Interceptor: auto-attach Firebase JWT ─────────────────────────────
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // 401 → try token refresh once
        if (error.response?.statusCode == 401) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final freshToken = await user.getIdToken(true);
            error.requestOptions.headers['Authorization'] = 'Bearer $freshToken';
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        }
        handler.next(error);
      },
    ),
  );

  // ── Logging Interceptor (debug only) ──────────────────────────────────────
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (obj) => debugPrint(obj.toString()),
  ));

  return dio;
});
