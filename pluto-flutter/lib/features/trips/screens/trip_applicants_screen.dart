import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/workflow_provider.dart';

class TripApplicantsScreen extends ConsumerWidget {
  final String tripId;
  const TripApplicantsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(ownerApplicationsProvider(tripId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Applicants', style: PlutoTextStyles.headlineSmall),
      ),
      body: appsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(child: Text('No applications yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: apps.length,
            separatorBuilder: (_, __) => const Divider(height: 32),
            itemBuilder: (ctx, i) => _ApplicantTile(app: apps[i], tripId: tripId),
          );
        },
      ),
    );
  }
}

class _ApplicantTile extends ConsumerWidget {
  final Map<String, dynamic> app;
  final String tripId;
  const _ApplicantTile({required this.app, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = app['status'];
    final username = app['username'] ?? 'User';
    final appId = app['id'].toString();
    
    // Check vote status if in group pending
    final voteStatusAsync = (status == 'GROUP_PENDING') 
        ? ref.watch(applicationStatusProvider(appId))
        : const AsyncData(<String, dynamic>{});

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(radius: 28, backgroundColor: Colors.blueGrey),
          title: Text(username, style: PlutoTextStyles.titleLarge),
          subtitle: Text('Status: $status', style: TextStyle(color: _getStatusColor(status))),
          trailing: _buildActions(context, ref, status, appId),
        ),
        if (status == 'GROUP_PENDING') 
          voteStatusAsync.when(
            data: (v) => _VoteProgress(
              current: v['current_approvals'] ?? 0,
              required: v['required_approvals'] ?? 3,
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, String status, String appId) {
    if (status == 'APPLIED') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 30),
            onPressed: () => ref.read(workflowActionProvider.notifier).ownerApprove(appId, tripId),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.red, size: 30),
            onPressed: () {}, // Reject logic
          ),
        ],
      );
    }
    
    if (status == 'GROUP_PENDING') {
      final authState = ref.watch(authStateProvider);
      final currentUserId = authState.value?.id;
      final voteStatus = ref.watch(applicationStatusProvider(appId)).valueOrNull;
      final voters = voteStatus?['voters'] as List?;
      final alreadyVoted = voters != null && voters.contains(currentUserId);

      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: alreadyVoted ? Colors.grey : Colors.blueAccent,
        ),
        onPressed: alreadyVoted ? null : () => ref.read(workflowActionProvider.notifier).groupVote(appId, tripId),
        child: Text(alreadyVoted ? 'Voted' : 'Vote', style: const TextStyle(color: Colors.white)),
      );
    }

    return const Icon(Icons.info_outline, color: Colors.grey);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'APPLIED': return Colors.orange;
      case 'OWNER_APPROVED':
      case 'GROUP_PENDING': return Colors.blue;
      case 'GROUP_APPROVED':
      case 'FINALIZED': return Colors.green;
      case 'REJECTED': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _VoteProgress extends StatelessWidget {
  final int current, required;
  const _VoteProgress({required this.current, required this.required});

  @override
  Widget build(BuildContext context) {
    final progress = (current / required).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Group Approval', style: PlutoTextStyles.labelSmall),
              Text('$current / $required', style: PlutoTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              color: Colors.blueAccent,
            ),
          ),
        ],
      ),
    );
  }
}
