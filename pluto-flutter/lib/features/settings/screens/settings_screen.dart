import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Appearance'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Pluto'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: PlutoColors.error),
            title: const Text('Sign Out', style: TextStyle(color: PlutoColors.error)),
            onTap: () async { await FirebaseAuth.instance.signOut(); },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: PlutoColors.error),
            title: const Text('Delete Account', style: TextStyle(color: PlutoColors.error)),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
