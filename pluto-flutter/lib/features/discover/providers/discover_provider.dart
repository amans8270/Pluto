import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

// Discover feed state provider
final discoverFeedProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, mode) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('/swipes/discover', queryParameters: {'mode': mode});
  final data = resp.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(data['candidates'] ?? []);
});

// Swipe action notifier
class SwipeActionNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<Map<String, dynamic>> swipe({
    required String targetId,
    required String mode,
    required String action,
  }) async {
    final dio = ref.read(dioProvider);
    final resp = await dio.post('/swipes/', data: {
      'target_user_id': targetId,
      'mode': mode,
      'action': action,
    });
    return resp.data as Map<String, dynamic>;
  }
}

final swipeActionProvider = NotifierProvider<SwipeActionNotifier, void>(SwipeActionNotifier.new);
