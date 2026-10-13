import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/narration/presentation/mood_narration_text.dart';
import 'package:moodtune_app/features/narration/presentation/mood_narrator.dart';

import 'narration_fixtures.dart';

const _good =
    'This track feels upbeat: a fast 128 BPM pulse, high energy and a '
    'bright, layered sound.';

Widget _wrap(AudioUploadAnalysis analysis, MoodNarrator narrator) =>
    CupertinoApp(
      home: MoodNarrationText(
        analysis: analysis,
        narrator: narrator,
        style: const TextStyle(),
      ),
    );

void main() {
  group('MoodNarrationText', () {
    testWidgets('swaps in on-device narration with its caption', (
      tester,
    ) async {
      final narrator = MoodNarrator(
        engine: FakeNarrationEngine(output: _good),
      );

      await tester.pumpWidget(_wrap(buildAnalysis(), narrator));
      expect(find.text(templateReasoning), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text(_good), findsOneWidget);
      expect(
        find.text('Written on-device by Apple Intelligence'),
        findsOneWidget,
      );
    });

    testWidgets('shows on-device narration when the template is empty', (
      tester,
    ) async {
      final narrator = MoodNarrator(
        engine: FakeNarrationEngine(output: _good),
      );

      await tester.pumpWidget(_wrap(buildAnalysis(reasoning: ''), narrator));
      expect(find.byType(Text), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text(_good), findsOneWidget);
    });

    testWidgets('renders nothing, not even padding, without any text', (
      tester,
    ) async {
      final narrator = MoodNarrator(
        engine: FakeNarrationEngine(available: false),
      );

      await tester.pumpWidget(
        CupertinoApp(
          home: MoodNarrationText(
            analysis: buildAnalysis(reasoning: ''),
            narrator: narrator,
            style: const TextStyle(),
            padding: const EdgeInsets.all(16),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Text), findsNothing);
      expect(find.byType(Padding), findsNothing);
    });

    testWidgets('resets when a different analysis is shown in place', (
      tester,
    ) async {
      final narrator = MoodNarrator(
        engine: FakeNarrationEngine(available: false),
      );

      await tester.pumpWidget(
        _wrap(buildAnalysis(reasoning: 'First song.'), narrator),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        _wrap(buildAnalysis(id: 'a2', reasoning: 'Second song.'), narrator),
      );
      await tester.pumpAndSettle();

      expect(find.text('Second song.'), findsOneWidget);
      expect(find.text('First song.'), findsNothing);
    });
  });
}
