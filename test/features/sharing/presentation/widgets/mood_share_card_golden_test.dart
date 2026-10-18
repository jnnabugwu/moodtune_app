import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/sharing/sharing.dart';

import '../../../../helpers/fonts.dart';
import '../../sharing_fixtures.dart';

/// The goldens are generated on Linux, where CI runs (`flutter test
/// --update-goldens` on Linux). macOS renders text anti-aliasing about 3 %
/// differently, so regenerate them on Linux, not a Mac. The small budget
/// below only absorbs renderer noise between Flutter patch releases; it is
/// far smaller than a missing line of text.
///
/// Wraps whatever comparator is active (the default `LocalFileComparator`,
/// or the path-aware one `very_good test --optimization` installs) so
/// golden paths keep resolving the same way.
class _TolerantGoldenComparator extends GoldenFileComparator {
  _TolerantGoldenComparator(this._inner);

  final GoldenFileComparator _inner;

  /// Up to this share of pixels may differ (0.1 %, about 230 px).
  static const double maxDiffPercent = 0.1;

  // flutter_test reports "Pixel test failed, 0.26%, 123px diff detected."
  static final _diffPercent = RegExp(r'Pixel test failed, ([\d.]+)%');

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    try {
      return await _inner.compare(imageBytes, golden);
      // LocalFileComparator reports a pixel mismatch as a FlutterError, so
      // that is what carries the diff percentage.
      // ignore: avoid_catching_errors
    } on FlutterError catch (error) {
      final match = _diffPercent.firstMatch(error.message);
      final percent = match == null ? null : double.tryParse(match.group(1)!);
      if (percent != null && percent <= maxDiffPercent) return true;
      rethrow;
    }
  }

  @override
  Uri getTestUri(Uri key, int? version) => _inner.getTestUri(key, version);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      _inner.update(golden, imageBytes);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    goldenFileComparator = _TolerantGoldenComparator(goldenFileComparator);
  });

  Future<void> pumpCard(WidgetTester tester, ShareContent content) async {
    tester.view.physicalSize = MoodShareCard.logicalSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.noScaling),
          child: Center(child: MoodShareCard(content: content)),
        ),
      ),
    );
  }

  group('MoodShareCard goldens (AC2, R12)', () {
    for (final mood in [
      MoodIdentity.charged,
      MoodIdentity.serene,
      MoodIdentity.reflective,
    ]) {
      testWidgets('${mood.name} with descriptors', (tester) async {
        await pumpCard(tester, testShareContent(mood: mood));

        await expectLater(
          find.byType(MoodShareCard),
          matchesGoldenFile('goldens/mood_share_card_${mood.name}_tags.png'),
        );
      });

      testWidgets('${mood.name} without descriptors (history share)', (
        tester,
      ) async {
        await pumpCard(
          tester,
          testShareContent(mood: mood, descriptors: const []),
        );

        await expectLater(
          find.byType(MoodShareCard),
          matchesGoldenFile('goldens/mood_share_card_${mood.name}_no_tags.png'),
        );
      });
    }
  });

  group('MoodShareCard layout', () {
    testWidgets('shows mood word, quadrant, track line, tags and CTA', (
      tester,
    ) async {
      await pumpCard(tester, testShareContent());

      expect(find.text('Charged.'), findsOneWidget);
      expect(find.text('Intense & Powerful'), findsOneWidget);
      expect(find.text('Blinding Lights — The Weeknd'), findsOneWidget);
      expect(find.text('intense · driving · bright'), findsOneWidget);
      expect(find.text('moodtune'), findsOneWidget);
      expect(find.text(MoodShareCard.ctaText), findsOneWidget);
      expect(find.text('getmoodtune.com'), findsOneWidget);
      expect(find.byType(AnimatedWidget), findsNothing);
    });

    testWidgets('omits the track line without a title (no empty row)', (
      tester,
    ) async {
      await pumpCard(
        tester,
        testShareContent(title: null, artist: 'Nobody', descriptors: const []),
      );

      expect(find.textContaining('Nobody'), findsNothing);
      expect(find.textContaining(' · '), findsNothing);
      expect(find.text('Charged.'), findsOneWidget);
    });

    testWidgets('shows the title alone without an artist', (tester) async {
      await pumpCard(tester, testShareContent(artist: null));

      expect(find.text('Blinding Lights'), findsOneWidget);
    });

    testWidgets('ellipsizes a long title to one line', (tester) async {
      await pumpCard(
        tester,
        testShareContent(
          title: 'A Very Long Song Title That Keeps Going And Going Forever',
          artist: 'An Artist With An Equally Long Name',
        ),
      );

      final text = tester.widget<Text>(
        find.textContaining('A Very Long Song Title'),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });

    testWidgets('caps descriptors at three', (tester) async {
      await pumpCard(
        tester,
        testShareContent(descriptors: const ['a', 'b', 'c', 'd']),
      );

      expect(find.text('a · b · c'), findsOneWidget);
    });

    test('mood words and accents cover every identity', () {
      expect(MoodShareCard.moodWord(MoodIdentity.upbeat), 'Upbeat.');
      expect(MoodShareCard.moodWord(MoodIdentity.reflective), 'Reflective.');
      expect(
        MoodIdentity.values.map(MoodShareCard.accentFor).toSet(),
        hasLength(4),
      );
    });
  });

  group('MoodShareCardRenderer', () {
    // Rasterizing needs the real engine, so it runs outside fake async.
    testWidgets('renders a 1080×1350 PNG (R3, AC2)', (tester) async {
      final image = await tester.runAsync(
        () => const MoodShareCardRenderer().render(testShareContent()),
      );

      expect(image!.width, 1080);
      expect(image.height, 1350);
      final decoded = await tester.runAsync(
        () => decodeImageFromList(image.pngBytes),
      );
      expect(decoded!.width, 1080);
      expect(decoded.height, 1350);
      decoded.dispose();
    });

    testWidgets('renders a history card with no descriptors', (tester) async {
      final image = await tester.runAsync(
        () => const MoodShareCardRenderer().render(
          testShareContent(descriptors: const [], mood: MoodIdentity.upbeat),
        ),
      );

      expect(image!.pngBytes, isNotEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
