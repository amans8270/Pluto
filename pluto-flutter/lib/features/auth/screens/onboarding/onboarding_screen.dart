import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../../core/theme/app_theme.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardingPage(
      emoji: '❤️',
      title: 'Find Your Match',
      subtitle: 'Swipe through people in Dating mode and find someone who sparks something.',
      color: PlutoColors.dating,
    ),
    _OnboardingPage(
      emoji: '✈️',
      title: 'Travel Together',
      subtitle: 'Join group trips and meet fellow adventurers heading the same way.',
      color: PlutoColors.travel,
    ),
    _OnboardingPage(
      emoji: '🤝',
      title: 'Find Your BFF',
      subtitle: 'Move to a new city? Find nearby friends with BFF mode.',
      color: PlutoColors.bff,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: _pages.length,
            itemBuilder: (ctx, i) => _OnboardingPageWidget(page: _pages[i]),
          ),
          Positioned(
            bottom: 80,
            left: 0, right: 0,
            child: Center(
              child: AnimatedSmoothIndicator(
                activeIndex: _page,
                count: _pages.length,
                effect: ExpandingDotsEffect(
                  activeDotColor: _pages[_page].color,
                  dotColor: Colors.grey.withOpacity(0.3),
                  dotHeight: 8, dotWidth: 8, expansionFactor: 3,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 24, right: 24,
            child: _page < _pages.length - 1
                ? ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _pages[_page].color),
                    onPressed: () => _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
                    child: const Text('Next', style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 16)),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: _pages[_page].color),
                    onPressed: () => context.go('/discover'),
                    child: const Text("Let's Go! 🚀", style: TextStyle(fontFamily: 'Outfit', fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final String emoji, title, subtitle;
  final Color color;
  const _OnboardingPage({required this.emoji, required this.title, required this.subtitle, required this.color});
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [page.color.withOpacity(0.08), Colors.transparent],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(page.emoji, style: const TextStyle(fontSize: 100)).animate().scale(begin: const Offset(0.5, 0.5), curve: Curves.elasticOut),
              const SizedBox(height: 32),
              Text(page.title, style: PlutoTextStyles.displayMedium, textAlign: TextAlign.center).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              const SizedBox(height: 16),
              Text(page.subtitle, style: PlutoTextStyles.bodyLarge.copyWith(color: Colors.grey), textAlign: TextAlign.center).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
