import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final chatListProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('chats/');
  final data = resp.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(data['chats'] ?? []);
});

final messagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, chatId) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('chats/$chatId/messages', queryParameters: {'limit': 40});
  final data = resp.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(data['messages'] ?? []);
});

class SendMessageNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> send({required String chatId, required String content}) async {
    final dio = ref.read(dioProvider);
    await dio.post('chats/$chatId/messages', data: {
      'content': content, 'msg_type': 'TEXT',
    });
    ref.invalidate(messagesProvider(chatId));
    ref.invalidate(chatListProvider);
  }
}

final sendMessageProvider = NotifierProvider<SendMessageNotifier, void>(SendMessageNotifier.new);
