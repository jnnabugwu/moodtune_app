import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_assets.dart';

/// Serves an edited copy of the shipped mood config.
class _ConfigBundle extends CachingAssetBundle {
  _ConfigBundle(void Function(Map<String, Object?> config) edit)
    : _config =
          jsonDecode(File(yamnetMoodConfigAsset).readAsStringSync())
              as Map<String, Object?> {
    edit(_config);
  }

  final Map<String, Object?> _config;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(utf8.encode(jsonEncode(_config)));
}

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

    test('rejects a config of another version', () {
      expect(
        loadYamnetMoodModel(bundle: _ConfigBundle((c) => c['version'] = 2)),
        throwsFormatException,
      );
    });

    test("rejects a config exported for other framing than the engine's", () {
      expect(
        loadYamnetMoodModel(
          bundle: _ConfigBundle(
            (c) => (c['input']! as Map<String, Object?>)['hopSamples'] = 8000,
          ),
        ),
        throwsFormatException,
      );
      expect(
        loadYamnetMoodModel(bundle: _ConfigBundle((c) => c.remove('input'))),
        throwsFormatException,
      );
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
