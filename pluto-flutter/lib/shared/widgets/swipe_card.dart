import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';

class SwipeCard extends StatelessWidget {
  final Map<String, dynamic> candidate;
  final String mode;
  const SwipeCard({super.key, required this.candidate, required this.mode});

  @override
  Widget build(BuildContext context) {
    final photos = (candidate['photos'] as List?)?.cast<String>() ?? [];
    final interests = (candidate['interests'] as List?)?.cast<String>() ?? [];
    final activeColor = PlutoColors.modeColor(mode);
    final modeLabel = {'DATE': 'DATE MODE', 'TRAVELBUDDY': 'TRAVELBUDDY MODE', 'BFF': 'BFF MODE'}[mode]!;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 10)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            photos.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photos[0],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: Colors.grey[200]),
                    errorWidget: (_, __, ___) => Container(
                      color: activeColor.withOpacity(0.15),
                      child: Icon(Icons.person, size: 100, color: activeColor.withOpacity(0.3)),
                    ),
                  )
                : Container(
                    color: activeColor.withOpacity(0.15),
                    child: Icon(Icons.person, size: 100, color: activeColor.withOpacity(0.3)),
                  ),

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1.0],
                  ),
                ),
              ),
            ),

            // Mode badge
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  modeLabel,
                  style: const TextStyle(
                    fontFamily: 'Outfit', color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Info at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${candidate['display_name'] ?? 'Unknown'}, ${candidate['age'] ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Outfit', color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Color(0xFF60B8FF), size: 20),
                      ],
                    ),
                    if (candidate['dist_km'] != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.white70, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${candidate['dist_km']} km away',
                            style: const TextStyle(fontFamily: 'Outfit', color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                    if (candidate['bio'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        candidate['bio'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'Outfit', color: Colors.white70, fontSize: 14),
                      ),
                    ],
                    if (interests.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: interests.take(4).map((tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(tag, style: const TextStyle(fontFamily: 'Outfit', color: Colors.white, fontSize: 12)),
                        )).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
