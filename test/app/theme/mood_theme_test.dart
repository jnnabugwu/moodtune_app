import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';

void main() {
  group('MoodTheme.colorsFor', () {
    test('upbeat uses amber/orange palette with dark text', () {
      final c = MoodTheme.colorsFor(MoodIdentity.upbeat);
      expect(c.background, const Color(0xFFF5A623));
      expect(c.backgroundEnd, const Color(0xFFE8721A));
      expect(c.text, const Color(0xFF1A0A00));
      expect(c.accent, const Color(0xFFE8721A));
      expect(c.tagBackground, const Color(0x26E8721A));
    });

    test('serene uses teal palette with dark text', () {
      final c = MoodTheme.colorsFor(MoodIdentity.serene);
      expect(c.background, const Color(0xFF4ECDC4));
      expect(c.backgroundEnd, const Color(0xFFA8E6CF));
      expect(c.text, const Color(0xFF0D2B28));
      expect(c.accent, const Color(0xFF2BAF9A));
      expect(c.tagBackground, const Color(0x262BAF9A));
    });

    test('charged uses purple/red palette with white text', () {
      final c = MoodTheme.colorsFor(MoodIdentity.charged);
      expect(c.background, const Color(0xFF2D1B69));
      expect(c.backgroundEnd, const Color(0xFFC0392B));
      expect(c.text, const Color(0xFFFFFFFF));
      expect(c.accent, const Color(0xFFC0392B));
      expect(c.tagBackground, const Color(0x26C0392B));
    });

    test('reflective uses slate palette with white text', () {
      final c = MoodTheme.colorsFor(MoodIdentity.reflective);
      expect(c.background, const Color(0xFF4A6FA5));
      expect(c.backgroundEnd, const Color(0xFF2C3E50));
      expect(c.text, const Color(0xFFFFFFFF));
      expect(c.accent, const Color(0xFF4A6FA5));
      expect(c.tagBackground, const Color(0x264A6FA5));
    });

    test('tag background is the accent at ~15% opacity for every mood', () {
      for (final mood in MoodIdentity.values) {
        final c = MoodTheme.colorsFor(mood);
        expect(
          c.tagBackground.toARGB32() & 0x00FFFFFF,
          c.accent.toARGB32() & 0x00FFFFFF,
          reason: '$mood tag background should share the accent RGB',
        );
        expect((c.tagBackground.a * 255).round(), 0x26);
      }
    });
  });

  group('MoodTheme.iconFor', () {
    test('returns a distinct icon per mood', () {
      expect(
        MoodTheme.iconFor(MoodIdentity.upbeat),
        CupertinoIcons.sun_max_fill,
      );
      expect(MoodTheme.iconFor(MoodIdentity.serene), CupertinoIcons.cloud_sun);
      expect(MoodTheme.iconFor(MoodIdentity.charged), CupertinoIcons.bolt_fill);
      expect(
        MoodTheme.iconFor(MoodIdentity.reflective),
        CupertinoIcons.moon_fill,
      );
    });
  });

  group('MoodTheme labels', () {
    test('quadrantLabel', () {
      expect(MoodTheme.quadrantLabel(MoodIdentity.upbeat), 'Happy & Energetic');
      expect(MoodTheme.quadrantLabel(MoodIdentity.serene), 'Calm & Positive');
      expect(
        MoodTheme.quadrantLabel(MoodIdentity.charged),
        'Intense & Powerful',
      );
      expect(
        MoodTheme.quadrantLabel(MoodIdentity.reflective),
        'Melancholic & Thoughtful',
      );
    });

    test('shortLabel', () {
      expect(MoodTheme.shortLabel(MoodIdentity.upbeat), 'UPBEAT');
      expect(MoodTheme.shortLabel(MoodIdentity.serene), 'SERENE');
      expect(MoodTheme.shortLabel(MoodIdentity.charged), 'CHARGED');
      expect(MoodTheme.shortLabel(MoodIdentity.reflective), 'REFLECTIVE');
    });
  });

  group('MoodTheme.fromString', () {
    const expectations = <MoodIdentity, List<String>>{
      MoodIdentity.upbeat: [
        'upbeat',
        'happy',
        'energetic',
        'joyful',
        'excited',
        'cheerful',
      ],
      MoodIdentity.serene: [
        'serene',
        'calm',
        'peaceful',
        'relaxed',
        'chill',
        'tranquil',
      ],
      MoodIdentity.charged: [
        'charged',
        'intense',
        'aggressive',
        'powerful',
        'angry',
        'fierce',
      ],
      MoodIdentity.reflective: [
        'reflective',
        'melancholic',
        'sad',
        'thoughtful',
        'somber',
        'nostalgic',
      ],
    };

    for (final entry in expectations.entries) {
      for (final value in entry.value) {
        test('"$value" maps to ${entry.key}', () {
          expect(MoodTheme.fromString(value), entry.key);
        });
      }
    }

    test('is case-insensitive and trims whitespace', () {
      expect(MoodTheme.fromString('  HaPpY  '), MoodIdentity.upbeat);
      expect(MoodTheme.fromString('CALM\n'), MoodIdentity.serene);
      expect(MoodTheme.fromString(' Angry'), MoodIdentity.charged);
    });

    test('falls back to reflective for unknown or empty values', () {
      expect(MoodTheme.fromString('danceable'), MoodIdentity.reflective);
      expect(MoodTheme.fromString(''), MoodIdentity.reflective);
    });
  });
}
