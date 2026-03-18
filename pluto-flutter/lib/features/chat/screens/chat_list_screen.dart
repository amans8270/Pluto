import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(chatListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                children: [
                  Text('Messages', style: PlutoTextStyles.headlineLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: chatsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Failed to load chats')),
                data: (chats) => chats.isEmpty
                    ? const _EmptyChats()
                    : ListView.builder(
                        itemCount: chats.length,
                        itemBuilder: (ctx, i) => _ChatTile(chat: chats[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final Map<String, dynamic> chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => context.push('/chat/${chat['id']}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: PlutoColors.dating.withOpacity(0.2),
        child: chat['is_group'] == true
            ? const Icon(Icons.group, color: PlutoColors.travel)
            : const Icon(Icons.person, color: PlutoColors.dating),
      ),
      title: Text(
        chat['name'] ?? 'Chat',
        style: PlutoTextStyles.titleMedium,
      ),
      subtitle: Text(
        chat['last_message'] ?? 'Start chatting',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: PlutoTextStyles.bodySmall.copyWith(color: Colors.grey),
      ),
      trailing: chat['last_message_at'] != null
          ? Text(
              _formatTime(chat['last_message_at']),
              style: PlutoTextStyles.labelSmall.copyWith(color: Colors.grey),
            )
          : null,
    );
  }

  String _formatTime(String? ts) {
    if (ts == null) return '';
    try {
      return timeago.format(DateTime.parse(ts));
    } catch (_) { return ''; }
  }
}

class _EmptyChats extends StatelessWidget {
  const _EmptyChats();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 70, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('No chats yet', style: PlutoTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text('Match with someone and say hello! 👋', style: PlutoTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
