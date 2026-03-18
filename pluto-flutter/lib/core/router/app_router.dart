import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/onboarding/onboarding_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/matches/screens/matches_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/trips/screens/trip_feed_screen.dart';
import '../../features/trips/screens/trip_detail_screen.dart';
import '../../features/trips/screens/create_trip_screen.dart';
import '../../features/trips/screens/trip_applicants_screen.dart';
import '../../features/trips/screens/trip_payment_screen.dart';
import '../../features/trips/screens/trip_members_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/interests_screen.dart';
import '../../features/nearby/screens/nearby_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../shared/screens/shell_screen.dart';
import '../providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final onAuthPage = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation == '/splash';

      if (!isLoggedIn && !onAuthPage) return '/login';
      if (isLoggedIn && onAuthPage) return '/discover';
      return null;
    },
    routes: [
      // ── Public ───────────────────────────────────────────────
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login',  builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // ── Main Shell (bottom nav) ───────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(path: '/discover',    builder: (_, __) => const DiscoverScreen()),
          GoRoute(path: '/nearby',      builder: (_, __) => const NearbyScreen()),
          GoRoute(path: '/matches',     builder: (_, __) => const MatchesScreen()),
          GoRoute(path: '/trips',       builder: (_, __) => const TripFeedScreen()),
          GoRoute(path: '/chats',       builder: (_, __) => const ChatListScreen()),
          GoRoute(path: '/profile',     builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // ── Feature Screens (full screen, no bottom nav) ─────────
      GoRoute(
        path: '/chat/:chatId',
        builder: (ctx, state) => ChatScreen(chatId: state.pathParameters['chatId']!),
      ),
      GoRoute(
        path: '/trips/:tripId',
        builder: (ctx, state) => TripDetailScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/trips/:tripId/applicants',
        builder: (ctx, state) => TripApplicantsScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(
        path: '/applications/:appId/pay',
        builder: (ctx, state) => TripPaymentScreen(
          applicationId: state.pathParameters['appId']!,
          tripId: state.uri.queryParameters['tripId']!,
        ),
      ),
      GoRoute(
        path: '/trips/:tripId/members',
        builder: (ctx, state) => TripMembersScreen(tripId: state.pathParameters['tripId']!),
      ),
      GoRoute(path: '/trips/create', builder: (_, __) => const CreateTripScreen()),
      GoRoute(path: '/profile/edit',  builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/profile/interests', builder: (_, __) => const InterestsScreen()),
      GoRoute(path: '/settings',      builder: (_, __) => const SettingsScreen()),
    ],
  );
});
