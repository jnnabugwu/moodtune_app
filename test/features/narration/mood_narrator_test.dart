import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/narration/domain/mood_narrator.dart';

import 'narration_fixtures.dart';

const _good =
    'This track feels upbeat: a fast 128 BPM pulse, high energy and a '
    'bright, layered sound.';

void main() {
  group('MoodNarrator', () {
    test('uses on-device narration when available and grounded', () async {
      final narrator = MoodNarrator(engine: FakeNarrationEngine(output: _good));

      final result = await narrator.narrate(buildAnalysis());

      expect(result.source, NarrationSource.onDevice);
      expect(result.text, _good);
    });

    test('falls back to template when the model is unavailable', () async {
      final engine = FakeNarrationEngine(available: false, output: _good);
      final narrator = MoodNarrator(engine: engine);

      final result = await narrator.narrate(buildAnalysis());

      expect(
        result,
        const MoodNarration(
          text: templateReasoning,
          source: NarrationSource.template,
        ),
      );
      expect(engine.narrateCalls, 0);
    });

    test('falls back to template when the model throws', () async {
      final narrator = MoodNarrator(
        engine: FakeNarrationEngine(error: Exception('generation failed')),
      );

      final result = await narrator.narrate(buildAnalysis());

      expect(result.source, NarrationSource.template);
    });

    test('falls back to template when the model times out', () async {
      final narrator = MoodNarrator(
        engine: FakeNarrationEngine(
          output: _good,
          delay: const Duration(milliseconds: 50),
        ),
        timeout: const Duration(milliseconds: 10),
      );

      final result = await narrator.narrate(buildAnalysis());

      expect(result.source, NarrationSource.template);
    });

    test('applies one deadline across availability and generation', () async {
      final narrator = MoodNarrator(
        engine: FakeNarrationEngine(
          output: _good,
          availabilityDelay: const Duration(milliseconds: 30),
          delay: const Duration(milliseconds: 30),
        ),
        timeout: const Duration(milliseconds: 45),
      );

      final result = await narrator.narrate(buildAnalysis());

      expect(result.source, NarrationSource.template);
    });

    test('passes the remaining budget to the engine', () async {
      final engine = FakeNarrationEngine(
        output: _good,
        availabilityDelay: const Duration(milliseconds: 20),
      );
      final narrator = MoodNarrator(
        engine: engine,
        timeout: const Duration(seconds: 1),
      );

      await narrator.narrate(buildAnalysis());

      expect(engine.lastTimeout, isNotNull);
      expect(
        engine.lastTimeout,
        lessThanOrEqualTo(const Duration(milliseconds: 980)),
      );
      expect(engine.lastTimeout, greaterThan(Duration.zero));
    });

    test('skips generation when availability uses the whole budget', () async {
      final engine = FakeNarrationEngine(
        output: _good,
        availabilityDelay: const Duration(milliseconds: 30),
      );
      final narrator = MoodNarrator(
        engine: engine,
        timeout: const Duration(milliseconds: 10),
      );

      final result = await narrator.narrate(buildAnalysis());

      expect(result.source, NarrationSource.template);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(engine.narrateCalls, 0);
    });

    test('falls back to template when output is not grounded', () async {
      final narrator = MoodNarrator(
        engine: FakeNarrationEngine(
          output: 'A haunting ballad about lost love.',
        ),
      );

      final result = await narrator.narrate(buildAnalysis());

      expect(result.source, NarrationSource.template);
    });

    test('caches on-device narration per analysis id', () async {
      final engine = FakeNarrationEngine(output: _good);
      final narrator = MoodNarrator(engine: engine);

      await narrator.narrate(buildAnalysis());
      await narrator.narrate(buildAnalysis());

      expect(engine.narrateCalls, 1);
    });
  });

  group('NarrationInput', () {
    test('uses the on-screen mood name, not the backend label', () {
      final input = NarrationInput.fromMood(
        buildAnalysis(primaryMood: 'calm').mood,
      );

      expect(input.mood, 'serene');
      expect(input.moodSummary, 'calm and positive');
    });

    test('pre-phrases sound facts so the model cannot echo raw labels', () {
      final input = NarrationInput.fromMood(buildAnalysis().mood);

      expect(input.tempo, 128);
      expect(input.tempoFeel, 'fast');
      expect(input.energy, 'high energy');
      expect(input.tone, 'a bright tone');
      expect(input.texture, 'a dense sound');
    });

    test('sends no confidence score to the model', () {
      final map = NarrationInput.fromMood(buildAnalysis().mood).toMap();

      expect(map.keys, isNot(contains('confidence')));
    });
  });

  group('isGrounded', () {
    final input = NarrationInput.fromMood(buildAnalysis().mood);

    test('rejects text that is too short or too long', () {
      expect(MoodNarrator.isGrounded('energetic', input), isFalse);
      expect(MoodNarrator.isGrounded('energetic ' * 50, input), isFalse);
    });

    test('rejects links', () {
      expect(
        MoodNarrator.isGrounded('Energetic track, see https://x.co', input),
        isFalse,
      );
    });

    test('rejects topics the model has no facts about', () {
      for (final text in [
        'An energetic track with lyrics about summer.',
        'Energetic, like most songs in the genre.',
        'The artist keeps it energetic throughout.',
        'Energetic, driven by powerful vocals.',
      ]) {
        expect(MoodNarrator.isGrounded(text, input), isFalse, reason: text);
      }
    });

    test('accepts text that names a descriptor instead of the mood', () {
      expect(
        MoodNarrator.isGrounded('A danceable track with a fast pulse.', input),
        isTrue,
      );
    });
  });
}
