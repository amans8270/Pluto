import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/trip_provider.dart';
import '../providers/workflow_provider.dart';

class TripDetailScreen extends ConsumerWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripAsync = ref.watch(tripDetailProvider(tripId));

    return Scaffold(
      body: tripAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: PlutoColors.travel)),
        error: (e, _) => Center(child: Text('Failed to load trip')),
        data: (trip) => _TripDetailBody(trip: trip),
      ),
      bottomNavigationBar: tripAsync.when(
        data: (trip) => _TripBottomBar(trip: trip),
        loading: () => null,
        error: (_, __) => null,
      ),
    );
  }
}

class _TripBottomBar extends ConsumerWidget {
  final Map<String, dynamic> trip;
  const _TripBottomBar({required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = trip['is_owner'] ?? false;
    final viewerStatus = trip['viewer_status'] ?? 'NONE';
    final tripId = trip['id'].toString();
    final appBarId = trip['application_id']?.toString();
    final actionState = ref.watch(workflowActionProvider);

    if (isOwner) {
      return _BottomButton(
        label: 'Manage Applicants',
        onPressed: () => context.push('/trips/$tripId/applicants'),
        color: PlutoColors.travel,
      );
    }

    // If member but not owner, check if they can vote (handled in a separate screen or here)
    if (viewerStatus == 'MEMBER') {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BottomButton(
            label: 'Vote on Applicants',
            onPressed: () => context.push('/trips/$tripId/applicants'), // Members can also view and vote
            color: Colors.blueAccent,
          ),
          const _StatusBadge(label: 'You are a member! 🎉', color: Colors.green),
        ],
      );
    }

    switch (viewerStatus) {
      case 'NONE':
        return _BottomButton(
          label: 'Apply to Join',
          onPressed: () => ref.read(workflowActionProvider.notifier).apply(tripId),
          color: PlutoColors.travel,
          isLoading: actionState.isLoading,
        );
      case 'APPLIED':
        return const _StatusBadge(label: 'Wait: Pending Owner Approval ⏳', color: Colors.orange);
      case 'GROUP_PENDING':
        return const _StatusBadge(label: 'Wait: Awaiting Group Votes 🗳️', color: Colors.blueGrey);
      case 'GROUP_APPROVED':
        return _BottomButton(
          label: 'Pay ₹11 to Join',
          onPressed: () => context.push('/applications/$appBarId/pay?tripId=$tripId'),
          color: Colors.green,
        );
      case 'FINALIZED':
        return const _StatusBadge(label: 'Membership Confirmed! ✅', color: Colors.green);
      case 'REJECTED':
        return const _StatusBadge(label: 'Application Not Approved', color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _BottomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool isLoading;
  final String? labelOverride;

  const _BottomButton({
    required this.label,
    required this.onPressed,
    required this.color,
    this.isLoading = false,
    this.labelOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(labelOverride ?? label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Outfit')),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      color: color.withOpacity(0.1),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Outfit'),
      ),
    );
  }
}

class _TripDetailBody extends StatelessWidget {
  final Map<String, dynamic> trip;
  const _TripDetailBody({required this.trip});

  @override
  Widget build(BuildContext context) {
    final spotsLeft = trip['spots_left'] ?? 0;
    final fee = trip['entry_fee_inr'] ?? 0;
    final hasFee = (fee as num) > 0;

    return CustomScrollView(
      slivers: [
        // ── Hero Image ─────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: PlutoColors.travel,
          leading: GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
              child: IconButton(icon: const Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: trip['cover_image_url'] != null
                ? CachedNetworkImage(imageUrl: trip['cover_image_url'], fit: BoxFit.cover)
                : Container(color: PlutoColors.travel.withOpacity(0.3), child: const Icon(Icons.landscape, size: 80, color: PlutoColors.travel)),
          ),
        ),

        // ── Content ────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category + days
                Row(
                  children: [
                    _Chip(label: trip['category'] ?? 'TRIP', color: PlutoColors.travel),
                    const SizedBox(width: 8),
                    if (trip['start_date'] != null && trip['end_date'] != null)
                      _Chip(label: '${_tripDays(trip['start_date'], trip['end_date'])} DAYS', color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(trip['title'] ?? '', style: PlutoTextStyles.displayMedium),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on, color: PlutoColors.travel, size: 16),
                    const SizedBox(width: 4),
                    Text(trip['destination'] ?? '', style: PlutoTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats row
                Row(
                  children: [
                    _StatItem(label: 'Level', value: trip['difficulty'] ?? 'Easy'),
                    _StatItem(label: 'Temp', value: trip['temperature'] ?? '--'),
                    _StatItem(label: 'Group', value: '${trip['max_members'] ?? '--'} Max'),
                  ],
                ),
                const Divider(height: 32),

                // The Plan
                if (trip['description'] != null) ...[
                  Text('About This Trip', style: PlutoTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text(trip['description'], style: PlutoTextStyles.bodyMedium.copyWith(color: Colors.grey[700], height: 1.6)),
                  const Divider(height: 32),
                ],

                // Current Buddies
                Text('Current Buddies', style: PlutoTextStyles.headlineSmall),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => context.push('/trips/${trip['id']}/members'),
                  child: Text('${trip['joined_count'] ?? 0} joined',
                      style: PlutoTextStyles.bodySmall.copyWith(color: PlutoColors.travel, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (trip['joined_count'] ?? 0) > 5 ? 6 : (trip['joined_count'] ?? 0),
                    itemBuilder: (_, i) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(radius: 22, backgroundColor: PlutoColors.travel.withOpacity(0.2 + i * 0.1)),
                    ),
                  ),
                ),
                const SizedBox(height: 100), // bottom padding for button
              ],
            ),
          ),
        ),
      ],
    );
  }

  int _tripDays(String start, String end) {
    try {
      final s = DateTime.parse(start);
      final e = DateTime.parse(end);
      return e.difference(s).inDays + 1;
    } catch (_) { return 1; }
  }
}

class _Chip extends StatelessWidget {
  final String label; final Color color;
  const _Chip({required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontFamily: 'Outfit', color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );
}

class _StatItem extends StatelessWidget {
  final String label, value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(label, style: PlutoTextStyles.bodySmall.copyWith(color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: PlutoTextStyles.titleMedium),
      ],
    ),
  );
}
