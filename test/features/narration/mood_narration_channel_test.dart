import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/narration/data/mood_narration_channel.dart';
import 'package:moodtune_app/features/narration/domain/mood_narrator.dart';

import 'narration_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('moodtune/narration');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final input = NarrationInput.fromMood(buildAnalysis().mood);

  void reply(Object? Function(MethodCall call) handler) =>
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        return handler(call);
      });

  tearDown(() => messenger.setMockMethodCallHandler(methodChannel, null));

  group('MoodNarrationChannel', () {
    test('returns the text from the native reply', () async {
      reply(
        (_) => {'text': 'This track feels upbeat.', 'instructions': 'full'},
      );

      final text = await MoodNarrationChannel().narrate(input);

      expect(text, 'This track feels upbeat.');
    });

    test('sends the narration input as the call arguments', () async {
      MethodCall? received;
      reply((call) {
        received = call;
        return {'text': 'ok', 'instructions': 'minimal'};
      });

      await MoodNarrationChannel().narrate(input);

      expect(received?.method, 'narrate');
      expect(received?.arguments, input.toMap());
    });

    test('throws when the reply has no text', () async {
      reply((_) => <String, String>{});

      expect(
        () => MoodNarrationChannel().narrate(input),
        throwsA(isA<PlatformException>()),
      );
    });

    test('reports unavailable when no native handler exists', () async {
      expect(await MoodNarrationChannel().isAvailable(), isFalse);
    });
  });
}
