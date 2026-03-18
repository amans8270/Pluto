import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/workflow_provider.dart';

class TripMembersScreen extends ConsumerWidget {
  final String tripId;
  const TripMembersScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(tripMembersProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: const Text('Trip Buddies', style: PlutoTextStyles.headlineSmall)),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (members) {
          if (members.isEmpty) {
            return const Center(child: Text('No members yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: members.length,
            itemBuilder: (ctx, i) {
              final m = members[i];
              final isOwner = m['is_owner'] ?? false;
              return ListTile(
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: isOwner ? PlutoColors.travel : Colors.grey[300],
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  m['username'] ?? 'User',
                  style: PlutoTextStyles.titleMedium.copyWith(
                    fontWeight: isOwner ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Text(isOwner ? 'Trip Owner' : 'Member'),
                trailing: isOwner 
                  ? const Icon(Icons.verified, color: PlutoColors.travel, size: 20)
                  : null,
              );
            },
          );
        },
      ),
    );
  }
}
