import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/analysis/data/models/models.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/presentation/engine_comparison.dart';
import 'package:shared_preferences/shared_preferences.dart';

HistoryEntry _entry({
  String backend = 'happy',
  String? onDevice = 'calm',
  MoodSource shown = MoodSource.onDevice,
  bool? agrees,
  String? userMood,
  bool withComparison = true,
}) => HistoryEntry(
  id: 'e',
  title: 't',
  primaryMood: shown == MoodSource.onDevice ? onDevice ?? backend : backend,
  confidence: null,
  createdAt: DateTime.utc(2026),
  type: HistoryEntryType.song,
  comparison: withComparison
      ? EngineComparison(
          backendMood: backend,
          onDeviceMood: onDevice,
          displayedSource: shown,
          agrees: agrees,
          userMood: userMood,
        )
      : null,
);

void main() {
  group('EngineComparisonSummary', () {
    test('compares engines at the display-bucket level', () {
      final summary = EngineComparisonSummary.from([
        // happy and energetic are both UPBEAT: counts as agreement
        _entry(backend: 'happy', onDevice: 'energetic'),
        _entry(backend: 'happy', onDevice: 'calm'),
        // on-device didn't run: not compared
        _entry(onDevice: null, shown: MoodSource.backend),
        // older row without both moods: not compared
        _entry(withComparison: false),
      ]);

      expect(summary.compared, 2);
      expect(summary.enginesAgreed, 1);
      expect(summary.judged, 0);
    });

    test('grades each engine against the user answer', () {
      final summary = EngineComparisonSummary.from([
        // 👍 on the on-device mood: on-device right, backend wrong
        _entry(agrees: true),
        // 👎 on on-device, user picked UPBEAT: backend (happy) right
        _entry(agrees: false, userMood: 'upbeat'),
        // 👍 on the backend mood shown
        _entry(shown: MoodSource.backend, agrees: true),
        // 👎 without a pick: can't tell which is right
        _entry(agrees: false),
        // unanswered
        _entry(),
      ]);

      expect(summary.compared, 5);
      expect(summary.judged, 3);
      expect(summary.onDeviceRight, 1);
      expect(summary.backendRight, 2);
    });

    test('userBucket follows the engine that was shown', () {
      expect(
        EngineComparisonSummary.userBucket(
          _entry(shown: MoodSource.backend, agrees: true).comparison!,
        ),
        MoodIdentity.upbeat,
      );
      expect(
        EngineComparisonSummary.userBucket(_entry(agrees: true).comparison!),
        MoodIdentity.serene,
      );
    });
  });

  group('EngineComparisonPreference', () {
    test('is off until turned on, and remembers it', () async {
      SharedPreferences.setMockInitialValues({});
      final preference = EngineComparisonPreference();
      await preference.load();
      expect(preference.enabled.value, isFalse);

      await preference.setEnabled(value: true);
      final reloaded = EngineComparisonPreference();
      await reloaded.load();

      expect(reloaded.enabled.value, isTrue);
    });

    // #49 AC5
    test('clear removes the stored value and turns it off', () async {
      SharedPreferences.setMockInitialValues({
        'history.showEngineComparison': true,
      });
      final preference = EngineComparisonPreference();
      await preference.load();
      expect(preference.enabled.value, isTrue);

      await preference.clear();

      expect(preference.enabled.value, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('history.showEngineComparison'), isFalse);
    });

    test('clear survives unavailable storage', () async {
      final preference = EngineComparisonPreference(
        prefs: () => Future.error(Exception('no storage')),
      );
      await preference.clear();
      expect(preference.enabled.value, isFalse);
    });
  });

  group('EngineComparisonPreference load race', () {
    test('a tap during a pending load wins over the stored value', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Like the first SharedPreferences.getInstance(): one pending future
      // that both the load and the tap wait on. The load resumes first and
      // reads the old stored value (false) before the tap's write lands.
      final firstRead = Completer<SharedPreferences>();
      final preference = EngineComparisonPreference(
        prefs: () => firstRead.future,
      );

      final loading = preference.load();
      final tapping = preference.setEnabled(value: true);
      firstRead.complete(prefs);
      await Future.wait([loading, tapping]);

      expect(preference.enabled.value, isTrue);
      expect(prefs.getBool('history.showEngineComparison'), isTrue);
    });
  });

  group('ResultHistoryRecord.toJson', () {
    test('matches the POST /song/history body', () {
      const record = ResultHistoryRecord(
        source: ResultHistorySource.catalog,
        title: 'Planet 21',
        artist: 'Someone',
        trackId: 'j1',
        displayedMood: 'calm',
        displayedSource: MoodSource.onDevice,
        backendMood: 'happy',
        onDeviceMood: 'calm',
        observationId: 'o-1',
      );

      expect(record.toJson(), {
        'source': 'catalog',
        'title': 'Planet 21',
        'artist': 'Someone',
        'track_id': 'j1',
        'displayed_mood': 'calm',
        'displayed_source': 'on_device',
        'backend_mood': 'happy',
        'on_device_mood': 'calm',
        'confidence': null,
        'observation_id': 'o-1',
        'title_from_filename': false,
      });
    });

    test('sends title_from_filename for a title made from the filename', () {
      const record = ResultHistoryRecord(
        source: ResultHistorySource.upload,
        title: 'Summer Vibes',
        titleFromFilename: true,
        displayedMood: 'happy',
        displayedSource: MoodSource.backend,
        backendMood: 'happy',
      );

      expect(record.toJson()['title_from_filename'], isTrue);
    });
  });
}
