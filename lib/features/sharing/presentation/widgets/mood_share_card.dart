import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_content.dart';
import 'package:moodtune_app/features/sharing/domain/share_links.dart';
import 'package:moodtune_app/shared/widgets/moodtune_note_mark.dart';

/// The "dark poster" share card (D9), laid out at 432×540 logical pixels
/// and exported at ×2.5 for the 1080×1350 (4:5) PNG (R2, R3).
///
/// Static by design: no animation, no [AnimationController], no ambient
/// theme, so it rasterizes offscreen the same way every time. Everything on
/// it comes from [ShareContent], which is already privacy-filtered (R8).
class MoodShareCard extends StatelessWidget {
  const MoodShareCard({required this.content, super.key});

  final ShareContent content;

  /// Logical layout size; multiply by [exportPixelRatio] for the PNG.
  static const Size logicalSize = Size(432, 540);

  /// 432×540 × 2.5 = 1080×1350.
  static const double exportPixelRatio = 2.5;

  static const String fontFamily = 'Inter Tight';

  // Brand tokens (D9).
  static const Color ink = Color(0xFF2D2A26);
  static const Color cream = Color(0xFFEFECE6);
  static const Color peach = Color(0xFFD99D77);
  static const Color muted = Color(0xFFB8B0A3);

  static const String ctaText = 'What does your song feel like?';

  /// Mood-word colour, chosen for contrast on [ink] rather than
  /// `MoodTheme.text`.
  static Color accentFor(MoodIdentity mood) => switch (mood) {
    MoodIdentity.upbeat => const Color(0xFFF5A623),
    MoodIdentity.serene => const Color(0xFF4ECDC4),
    MoodIdentity.charged => const Color(0xFFE8554A),
    MoodIdentity.reflective => const Color(0xFF7FA3D6),
  };

  /// "charged" → "Charged."
  static String moodWord(MoodIdentity mood) {
    final name = mood.name;
    return '${name[0].toUpperCase()}${name.substring(1)}.';
  }

  /// `"<title> — <artist>"`, the title alone without an artist, or null
  /// without a title.
  static String? trackLine(ShareContent content) {
    final title = content.title;
    if (title == null) return null;
    final artist = content.artist;
    return artist == null ? title : '$title — $artist';
  }

  @override
  Widget build(BuildContext context) {
    final colors = MoodTheme.colorsFor(content.mood);
    final track = trackLine(content);
    final descriptors = content.descriptors
        .take(ShareContent.maxDescriptors)
        .join(' · ');

    return SizedBox.fromSize(
      size: logicalSize,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: ColoredBox(
          color: ink,
          child: Stack(
            children: [
              // Orb: 260 px, centred 60 px inside the top-right corner.
              Positioned(
                top: -70,
                right: -70,
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: _gradientBegin,
                      end: _gradientEnd,
                      colors: [colors.background, colors.backgroundEnd],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _Lockup(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (track != null) ...[
                          Text(
                            track,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _secondaryStyle,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          moodWord(content.mood),
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 70,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -2.8, // −4 % of 70
                            height: 0.92,
                            color: accentFor(content.mood),
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          MoodTheme.quadrantLabel(content.mood),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: cream,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        if (descriptors.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            descriptors,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _secondaryStyle,
                          ),
                        ],
                      ],
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            ctaText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: muted,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          ShareLinks.displayDomain,
                          style: TextStyle(
                            fontFamily: fontFamily,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cream,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _secondaryStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: muted,
    decoration: TextDecoration.none,
  );

  // A CSS 150° gradient: 0° points up and angles run clockwise, so the
  // direction vector is (sin 150°, −cos 150°) = (0.5, 0.866).
  static final Alignment _gradientEnd = Alignment(
    math.sin(150 * math.pi / 180),
    -math.cos(150 * math.pi / 180),
  );
  static final Alignment _gradientBegin = -_gradientEnd;
}

/// Note mark (26 px, peach with ink face) and the `moodtune` wordmark.
class _Lockup extends StatelessWidget {
  const _Lockup();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MoodTuneNoteMark(
          size: 26,
          noteColor: MoodShareCard.peach,
          faceColor: MoodShareCard.ink,
        ),
        SizedBox(width: 8),
        Text(
          'moodtune',
          style: TextStyle(
            fontFamily: MoodShareCard.fontFamily,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: MoodShareCard.cream,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
