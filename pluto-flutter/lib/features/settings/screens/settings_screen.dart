import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: ListView(
        children: [
          // ... other list tiles ...
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: PlutoColors.error),
            title: const Text('Sign Out', style: TextStyle(color: PlutoColors.error)),
            onTap: () async { 
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: PlutoColors.error),
            title: const Text('Delete Account', style: TextStyle(color: PlutoColors.error)),
            onTap: () async {
              await ref.read(authServiceProvider).deleteAccount();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
