import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/demo_profiles.dart';
import '../../../core/services/cache_service.dart';
import '../../../core/services/location_service.dart';

// Discover feed state provider
final discoverFeedProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, mode) async {
  final dio = ref.watch(dioProvider);
  final cache = ref.watch(cacheServiceProvider);
  final locService = ref.watch(locationServiceProvider);
  
  // Check if this is a first-time discovery session
  final isNewUser = cache.getString('is_not_new_discover') == null;

  try {
    // 1. Get current location
    final position = await locService.getCurrentLocation();
    
    final queryParams = <String, dynamic>{'mode': mode};
    if (position != null) {
      queryParams['lat'] = position.latitude;
      queryParams['lon'] = position.longitude;
    } else {
      // Fallback for DEV TESTING: Use Delhi center if real GPS fails
      // This ensures the seeded users are visible during development
      queryParams['lat'] = 28.6139; 
      queryParams['lon'] = 77.2090;
      queryParams['radius_km'] = 500; // Large radius to catch all seeded users
    }

    final resp = await dio.get('swipes/discover', queryParameters: queryParams);
    final data = resp.data as Map<String, dynamic>;
    final candidates = List<Map<String, dynamic>>.from(data['candidates'] ?? []);
    
    if (candidates.isEmpty && position != null) {
      // If no one nearby in REAL location, try Delhi fallback for demo
      final fallbackResp = await dio.get('swipes/discover', queryParameters: {
        'mode': mode,
        'lat': 28.6139,
        'lon': 77.2090,
        'radius_km': 100,
      });
      final fallbackData = fallbackResp.data as Map<String, dynamic>;
      return List<Map<String, dynamic>>.from(fallbackData['candidates'] ?? []);
    }
    
    if (isNewUser && candidates.isNotEmpty) {
      return [...demoProfiles, ...candidates];
    }
    
    return candidates.isEmpty ? demoProfiles : candidates;
  } catch (e) {
    return demoProfiles;
  }
});

// Swipe action notifier
class SwipeActionNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<Map<String, dynamic>> swipe({
    required String targetId,
    required String mode,
    required String action,
  }) async {
    // Handle Demo Swipe
    if (targetId.startsWith('demo_')) {
      final cache = ref.read(cacheServiceProvider);
      int swipes = int.tryParse(cache.getString('demo_swipe_count') ?? '0') ?? 0;
      swipes++;
      cache.setString('demo_swipe_count', swipes.toString());
      
      final hasSeenGuidance = cache.getString('has_seen_swipe_guidance') == 'true';
      if (hasSeenGuidance) {
        return {'matched': false, 'is_demo_interaction': false};
      }

      if (swipes >= 3) {
        cache.setString('is_not_new_discover', 'true');
        cache.setString('has_seen_swipe_guidance', 'true');
      }

      final profile = demoProfiles.firstWhere((p) => p['id'] == targetId);
      return {
        'is_demo_interaction': true,
        'matched': false,
        'message': _getDemoMessage(profile['demo_feature'], action),
        'title': 'Pluto Guide Tips 💡',
      };
    }

    final dio = ref.read(dioProvider);
    final resp = await dio.post('swipes/', data: {
      'target_user_id': targetId,
      'mode': mode,
      'action': action,
    });
    return resp.data as Map<String, dynamic>;
  }

  String _getDemoMessage(String? feature, String action) {
    if (action == 'DISLIKE') return "Passing is okay! You won't see this profile again for a while.";
    
    switch (feature) {
      case 'swipe': return "Great job! Swiping right shows interest. If they like you back, it's a match!";
      case 'match_chat': return "Matches appear in your Chat tab. That's where the magic happens!";
      case 'travel_buddy': return "Travel mode helps you find globetrotters. Perfect for your next adventure!";
      case 'profile_customization': return "A full profile gets way more likes. Go to Settings to polish yours!";
      case 'safety': return "Safety first! Use the block button if someone makes you uncomfortable.";
      default: return "You're getting the hang of it! Keep exploring Pluto.";
    }
  }
}

final swipeActionProvider = NotifierProvider<SwipeActionNotifier, void>(SwipeActionNotifier.new);
