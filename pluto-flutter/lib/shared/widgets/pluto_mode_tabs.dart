import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class PlutoModeTabs extends StatelessWidget {
  final String selectedMode;
  final ValueChanged<String> onModeChanged;
  const PlutoModeTabs({super.key, required this.selectedMode, required this.onModeChanged});

  static const _modes = [
    ('DATE', 'Date'),
    ('TRAVELBUDDY', 'TravelBuddy'),
    ('BFF', 'BFF'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: _modes.map((m) {
            final isSelected = selectedMode == m.$1;
            final color = PlutoColors.modeColor(m.$1);
            return Expanded(
              child: GestureDetector(
                onTap: () => onModeChanged(m.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? color : Colors.transparent,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    m.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
