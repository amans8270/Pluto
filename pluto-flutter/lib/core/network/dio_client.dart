import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
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
