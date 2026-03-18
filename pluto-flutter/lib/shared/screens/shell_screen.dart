import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _tabs = [
    _TabItem(icon: Icons.explore_outlined, activeIcon: Icons.explore, label: 'Discover', path: '/discover'),
    _TabItem(icon: Icons.travel_explore_outlined, activeIcon: Icons.travel_explore, label: 'Trips', path: '/trips'),
    _TabItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Chats', path: '/chats'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile', path: '/profile'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final mode = ref.watch(appModeProvider);
    final activeColor = PlutoColors.modeColor(mode);

    int activeIndex = _tabs.indexWhere((t) => location.startsWith(t.path));
    if (activeIndex < 0) activeIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final tab = _tabs[i];
                final isActive = i == activeIndex;
                return GestureDetector(
                  onTap: () => context.go(tab.path),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? activeColor.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isActive ? tab.activeIcon : tab.icon,
                          color: isActive ? activeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? activeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontFamily: 'Outfit',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;
  const _TabItem({required this.icon, required this.activeIcon, required this.label, required this.path});
}
