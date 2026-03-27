import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/trip_provider.dart';

class TripFeedScreen extends ConsumerWidget {
  const TripFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripFeedProvider);
    const teal = PlutoColors.travel;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  const Icon(Icons.menu, size: 24),
                  const SizedBox(width: 12),
                  Text('Pluto',
                      style: PlutoTextStyles.headlineMedium
                          .copyWith(color: teal, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: teal),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Search Bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, size: 18, color: Colors.grey[500]),
                          const SizedBox(width: 8),
                          Text('Find trips in Delhi',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontFamily: 'Outfit',
                                  fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: teal, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Trip List ────────────────────────────────────────
            Expanded(
              child: tripsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator(color: teal)),
                error: (e, _) =>
                    const Center(child: Text('Failed to load trips')),
                data: (trips) => ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: trips.length,
                  itemBuilder: (ctx, i) => TripCard(trip: trips[i])
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i * 80))
                      .slideY(begin: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/trips/create'),
        backgroundColor: teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Trip',
            style: TextStyle(
                fontFamily: 'Outfit',
                fontWeight: FontWeight.w600,
                color: Colors.white)),
      ),
    );
  }
}

// ─── Trip Card ────────────────────────────────────────────────────────────────
class TripCard extends StatelessWidget {
  final Map<String, dynamic> trip;
  const TripCard({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    final spotsLeft = trip['spots_left'] ?? 0;
    final joined = trip['joined_count'] ?? 0;
    final fee = trip['entry_fee_inr'] ?? 0;
    final feeLabel = fee == 0 ? 'Free' : '₹${fee.toStringAsFixed(0)}';

    return GestureDetector(
      onTap: () => context.push('/trips/${trip['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover image
              Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: trip['cover_image_url'] != null
                        ? CachedNetworkImage(
                            imageUrl: trip['cover_image_url'],
                            fit: BoxFit.cover)
                        : Container(
                            color: PlutoColors.travel.withOpacity(0.15),
                            child: const Icon(Icons.landscape,
                                size: 60, color: PlutoColors.travel),
                          ),
                  ),
                  // Creator avatar
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: trip['creator_photo'] != null
                              ? NetworkImage(trip['creator_photo'])
                              : null,
                          backgroundColor: PlutoColors.travel.withOpacity(0.3),
                          child: trip['creator_photo'] == null
                              ? const Icon(Icons.person,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          trip['creator_name'] ?? 'Organizer',
                          style: const TextStyle(
                              fontFamily: 'Outfit',
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // Spots left badge
                  if (spotsLeft <= 3 && spotsLeft > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                            color: PlutoColors.dating,
                            borderRadius: BorderRadius.circular(20)),
                        child: Text('$spotsLeft spots left',
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),

              // Info
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (trip['category'] != null)
                          Text(trip['category'].toString().toUpperCase(),
                              style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  color: PlutoColors.travel,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        const Spacer(),
                        Text(_feeToSymbol(fee),
                            style: const TextStyle(
                                fontFamily: 'Outfit',
                                color: Colors.grey,
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(trip['title'] ?? '',
                        style: PlutoTextStyles.headlineSmall),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(_formatDates(trip['start_date'], trip['end_date']),
                            style: PlutoTextStyles.bodySmall
                                .copyWith(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Member stacks
                        SizedBox(
                          width: 60,
                          height: 28,
                          child: Stack(
                            children: List.generate(
                                3,
                                (i) => Positioned(
                                      left: i * 18.0,
                                      child: CircleAvatar(
                                          radius: 14,
                                          backgroundColor: PlutoColors.travel
                                              .withOpacity(0.2 + i * 0.15)),
                                    )),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (joined > 3)
                          Text('+${joined - 3}',
                              style: PlutoTextStyles.bodySmall
                                  .copyWith(color: Colors.grey)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: PlutoColors.travel,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text('View Trip',
                              style: TextStyle(
                                  fontFamily: 'Outfit',
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _feeToSymbol(dynamic fee) {
    if (fee == null || fee == 0) return 'Free';
    final f = (fee as num).toDouble();
    if (f < 500) return '₹';
    if (f < 2000) return '₹₹';
    if (f < 5000) return '₹₹₹';
    return '₹₹₹₹';
  }

  String _formatDates(String? start, String? end) {
    if (start == null) return '';
    return '$start${end != null ? ' - $end' : ''}';
  }
}
