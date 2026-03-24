import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final myProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final resp = await dio.get('users/me');
    return resp.data as Map<String, dynamic>;
  } catch (_) { return null; }
});

final availableInterestsProvider = FutureProvider<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('users/interests');
  return resp.data as List<dynamic>;
});
