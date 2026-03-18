import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  Widget build(BuildContext context) {
    final msgs = ref.watch(messagesProvider(widget.chatId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Chat', style: PlutoTextStyles.headlineSmall),
        actions: [
          IconButton(icon: const Icon(Icons.video_call_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: msgs.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Failed to load messages')),
              data: (messages) => ListView.builder(
                controller: _scrollCtrl,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: messages.length,
                itemBuilder: (ctx, i) => _MessageBubble(msg: messages[i]),
              ),
            ),
          ),

          // ── Input ──────────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).padding.bottom + 8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {},
                  color: Colors.grey,
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Message...',
                        border: InputBorder.none, filled: false,
                        contentPadding: EdgeInsets.zero, isDense: true,
                      ),
                      maxLines: 4, minLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: PlutoColors.dating, shape: BoxShape.circle),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    _msgCtrl.clear();
    await ref.read(sendMessageProvider.notifier).send(
      chatId: widget.chatId,
      content: text,
    );
    ref.invalidate(messagesProvider(widget.chatId));
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  const _MessageBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    // For now all messages show as sender (replace with actual user check)
    final isMe = true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const CircleAvatar(radius: 16, backgroundColor: Color(0xFFE5E7EB)),
            const SizedBox(width: 8),
          ],
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? PlutoColors.dating : Theme.of(context).cardColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Text(
              msg['content'] ?? '',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15,
                color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
