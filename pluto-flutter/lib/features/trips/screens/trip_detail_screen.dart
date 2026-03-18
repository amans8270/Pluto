import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/trip_provider.dart';

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
                Text('${trip['joined_count'] ?? 0} joined',
                    style: PlutoTextStyles.bodySmall.copyWith(color: PlutoColors.travel, fontWeight: FontWeight.w600)),
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
