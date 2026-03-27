import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/interests.dart';
import '../providers/profile_provider.dart';

class SignUpInterestsScreen extends ConsumerStatefulWidget {
  const SignUpInterestsScreen({super.key});

  @override
  ConsumerState<SignUpInterestsScreen> createState() =>
      _SignUpInterestsScreenState();
}

class _SignUpInterestsScreenState extends ConsumerState<SignUpInterestsScreen> {
  final Set<String> _selectedInterests = {};
  final Set<String> _expandedCategories = {interestCategories.first.id};

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        _selectedInterests.remove(interest);
      } else {
        if (_selectedInterests.length < 10) {
          _selectedInterests.add(interest);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can select up to 10 interests')),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F2), // Light beige/cream background
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
                  value: 0.7, // 70% progress
                  backgroundColor: Color(0xFFE0E0E0),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () => context.push('/profile/edit'),
              child: const Text('Skip',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What are you excited about?',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'My selection : ${_selectedInterests.length}/10',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_selectedInterests.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedInterests.map((interest) {
                            return _InterestChip(
                              label: interest,
                              isSelected: true,
                              onTap: () => _toggleInterest(interest),
                            );
                          }).toList(),
                        )
                      else
                        const Row(
                          children: [
                            _PlaceholderChip(icon: Icons.tv),
                            SizedBox(width: 8),
                            _PlaceholderChip(icon: Icons.music_note),
                            SizedBox(width: 8),
                            _PlaceholderChip(icon: Icons.sports_basketball),
                          ],
                        ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: interestCategories.length,
                  itemBuilder: (context, index) {
                    final category = interestCategories[index];
                    final isExpanded =
                        _expandedCategories.contains(category.id);

                    return _CategorySection(
                      category: category,
                      isExpanded: isExpanded,
                      selectedInterests: _selectedInterests,
                      onToggleExpand: () {
                        setState(() {
                          if (isExpanded) {
                            _expandedCategories.remove(category.id);
                          } else {
                            _expandedCategories.add(category.id);
                          }
                        });
                      },
                      onInterestTap: _toggleInterest,
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              onPressed: () {
                if (_selectedInterests.length < 3) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select at least 3 interests')),
                  );
                  return;
                }
                // Save selected interests to provider or pass to next screen
                // For now, we'll navigate to edit profile to finish the bio/photos
                context.push('/profile/edit');
              },
              child: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatefulWidget {
  final InterestCategory category;
  final bool isExpanded;
  final Set<String> selectedInterests;
  final VoidCallback onToggleExpand;
  final Function(String) onInterestTap;

  const _CategorySection({
    required this.category,
    required this.isExpanded,
    required this.selectedInterests,
    required this.onToggleExpand,
    required this.onInterestTap,
  });

  @override
  State<_CategorySection> createState() => _CategorySectionState();
}

class _CategorySectionState extends State<_CategorySection> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final displayedInterests = _showAll
        ? widget.category.interests
        : widget.category.interests.take(12).toList();

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: Icon(widget.category.icon, color: Colors.black, size: 24),
          title: Text(
            widget.category.label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          trailing: Icon(
            widget.isExpanded
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_down,
            color: Colors.black,
          ),
          onTap: widget.onToggleExpand,
        ),
        if (widget.isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: displayedInterests.map((interest) {
                    final isSelected =
                        widget.selectedInterests.contains(interest);
                    return _InterestChip(
                      label: interest,
                      isSelected: isSelected,
                      onTap: () => widget.onInterestTap(interest),
                    );
                  }).toList(),
                ),
                if (widget.category.interests.length > 12)
                  TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(
                      _showAll ? 'See less' : 'See more',
                      style: const TextStyle(
                          color: Colors.grey,
                          decoration: TextDecoration.underline),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD7B9FF) : const Color(0xFFEAEAEA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderChip extends StatelessWidget {
  final IconData icon;
  const _PlaceholderChip({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.grey.withOpacity(0.3),
            width: 1.5,
            style: BorderStyle.solid),
      ),
      child: Icon(icon, color: Colors.grey.withOpacity(0.3)),
    );
  }
}
