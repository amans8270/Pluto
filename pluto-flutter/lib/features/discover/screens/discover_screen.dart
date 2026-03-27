import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/pluto_mode_tabs.dart';
import '../../../shared/widgets/swipe_card.dart';
import '../providers/discover_provider.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final discoverAsync = ref.watch(discoverFeedProvider(mode));
    final activeColor = PlutoColors.modeColor(mode);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  // Pluto logo
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.public, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Pluto',
                    style: PlutoTextStyles.headlineMedium.copyWith(
                      color: activeColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: activeColor),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Mode Tabs ────────────────────────────────────────
            PlutoModeTabs(
              selectedMode: mode,
              onModeChanged: (m) =>
                  ref.read(appModeProvider.notifier).setMode(m),
            ),
            const SizedBox(height: 16),

            // ── Swipe Cards ──────────────────────────────────────
            Expanded(
              child: discoverAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    const Center(child: Text('Error loading profiles')),
                data: (candidates) {
                  if (candidates.isEmpty) {
                    return _EmptyState(mode: mode, color: activeColor);
                  }
                  return _SwipeDeck(candidates: candidates, mode: mode);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Swipe Deck ───────────────────────────────────────────────────────────────
class _SwipeDeck extends ConsumerWidget {
  final List<Map<String, dynamic>> candidates;
  final String mode;
  const _SwipeDeck({required this.candidates, required this.mode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = CardSwiperController();
    final activeColor = PlutoColors.modeColor(mode);

    return Stack(
      children: [
        // Cards
        Positioned.fill(
          bottom: 90,
          child: CardSwiper(
            controller: controller,
            cardsCount: candidates.length,
            numberOfCardsDisplayed:
                candidates.length < 3 ? candidates.length : 3,
            backCardOffset: const Offset(20, 30),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            isLoop:
                candidates.any((p) => p['id'].toString().startsWith('demo_')),
            onSwipe: (prev, curr, dir) {
              final action = dir == CardSwiperDirection.right
                  ? 'LIKE'
                  : dir == CardSwiperDirection.left
                      ? 'DISLIKE'
                      : 'SUPERLIKE';

              ref
                  .read(swipeActionProvider.notifier)
                  .swipe(
                    targetId: candidates[prev]['id'],
                    mode: mode,
                    action: action,
                  )
                  .then((result) {
                if (result['is_demo_interaction'] == true && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Row(
                        children: [
                          const Icon(Icons.lightbulb_outline,
                              color: Colors.amber),
                          const SizedBox(width: 10),
                          Text(result['title'] ?? 'Guide Tip'),
                        ],
                      ),
                      content: Text(result['message'] ?? '',
                          style: const TextStyle(fontSize: 16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Got it!',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                }
              });
              return true;
            },
            cardBuilder: (ctx, index, hOffset, vOffset) {
              return SwipeCard(candidate: candidates[index], mode: mode);
            },
          ),
        ),

        // ── Action Buttons ─────────────────────────────────────
        Positioned(
          bottom: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Dislike
              _ActionBtn(
                icon: Icons.close_rounded,
                color: activeColor,
                bg: Colors.white,
                shadow: Colors.black12,
                size: 56,
                onTap: () => controller.swipe(CardSwiperDirection.left),
              ),
              const SizedBox(width: 16),
              // Superlike (star)
              _ActionBtn(
                icon: Icons.star_rounded,
                color: const Color(0xFFFFB800),
                bg: Colors.white,
                shadow: Colors.black12,
                size: 48,
                onTap: () => controller.swipe(CardSwiperDirection.top),
              ),
              const SizedBox(width: 16),
              // Like
              _ActionBtn(
                icon: mode == 'TRAVELBUDDY'
                    ? Icons.explore
                    : Icons.favorite_rounded,
                color: Colors.white,
                bg: activeColor,
                shadow: activeColor.withOpacity(0.4),
                size: 56,
                onTap: () => controller.swipe(CardSwiperDirection.right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color, bg, shadow;
  final double size;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.icon,
      required this.color,
      required this.bg,
      required this.shadow,
      required this.size,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 16, offset: const Offset(0, 6))
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.46),
      ).animate(onPlay: (c) => c.forward()).scale(begin: const Offset(1, 1)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String mode;
  final Color color;
  const _EmptyState({required this.mode, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: color.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text("You've seen everyone nearby!",
              style: PlutoTextStyles.headlineSmall
                  .copyWith(color: Theme.of(context).colorScheme.onSurface)),
          const SizedBox(height: 8),
          Text('Try expanding your search radius',
              style: PlutoTextStyles.bodyMedium.copyWith(color: Colors.grey)),
        ],
      ).animate().fadeIn(),
    );
  }
}
