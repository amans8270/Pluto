import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

// Trip feed provider
final tripFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('trips/', queryParameters: {
    'latitude': 28.6139, 'longitude': 77.2090, 'radius_km': 500
  });
  final data = resp.data as Map<String, dynamic>;
  return List<Map<String, dynamic>>.from(data['trips'] ?? []);
});

// Trip detail provider
final tripDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, tripId) async {
  final dio = ref.watch(dioProvider);
  final resp = await dio.get('trips/$tripId');
  return resp.data as Map<String, dynamic>;
});

// Create trip notifier
class CreateTripNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> create({
    required String title,
    required String destination,
    required String? description,
    required DateTime startDate,
    required DateTime endDate,
    required int maxMembers,
    required double entryFeeInr,
    required String? category,
  }) async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      await dio.post('trips/', data: {
        'title': title,
        'destination': destination,
        'description': description,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate.toIso8601String().split('T')[0],
        'max_members': maxMembers,
        'entry_fee_inr': entryFeeInr,
        'category': category,
      });
      ref.invalidate(tripFeedProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createTripProvider = NotifierProvider<CreateTripNotifier, AsyncValue<void>>(CreateTripNotifier.new);
