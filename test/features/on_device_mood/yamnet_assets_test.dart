import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('YAMNet assets', () {
    test('the mood config is bundled and parses', () async {
      final model = await loadYamnetMoodModel();

      expect(model.moodClasses.map((c) => c.label), {
        'happy',
        'energetic',
        'calm',
        'angry',
        'sad',
      });
    });

    test('the model file is bundled', () async {
      final bytes = await rootBundle.load('assets/models/yamnet.tflite');

      expect(bytes.lengthInBytes, greaterThan(4000000));
    });

    test('registers the Apache 2.0 notice', () async {
      registerYamnetLicense();

      final entries = await LicenseRegistry.licenses.toList();
      final yamnet = entries.where((e) => e.packages.contains('YAMNet'));
      expect(yamnet, isNotEmpty);
      final text = yamnet.first.paragraphs.map((p) => p.text).join('\n');
      expect(text, contains('Apache License'));
    });
  });
}
