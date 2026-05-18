import 'package:flutter/cupertino.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/shared/widgets/confidence_ring.dart';

/// A full-width hero card that displays the primary mood result for an
/// [AudioUploadAnalysis].
///
/// Stagger animation sequence (spec §5.3):
/// * T+0 ms   — gradient background fades in
/// * T+200 ms — mood icon fades in
/// * T+300 ms — primary label slides up 12 px and fades in
/// * T+400 ms — quadrant name fades in
/// * T+500 ms — confidence ring fades in (ring draws itself over 400 ms)
///
/// When [MediaQueryData.disableAnimations] is true all elements appear
/// instantly at full opacity.
class MoodHeroCard extends StatefulWidget {
  const MoodHeroCard({
    required this.analysis,
    super.key,
  });

  final AudioUploadAnalysis analysis;

  @override
  State<MoodHeroCard> createState() => _MoodHeroCardState();
}

class _MoodHeroCardState extends State<MoodHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Total duration that covers all stagger intervals (ms).
  static const int _durationMs = 700;

  late final Animation<double> _bgOpacity;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _labelOpacity;
  late final Animation<double> _labelSlideY; // 12 px → 0 px
  late final Animation<double> _quadrantOpacity;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _durationMs),
    );

    _bgOpacity = _fade(0, 200);
    _iconOpacity = _fade(200, 400);
    _labelOpacity = _fade(300, 500);
    _labelSlideY = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          300 / _durationMs,
          500 / _durationMs,
          curve: Curves.easeOut,
        ),
      ),
    );
    _quadrantOpacity = _fade(400, 600);
    _ringOpacity = _fade(500, _durationMs);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.of(context).disableAnimations) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
      }
    });
  }

  /// Convenience — builds an opacity [Animation] active between [startMs] and
  /// [endMs] (both in milliseconds, relative to the controller's total).
  Animation<double> _fade(int startMs, int endMs) =>
      Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            startMs / _durationMs,
            endMs / _durationMs,
            curve: Curves.easeOut,
          ),
        ),
      );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final identity =
        MoodTheme.fromString(widget.analysis.mood.primaryMood);
    final colors = MoodTheme.colorsFor(identity);
    final icon = MoodTheme.iconFor(identity);
    final quadrant = MoodTheme.quadrantLabel(identity);
    final short = MoodTheme.shortLabel(identity);
    final confidence = widget.analysis.mood.confidence;

    return FadeTransition(
      opacity: _bgOpacity,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colors.background, colors.backgroundEnd],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Mood icon
            FadeTransition(
              opacity: _iconOpacity,
              child: Icon(icon, size: 56, color: colors.text),
            ),
            const SizedBox(height: 16),

            // Primary mood label — fades + slides up
            FadeTransition(
              opacity: _labelOpacity,
              child: AnimatedBuilder(
                animation: _labelSlideY,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, _labelSlideY.value),
                  child: child,
                ),
                child: Text(
                  short,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Quadrant name
            FadeTransition(
              opacity: _quadrantOpacity,
              child: Text(
                quadrant,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colors.text.withAlpha(180),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Confidence ring — mounts and self-animates when revealed
            FadeTransition(
              opacity: _ringOpacity,
              child: ConfidenceRing(
                value: confidence,
                color: colors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
