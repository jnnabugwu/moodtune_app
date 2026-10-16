import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/entities.dart';

import '../mood_feedback_fixtures.dart';

void main() {
  group('MoodObservation', () {
    final uuidV4 = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );

    test('newId returns distinct v4 UUIDs', () {
      final ids = {for (var i = 0; i < 50; i++) MoodObservation.newId()};

      expect(ids, hasLength(50));
      expect(ids.every(uuidV4.hasMatch), isTrue);
    });

    test('newId is deterministic for a seeded Random', () {
      expect(
        MoodObservation.newId(Random(1)),
        MoodObservation.newId(Random(1)),
      );
      expect(uuidV4.hasMatch(MoodObservation.newId(Random(1))), isTrue);
    });

    test('defaults onDeviceTags to empty', () {
      const obs = MoodObservation(
        id: 'x',
        source: MoodObservationSource.catalog,
        backendMood: 'sad',
        displayedMood: 'sad',
        displayedSource: DisplayedMoodSource.backend,
      );

      expect(obs.onDeviceTags, isEmpty);
      expect(obs.onDeviceMood, isNull);
    });

    test('withDeviceDetails fills only null device fields', () {
      final filled = sampleObservation(
        osVersion: '17.0',
      ).withDeviceDetails(sampleDevice);

      expect(filled.platform, 'ios');
      expect(filled.osVersion, '17.0');
      expect(filled.deviceModel, 'iPhone15,2');
      expect(filled.appVersion, '1.0.0+7');
      expect(
        filled,
        sampleObservation(
          platform: 'ios',
          osVersion: '17.0',
          deviceModel: 'iPhone15,2',
          appVersion: '1.0.0+7',
        ),
      );
    });

    test('supports value equality', () {
      expect(sampleObservation(), sampleObservation());
      expect(sampleObservation(), isNot(sampleObservation(platform: 'ios')));
    });
  });

  group('AppConfig', () {
    test('fallback keeps on-device mood on', () {
      expect(AppConfig.fallback.onDeviceMood, isTrue);
    });

    test('supports value equality', () {
      expect(
        const AppConfig(onDeviceMood: false),
        const AppConfig(onDeviceMood: false),
      );
      expect(AppConfig.fallback, isNot(const AppConfig(onDeviceMood: false)));
    });
  });

  test('DeviceDetails supports value equality', () {
    expect(
      sampleDevice,
      const DeviceDetails(
        platform: 'ios',
        osVersion: '18.1',
        deviceModel: 'iPhone15,2',
        appVersion: '1.0.0+7',
      ),
    );
    expect(const DeviceDetails(), isNot(sampleDevice));
  });
}
