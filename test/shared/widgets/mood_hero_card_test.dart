import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/shared/widgets/confidence_ring.dart';
import 'package:moodtune_app/shared/widgets/mood_hero_card.dart';

import '../../helpers/helpers.dart';
import '../widget_fixtures.dart';

void main() {
  Widget card({
    String mood = 'happy',
    double confidence = 0.85,
    bool disableAnimations = false,
  }) {
    return Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: SingleChildScrollView(
          child: MoodHeroCard(
            analysis: buildAudioUploadAnalysis(
              primaryMood: mood,
              confidence: confidence,
            ),
          ),
        ),
      ),
    );
  }

  double opacityOf(WidgetTester tester, Finder child) {
    final fade = tester.widget<FadeTransition>(
      find.ancestor(of: child, matching: find.byType(FadeTransition)).first,
    );
    return fade.opacity.value;
  }

  group('MoodHeroCard', () {
    final cases = <String, MoodIdentity>{
      'happy': MoodIdentity.upbeat,
      'calm': MoodIdentity.serene,
      'intense': MoodIdentity.charged,
      'melancholic': MoodIdentity.reflective,
    };

    for (final entry in cases.entries) {
      testWidgets('renders ${entry.value} identity for "${entry.key}"', (
        tester,
      ) async {
        await tester.pumpWidgetInShell(card(mood: entry.key));
        await tester.pumpAndSettle();

        final identity = entry.value;
        final colors = MoodTheme.colorsFor(identity);
        expect(find.text(MoodTheme.shortLabel(identity)), findsOneWidget);
        expect(find.text(MoodTheme.quadrantLabel(identity)), findsOneWidget);
        final icon = tester.widget<Icon>(
          find.byIcon(MoodTheme.iconFor(identity)),
        );
        expect(icon.color, colors.text);

        final gradientBox = tester.widget<Container>(
          find
              .descendant(
                of: find.byType(MoodHeroCard),
                matching: find.byType(Container),
              )
              .first,
        );
        final gradient =
            (gradientBox.decoration! as BoxDecoration).gradient!
                as LinearGradient;
        expect(gradient.colors, [colors.background, colors.backgroundEnd]);

        final ring = tester.widget<ConfidenceRing>(find.byType(ConfidenceRing));
        expect(ring.value, 0.85);
        expect(ring.color, colors.text);
        expect(find.text('85%'), findsOneWidget);
      });
    }

    testWidgets('staggers fade-in of elements over 700ms', (tester) async {
      await tester.pumpWidgetInShell(card());

      final label = find.text('UPBEAT');
      final quadrant = find.text('Happy & Energetic');

      // First frame: nothing visible yet.
      expect(opacityOf(tester, label), 0);
      // Kick off the ticker started by the post-frame callback.
      await tester.pump();

      // ~T+350ms: label is mid-fade, quadrant not started.
      await tester.pump(const Duration(milliseconds: 350));
      final labelMid = opacityOf(tester, label);
      expect(labelMid, greaterThan(0));
      expect(labelMid, lessThan(1));
      expect(opacityOf(tester, quadrant), 0);

      // Label is still slid down while fading in.
      final translate = tester.widget<Transform>(
        find.ancestor(of: label, matching: find.byType(Transform)).first,
      );
      expect(translate.transform.getTranslation().y, greaterThan(0));

      await tester.pumpAndSettle();
      expect(opacityOf(tester, label), 1);
      expect(opacityOf(tester, quadrant), 1);
      final settled = tester.widget<Transform>(
        find.ancestor(of: label, matching: find.byType(Transform)).first,
      );
      expect(settled.transform.getTranslation().y, 0);
    });

    testWidgets('shows everything instantly when animations disabled', (
      tester,
    ) async {
      await tester.pumpWidgetInShell(card(disableAnimations: true));
      // The post-frame callback jumps the controller to the end.
      await tester.pump();

      expect(opacityOf(tester, find.text('UPBEAT')), 1);
      expect(opacityOf(tester, find.text('Happy & Energetic')), 1);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('Strong match'), findsOneWidget);
    });
  });

  testWidgets('hides the confidence ring for on-device moods', (tester) async {
    final backend = buildAudioUploadAnalysis();
    final onDevice = backend.copyWith(
      mood: backend.mood.copyWith(source: MoodSource.onDevice),
    );

    await tester.pumpWidgetInShell(
      SingleChildScrollView(child: MoodHeroCard(analysis: onDevice)),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ConfidenceRing), findsNothing);
    expect(find.text('85%'), findsNothing);
    expect(find.text('UPBEAT'), findsOneWidget);
  });
}
