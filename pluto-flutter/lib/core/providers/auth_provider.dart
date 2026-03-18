import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Auth state stream (Firebase User) ────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ─── Current user ID shortcut ─────────────────────────────────────────────────
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).valueOrNull?.uid;
});

// ─── App Mode (DATE | TRAVELBUDDY | BFF) ──────────────────────────────────────
class AppModeNotifier extends Notifier<String> {
  @override
  String build() => 'DATE';

  void setMode(String mode) => state = mode;
}

final appModeProvider = NotifierProvider<AppModeNotifier, String>(AppModeNotifier.new);
