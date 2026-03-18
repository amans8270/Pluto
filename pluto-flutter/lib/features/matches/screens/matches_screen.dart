import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_outline, size: 64, color: PlutoColors.dating.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('Your matches will appear here', style: PlutoTextStyles.bodyLarge),
          ],
        ),
      ),
    );
  }
}
