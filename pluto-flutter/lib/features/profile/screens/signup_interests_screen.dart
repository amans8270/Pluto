import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/cache_service.dart';
import '../providers/profile_provider.dart';

class SignUpInterestsScreen extends ConsumerStatefulWidget {
  const SignUpInterestsScreen({super.key});

  @override
  ConsumerState<SignUpInterestsScreen> createState() =>
      _SignUpInterestsScreenState();
}

class _SignUpInterestsScreenState extends ConsumerState<SignUpInterestsScreen> {
  final Set<int> _selectedInterestIds = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cached = ref.read(cacheServiceProvider).getString('pending_interest_ids');
    if (cached != null && cached.isNotEmpty) {
      final ids = cached
          .split(',')
          .map((value) => int.tryParse(value))
          .whereType<int>();
      _selectedInterestIds.addAll(ids);
    }
  }

  Future<void> _continue() async {
    if (_selectedInterestIds.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 3 interests')),
      );
      return;
    }

    setState(() => _saving = true);
    await ref.read(cacheServiceProvider).setString(
          'pending_interest_ids',
          _selectedInterestIds.join(','),
        );

    if (mounted) {
      context.go('/profile/edit');
    }
  }

  @override
  Widget build(BuildContext context) {
    final interestsAsync = ref.watch(availableInterestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: const LinearProgressIndicator(
                  value: 0.35,
                  backgroundColor: Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => context.go('/profile/edit'),
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: interestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load interests: $e')),
        data: (interests) => Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What are you into?',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pick 3 to 10 interests so Pluto can build a better discover feed.',
                    style: TextStyle(color: Colors.grey[700], fontSize: 15),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Selected: ${_selectedInterestIds.length}/10',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: interests.map((item) {
                      final id = item['id'] as int;
                      final name = item['name'] as String;
                      final isSelected = _selectedInterestIds.contains(id);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedInterestIds.remove(id);
                            } else if (_selectedInterestIds.length < 10) {
                              _selectedInterestIds.add(id);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFD7B9FF)
                                : const Color(0xFFEAEAEA),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton(
                backgroundColor: Colors.black,
                onPressed: _saving ? null : _continue,
                child: _saving
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.chevron_right, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
