import 'package:flutter/cupertino.dart';

/// A horizontal wrapping row of pill-shaped descriptor tags.
///
/// Used below the hero card on the Results screen to display mood descriptors
/// such as "upbeat", "danceable", "bright".
///
/// Uses the wireframe neutral palette — warm cream background with dark-brown
/// text — so the pills read cleanly on any page background.
class MoodDescriptorTags extends StatelessWidget {
  const MoodDescriptorTags({
    required this.tags,
    super.key,
  });

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) => _DescriptorPill(tag: tag)).toList(),
    );
  }
}

class _DescriptorPill extends StatelessWidget {
  const _DescriptorPill({required this.tag});

  final String tag;

  // Wireframe neutral palette: warm cream / warm mid-border / dark-brown text.
  static const _bg = Color(0xFFD4CEC1);
  static const _border = Color(0xFFB9B1A3);
  static const _text = Color(0xFF2D2A26);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border, width: 0.5),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _text,
        ),
      ),
    );
  }
}
