import 'package:flutter/cupertino.dart';

/// The four mood identities used throughout the app.
enum MoodIdentity { upbeat, serene, charged, reflective }

/// Colour palette for a single [MoodIdentity].
///
/// All palettes are designed to meet WCAG AA contrast ratios
/// for their respective [text] colour on [background].
class MoodColors {
  const MoodColors({
    required this.background,
    required this.backgroundEnd,
    required this.text,
    required this.accent,
    required this.tagBackground,
  });

  /// Gradient start colour for hero cards.
  final Color background;

  /// Gradient end colour for hero cards.
  final Color backgroundEnd;

  /// Primary text / icon colour on the hero gradient (meets WCAG AA).
  final Color text;

  /// Accent colour used for rings, pill buttons, and tag borders.
  final Color accent;

  /// Tag pill background (~15 % opacity of [accent]).
  final Color tagBackground;
}

/// Centralised look-up for mood-specific colours, icons, and labels.
class MoodTheme {
  MoodTheme._();

  // ---------------------------------------------------------------------------
  // Colour palettes
  // ---------------------------------------------------------------------------

  /// Returns the [MoodColors] palette for [mood].
  static MoodColors colorsFor(MoodIdentity mood) {
    switch (mood) {
      case MoodIdentity.upbeat:
        // Warm amber → orange.  Dark text for WCAG AA on amber.
        return const MoodColors(
          background: Color(0xFFF5A623),
          backgroundEnd: Color(0xFFE8721A),
          text: Color(0xFF1A0A00),
          accent: Color(0xFFE8721A),
          tagBackground: Color(0x26E8721A), // 15 % opacity
        );

      case MoodIdentity.serene:
        // Soft teal → warm white.  Dark text for WCAG AA on teal.
        return const MoodColors(
          background: Color(0xFF4ECDC4),
          backgroundEnd: Color(0xFFA8E6CF),
          text: Color(0xFF0D2B28),
          accent: Color(0xFF2BAF9A),
          tagBackground: Color(0x262BAF9A),
        );

      case MoodIdentity.charged:
        // Deep purple → electric red.  White text for WCAG AA on dark purple.
        return const MoodColors(
          background: Color(0xFF2D1B69),
          backgroundEnd: Color(0xFFC0392B),
          text: Color(0xFFFFFFFF),
          accent: Color(0xFFC0392B),
          tagBackground: Color(0x26C0392B),
        );

      case MoodIdentity.reflective:
        // Cool slate → dark blue-grey.  White text for WCAG AA on slate.
        return const MoodColors(
          background: Color(0xFF4A6FA5),
          backgroundEnd: Color(0xFF2C3E50),
          text: Color(0xFFFFFFFF),
          accent: Color(0xFF4A6FA5),
          tagBackground: Color(0x264A6FA5),
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Icons
  // ---------------------------------------------------------------------------

  /// Returns a representative [IconData] for [mood].
  static IconData iconFor(MoodIdentity mood) {
    switch (mood) {
      case MoodIdentity.upbeat:
        return CupertinoIcons.sun_max_fill;
      case MoodIdentity.serene:
        return CupertinoIcons.cloud_sun;
      case MoodIdentity.charged:
        return CupertinoIcons.bolt_fill;
      case MoodIdentity.reflective:
        return CupertinoIcons.moon_fill;
    }
  }

  // ---------------------------------------------------------------------------
  // Labels
  // ---------------------------------------------------------------------------

  /// Returns the quadrant label, e.g. "Happy & Energetic".
  static String quadrantLabel(MoodIdentity mood) {
    switch (mood) {
      case MoodIdentity.upbeat:
        return 'Happy & Energetic';
      case MoodIdentity.serene:
        return 'Calm & Positive';
      case MoodIdentity.charged:
        return 'Intense & Powerful';
      case MoodIdentity.reflective:
        return 'Melancholic & Thoughtful';
    }
  }

  /// Returns the short all-caps display label, e.g. "UPBEAT".
  static String shortLabel(MoodIdentity mood) {
    switch (mood) {
      case MoodIdentity.upbeat:
        return 'UPBEAT';
      case MoodIdentity.serene:
        return 'SERENE';
      case MoodIdentity.charged:
        return 'CHARGED';
      case MoodIdentity.reflective:
        return 'REFLECTIVE';
    }
  }

  // ---------------------------------------------------------------------------
  // Backend → MoodIdentity mapping
  // ---------------------------------------------------------------------------

  /// Maps a `primaryMood` string returned by the backend to a [MoodIdentity].
  ///
  /// Falls back to [MoodIdentity.reflective] for unrecognised values.
  static MoodIdentity fromString(String mood) {
    switch (mood.toLowerCase().trim()) {
      case 'upbeat':
      case 'happy':
      case 'energetic':
      case 'joyful':
      case 'excited':
      case 'cheerful':
        return MoodIdentity.upbeat;

      case 'serene':
      case 'calm':
      case 'peaceful':
      case 'relaxed':
      case 'chill':
      case 'tranquil':
        return MoodIdentity.serene;

      case 'charged':
      case 'intense':
      case 'aggressive':
      case 'powerful':
      case 'angry':
      case 'fierce':
        return MoodIdentity.charged;

      case 'reflective':
      case 'melancholic':
      case 'sad':
      case 'thoughtful':
      case 'somber':
      case 'nostalgic':
        return MoodIdentity.reflective;

      default:
        return MoodIdentity.reflective;
    }
  }
}
