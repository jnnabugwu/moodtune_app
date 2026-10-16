import 'dart:async';

import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/entities.dart';
import 'package:moodtune_app/features/mood_feedback/domain/repositories/repositories.dart';
import 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';

/// Records what each result showed (backend mood next to on-device mood)
/// and the user's "Does this feel right?" answer (ROADMAP OD-4).
///
/// Fire-and-forget: nothing here throws or blocks the results screen.
/// Feedback waits for its observation to be stored first, because the
/// backend can't attach feedback to a row that doesn't exist yet.
class MoodObservationRecorder {
  MoodObservationRecorder({required MoodObservationRepository repository})
    : _repository = repository;

  final MoodObservationRepository _repository;
  final Map<String, Future<bool>> _recorded = {};

  /// The backend rejects longer error strings (and the whole row with them).
  static const _maxErrorLength = 500;

  /// Starts recording a result and returns the id to send feedback with.
  ///
  /// [backendMood] is the backend's label; [displayed] is what the user saw.
  String record({
    required MoodObservationSource source,
    required String backendMood,
    required AudioUploadAnalysis displayed,
    OnDeviceMoodAttempt? attempt,
  }) {
    final id = MoodObservation.newId();
    final error = attempt?.failure;
    final observation = MoodObservation(
      id: id,
      source: source,
      analysisId: displayed.id.isEmpty ? null : displayed.id,
      backendMood: backendMood,
      onDeviceMood: attempt?.mood?.primaryMood,
      onDeviceTags: attempt?.mood?.tags ?? const [],
      onDeviceProbabilities: attempt?.mood?.probabilities,
      onDeviceLatencyMs: attempt?.mood == null
          ? null
          : attempt!.elapsed.inMilliseconds,
      onDeviceError: error == null || error.length <= _maxErrorLength
          ? error
          : error.substring(0, _maxErrorLength),
      displayedMood: displayed.mood.primaryMood,
      displayedSource: displayed.mood.source == MoodSource.onDevice
          ? DisplayedMoodSource.onDevice
          : DisplayedMoodSource.backend,
    );
    _recorded[id] = _repository
        .record(observation)
        .then(
          (result) => result.fold((failure) {
            talker.warning('Mood observation not recorded: ${failure.message}');
            return false;
          }, (_) => true),
        );
    return id;
  }

  /// Sends the user's answer once observation [id] is stored. Dropped (and
  /// logged) if it was never recorded.
  Future<void> sendFeedback(
    String id, {
    required bool agrees,
    MoodIdentity? userMood,
  }) async {
    if (!await (_recorded[id] ?? Future.value(false))) {
      talker.warning('Mood feedback dropped: observation $id not recorded');
      return;
    }
    final result = await _repository.sendFeedback(
      id: id,
      agrees: agrees,
      userMood: userMood,
    );
    result.fold(
      (failure) => talker.warning('Mood feedback not sent: ${failure.message}'),
      (_) {},
    );
  }
}
