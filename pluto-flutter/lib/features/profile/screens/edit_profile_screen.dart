import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: const Center(child: Text('Edit profile form — coming soon')),
    );
  }
}

class InterestsScreen extends ConsumerWidget {
  const InterestsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Interests'), leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: const Center(child: Text('Interest tags — coming soon')),
    );
  }
}
