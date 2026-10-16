import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/mood_feedback/data/models/app_config_model.dart';
import 'package:moodtune_app/features/mood_feedback/data/models/mood_observation_model.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/entities.dart';

import '../../mood_feedback_fixtures.dart';

void main() {
  group('MoodObservationJson', () {
    test('serializes every field with backend snake_case names', () {
      final json = sampleObservation().withDeviceDetails(sampleDevice).toJson();

      expect(json, {
        'id': observationId,
        'source': 'upload',
        'analysis_id': 'an-1',
        'backend_mood': 'happy',
        'on_device_mood': 'calm',
        'on_device_tags': ['vocals', 'piano'],
        'on_device_probabilities': {'happy': 0.2, 'calm': 0.8},
        'on_device_latency_ms': 840,
        'on_device_error': null,
        'displayed_mood': 'calm',
        'displayed_source': 'on_device',
        'platform': 'ios',
        'os_version': '18.1',
        'device_model': 'iPhone15,2',
        'app_version': '1.0.0+7',
      });
    });

    test('wire values match the backend enums', () {
      expect(MoodObservationSource.upload.wireValue, 'upload');
      expect(MoodObservationSource.catalog.wireValue, 'catalog');
      expect(DisplayedMoodSource.onDevice.wireValue, 'on_device');
      expect(DisplayedMoodSource.backend.wireValue, 'backend');
    });
  });

  group('AppConfigModel', () {
    test('parses on_device_mood', () {
      expect(
        AppConfigModel.fromJson({'on_device_mood': false}).toDomain(),
        const AppConfig(onDeviceMood: false),
      );
      expect(
        AppConfigModel.fromJson({'on_device_mood': true}).toDomain(),
        AppConfig.fallback,
      );
    });

    test('throws FormatException when the flag is missing or not a bool', () {
      expect(
        () => AppConfigModel.fromJson(<String, dynamic>{}),
        throwsFormatException,
      );
      expect(
        () => AppConfigModel.fromJson({'on_device_mood': 'false'}),
        throwsFormatException,
      );
    });
  });
}
