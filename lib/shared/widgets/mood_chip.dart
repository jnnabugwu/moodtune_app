import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';

/// A pill-shaped filter chip styled with a [MoodIdentity] accent colour.
///
/// When [isSelected] is true the chip uses a filled accent background;
/// otherwise it renders as an outlined ghost chip.
class MoodChip extends StatelessWidget {
  const MoodChip({
    required this.label,
    required this.mood,
    super.key,
    this.isSelected = false,
    this.onTap,
  });

  final String label;
  final MoodIdentity mood;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = MoodTheme.colorsFor(mood);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.accent
              : CupertinoColors.tertiarySystemFill,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? colors.accent : CupertinoColors.separator,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? CupertinoColors.white
                : CupertinoColors.label,
          ),
        ),
      ),
    );
  }
}
