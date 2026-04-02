import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../profile/providers/profile_provider.dart';

/// Provider for trip members
final tripMembersProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('trips/$tripId/members');
  return List<Map<String, dynamic>>.from(resp.data);
});

/// Provider for trip applications (seen by owner)
final ownerApplicationsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tripId) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('trips/$tripId/applications');
  return List<Map<String, dynamic>>.from(resp.data);
});

/// Provider for application approval status (vote count etc)
final applicationStatusProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, appId) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('trips/applications/$appId/status');
  return resp.data as Map<String, dynamic>;
});

final hasCurrentUserVotedProvider =
    FutureProvider.family<bool, String>((ref, appId) async {
  final status = await ref.watch(applicationStatusProvider(appId).future);
  final profile = await ref.watch(myProfileProvider.future);
  if (profile == null) return false;

  final currentUserId = profile['id']?.toString();
  final voters = (status['voters'] as List? ?? []).map((v) => v.toString());
  return currentUserId != null && voters.contains(currentUserId);
});

/// Notifier for workflow actions (apply, approve, vote, pay)
class WorkflowNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> apply(String tripId) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('trips/$tripId/apply');
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> ownerApprove(String appId, String tripId) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('trips/applications/$appId/owner-approve');
      ref.invalidate(ownerApplicationsProvider(tripId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> groupVote(String appId, String tripId) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('trips/applications/$appId/group-approve');
      ref.invalidate(applicationStatusProvider(appId));
      ref.invalidate(hasCurrentUserVotedProvider(appId));
      ref.invalidate(ownerApplicationsProvider(tripId));
      ref.invalidate(tripMembersProvider(tripId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> payWithPromo(String appId, String tripId, String promo) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('trips/applications/$appId/pay', data: {'promo_code': promo});
      ref.invalidate(tripMembersProvider(tripId));
      ref.invalidate(ownerApplicationsProvider(tripId));
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final workflowActionProvider = NotifierProvider<WorkflowNotifier, AsyncValue<void>>(WorkflowNotifier.new);
