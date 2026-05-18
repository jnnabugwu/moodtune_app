import 'package:flutter/cupertino.dart';

/// A horizontal wrapping row of pill-shaped descriptor tags.
///
/// Used below the hero card on the Results screen to display mood descriptors
/// such as "upbeat", "danceable", "bright".
class MoodDescriptorTags extends StatelessWidget {
  const MoodDescriptorTags({
    required this.tags,
    required this.accentColor,
    super.key,
  });

  final List<String> tags;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags
          .map((tag) => _DescriptorPill(tag: tag, accentColor: accentColor))
          .toList(),
    );
  }
}

class _DescriptorPill extends StatelessWidget {
  const _DescriptorPill({required this.tag, required this.accentColor});

  final String tag;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ~15 % opacity background
        color: accentColor.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withAlpha(80),
          width: 0.5,
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: accentColor,
        ),
      ),
    );
  }
}
