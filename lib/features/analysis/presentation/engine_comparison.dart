import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether History shows both engines' moods. Off by default so testers see
/// a plain history; stored on the device.
class EngineComparisonPreference {
  EngineComparisonPreference({Future<SharedPreferences> Function()? prefs})
    : _prefs = prefs ?? SharedPreferences.getInstance;

  static const _key = 'history.showEngineComparison';

  final Future<SharedPreferences> Function() _prefs;

  /// Current value; listen to rebuild when it changes.
  final ValueNotifier<bool> enabled = ValueNotifier(false);

  /// Bumped by [setEnabled], so a load that started before a tap doesn't
  /// overwrite it when the stored value arrives.
  int _changes = 0;

  Future<void> load() async {
    final changesAtStart = _changes;
    try {
      final stored = (await _prefs()).getBool(_key) ?? false;
      if (_changes == changesAtStart) enabled.value = stored;
    } on Object catch (e) {
      talker.warning('Engine comparison setting unavailable: $e');
    }
  }

  Future<void> setEnabled({required bool value}) async {
    _changes++;
    enabled.value = value;
    try {
      await (await _prefs()).setBool(_key, value);
    } on Object catch (e) {
      talker.warning('Engine comparison setting not saved: $e');
    }
  }
}

/// How the backend and on-device engines did across a user's history,
/// compared at the level of the 4 display buckets (what users see and pick).
class EngineComparisonSummary extends Equatable {
  const EngineComparisonSummary({
    required this.compared,
    required this.enginesAgreed,
    required this.judged,
    required this.onDeviceRight,
    required this.backendRight,
  });

  factory EngineComparisonSummary.from(List<HistoryEntry> entries) {
    var compared = 0;
    var enginesAgreed = 0;
    var judged = 0;
    var onDeviceRight = 0;
    var backendRight = 0;
    for (final entry in entries) {
      final comparison = entry.comparison;
      final onDevice = comparison?.onDeviceMood;
      if (comparison == null || onDevice == null) continue;
      compared++;
      final backendBucket = MoodTheme.fromString(comparison.backendMood);
      final onDeviceBucket = MoodTheme.fromString(onDevice);
      if (backendBucket == onDeviceBucket) enginesAgreed++;

      final truth = userBucket(comparison);
      if (truth == null) continue;
      judged++;
      if (onDeviceBucket == truth) onDeviceRight++;
      if (backendBucket == truth) backendRight++;
    }
    return EngineComparisonSummary(
      compared: compared,
      enginesAgreed: enginesAgreed,
      judged: judged,
      onDeviceRight: onDeviceRight,
      backendRight: backendRight,
    );
  }

  /// The bucket the user says fits: the shown mood on a thumbs-up, or the
  /// one they picked on a thumbs-down. Null if unanswered or no pick.
  static MoodIdentity? userBucket(EngineComparison comparison) {
    final shown = comparison.displayedSource == MoodSource.onDevice
        ? comparison.onDeviceMood
        : comparison.backendMood;
    return switch (comparison.agrees) {
      true when shown != null => MoodTheme.fromString(shown),
      false when comparison.userMood != null => MoodTheme.fromString(
        comparison.userMood!,
      ),
      _ => null,
    };
  }

  /// Results where both engines produced a mood.
  final int compared;

  /// Of [compared], how many landed in the same bucket.
  final int enginesAgreed;

  /// Of [compared], how many have an answer that names the right bucket.
  final int judged;
  final int onDeviceRight;
  final int backendRight;

  @override
  List<Object?> get props => [
    compared,
    enginesAgreed,
    judged,
    onDeviceRight,
    backendRight,
  ];
}
