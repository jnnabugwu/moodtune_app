import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/narration/presentation/mood_narrator.dart';

/// Shows the template reasoning immediately, then swaps in the on-device
/// narration if one arrives. The page never waits on the model.
///
/// Renders nothing (not even [padding]) while there is no text, so the page
/// can mount it even when the backend sends no reasoning.
class MoodNarrationText extends StatefulWidget {
  const MoodNarrationText({
    required this.analysis,
    required this.narrator,
    required this.style,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final AudioUploadAnalysis analysis;
  final MoodNarrator narrator;
  final TextStyle style;
  final EdgeInsetsGeometry padding;

  @override
  State<MoodNarrationText> createState() => _MoodNarrationTextState();
}

class _MoodNarrationTextState extends State<MoodNarrationText> {
  late MoodNarration _narration;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(MoodNarrationText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The results page rebuilds in place when a new analysis arrives.
    if (oldWidget.analysis.id != widget.analysis.id) _load();
  }

  void _load() {
    final analysis = widget.analysis;
    _narration = MoodNarration(
      text: analysis.mood.reasoning,
      source: NarrationSource.template,
    );
    unawaited(
      widget.narrator.narrate(analysis).then((narration) {
        // Drop late results for an analysis that is no longer shown.
        if (mounted && widget.analysis.id == analysis.id) {
          setState(() => _narration = narration);
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_narration.text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              _narration.text,
              key: ValueKey(_narration.source),
              style: widget.style,
            ),
          ),
          if (_narration.source == NarrationSource.onDevice)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Written on-device by Apple Intelligence',
                style: widget.style.copyWith(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
