import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';

/// WebSocket connection state
enum WsConnectionState { disconnected, connecting, connected, error }

/// A singleton WebSocket service that manages the chat connection.
/// Uses a Riverpod StateNotifier to expose connection state.
class WebSocketService extends StateNotifier<WsConnectionState> {
  WebSocketService() : super(WsConnectionState.disconnected);

  WebSocketChannel? _channel;
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  String? _userId;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  /// Public stream of incoming messages from the server
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;

  Future<void> connect(String userId) async {
    if (state == WsConnectionState.connected) return;
    _userId = userId;
    state = WsConnectionState.connecting;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) { state = WsConnectionState.error; return; }
      final token = await user.getIdToken();

      final wsUrl = Uri.parse('${AppConfig.wsBaseUrl}/$userId?token=$token');
      _channel = WebSocketChannel.connect(wsUrl);
      state = WsConnectionState.connected;
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (raw) {
          try {
            final msg = jsonDecode(raw as String) as Map<String, dynamic>;
            if (msg['type'] != 'pong') {
              _messageController.add(msg);
            }
          } catch (_) {}
        },
        onError: (_) => _scheduleReconnect(),
        onDone: () => _scheduleReconnect(),
      );

      // Start heartbeat
      _startHeartbeat();
    } catch (e) {
      state = WsConnectionState.error;
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> payload) {
    if (state == WsConnectionState.connected && _channel != null) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  void sendMessage({required String chatId, required String content}) {
    send({'type': 'message', 'chat_id': chatId, 'content': content, 'msg_type': 'TEXT'});
  }

  void sendTyping(String chatId) {
    send({'type': 'typing', 'chat_id': chatId});
  }

  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      if (state == WsConnectionState.connected) {
        send({'type': 'ping'});
      }
    });
  }

  void _scheduleReconnect() {
    state = WsConnectionState.disconnected;
    if (_reconnectAttempts >= 5) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts); // exponential backoff
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () {
      if (_userId != null) connect(_userId!);
    });
  }

  void disconnect() {
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    state = WsConnectionState.disconnected;
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}

// ─── Riverpod Provider ────────────────────────────────────────────────────────
final webSocketServiceProvider = StateNotifierProvider<WebSocketService, WsConnectionState>((ref) {
  return WebSocketService();
});

/// Convenience: stream of incoming WebSocket messages
final wsMessageStreamProvider = Provider<Stream<Map<String, dynamic>>>((ref) {
  return ref.watch(webSocketServiceProvider.notifier).onMessage;
});
