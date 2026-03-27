import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);
    final mode = ref.watch(appModeProvider);
    final activeColor = PlutoColors.modeColor(mode);

    return Scaffold(
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Failed to load profile')),
        data: (profile) => CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 12, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [activeColor.withOpacity(0.1), Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Profile', style: PlutoTextStyles.headlineLarge),
                        Row(
                          children: [
                            IconButton(
                                icon: const Icon(Icons.share_outlined),
                                onPressed: () {}),
                            IconButton(
                              icon: const Icon(Icons.settings_outlined),
                              onPressed: () => context.push('/settings'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Avatar
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 52,
                          backgroundColor: activeColor.withOpacity(0.2),
                          backgroundImage: profile?['photos']?[0]?['gcs_url'] !=
                                  null
                              ? NetworkImage(profile!['photos'][0]['gcs_url'])
                              : null,
                          child: profile?['photos']?.isEmpty ?? true
                              ? Icon(Icons.person, size: 52, color: activeColor)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => context.push('/profile/edit'),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                  color: activeColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2)),
                              child: const Icon(Icons.edit,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                    const SizedBox(height: 12),

                    Text(
                      profile?['display_name'] ?? 'Your Name',
                      style: PlutoTextStyles.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?['occupation'] ?? 'Add your occupation',
                      style: PlutoTextStyles.bodyMedium
                          .copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),

                    // Mode selector
                    PlutoModeProfileTabs(
                        activeMode: mode,
                        onChanged: (m) =>
                            ref.read(appModeProvider.notifier).setMode(m)),
                  ],
                ),
              ),
            ),

            // ── Profile Completion ───────────────────────────────
            SliverToBoxAdapter(
              child: _ProfileCompletionCard(color: activeColor),
            ),

            // ── Settings Menu ────────────────────────────────────
            SliverList(
              delegate: SliverChildListDelegate([
                _MenuSection(title: 'Account', items: [
                  _MenuItem(
                      icon: Icons.person_outline,
                      label: 'Edit Profile',
                      onTap: () => context.push('/profile/edit')),
                  _MenuItem(
                      icon: Icons.interests_outlined,
                      label: 'My Interests',
                      onTap: () => context.push('/profile/interests')),
                  _MenuItem(
                      icon: Icons.photo_camera_outlined,
                      label: 'Manage Photos',
                      onTap: () {}),
                ]),
                _MenuSection(title: 'Discovery', items: [
                  _MenuItem(
                      icon: Icons.tune_outlined,
                      label: 'Match Preferences',
                      onTap: () {}),
                  _MenuItem(
                      icon: Icons.explore_outlined,
                      label: 'Active Modes',
                      onTap: () {}),
                ]),
                _MenuSection(title: 'Privacy & Safety', items: [
                  _MenuItem(
                      icon: Icons.lock_outline,
                      label: 'Privacy Settings',
                      onTap: () {}),
                  _MenuItem(
                      icon: Icons.block_outlined,
                      label: 'Blocked Users',
                      onTap: () {}),
                ]),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                    },
                    icon: const Icon(Icons.logout, color: PlutoColors.error),
                    label: const Text('Sign Out',
                        style: TextStyle(
                            color: PlutoColors.error,
                            fontFamily: 'Outfit',
                            fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: PlutoColors.error),
                      foregroundColor: PlutoColors.error,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class PlutoModeProfileTabs extends StatelessWidget {
  final String activeMode;
  final ValueChanged<String> onChanged;
  const PlutoModeProfileTabs(
      {super.key, required this.activeMode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const modes = [
      ('DATE', '❤️', 'Date'),
      ('TRAVELBUDDY', '✈️', 'Travel'),
      ('BFF', '🤝', 'BFF')
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: modes.map((m) {
        final isActive = activeMode == m.$1;
        final color = PlutoColors.modeColor(m.$1);
        return GestureDetector(
          onTap: () => onChanged(m.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(m.$2, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Text(m.$3,
                    style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : color)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ProfileCompletionCard extends StatelessWidget {
  final Color color;
  const _ProfileCompletionCard({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_rounded, color: color, size: 18),
              const SizedBox(width: 8),
              Text('Profile Strength: Intermediate',
                  style: PlutoTextStyles.titleMedium.copyWith(color: color)),
              const Spacer(),
              Text('65%',
                  style: TextStyle(
                      fontFamily: 'Outfit',
                      color: color,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(title,
              style: PlutoTextStyles.labelSmall.copyWith(
                color: Colors.grey,
                letterSpacing: 1.5,
              )),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 0, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
      ),
      title: Text(label, style: PlutoTextStyles.titleMedium),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }
}
