import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:moodtune_app/features/on_device_mood/domain/decoded_audio.dart';

/// Per-class YAMNet scores for one track, pooled two ways over its frames.
class ClassScores {
  const ClassScores({required this.mean, required this.peak});

  /// Mean over frames (mean of each window's mean). Drives the mood, as in
  /// the spike that evaluated it.
  final Float32List mean;

  /// Highest single-frame score. Drives sound tags: averaging dilutes
  /// instruments that only play in part of a song.
  final Float32List peak;
}

/// Runs an audio classifier (YAMNet) over decoded windows.
abstract interface class AudioClassifierEngine {
  Future<ClassScores> score(DecodedAudio audio);
}

/// Mood and sound tags classified on the device.
class OnDeviceMood extends Equatable {
  const OnDeviceMood({
    required this.primaryMood,
    required this.probabilities,
    required this.tags,
  });

  /// One of the backend's labels (`happy`, `energetic`, `calm`, `angry`,
  /// `sad`), so `MoodTheme` maps it exactly like a backend result.
  final String primaryMood;

  /// Softmax over the calibrated mood scores. Overconfident: log it, don't
  /// show it, until it's recalibrated (ROADMAP OD-5).
  final Map<String, double> probabilities;

  /// Display tags such as "vocals" or "piano", strongest first.
  final List<String> tags;

  @override
  List<Object?> get props => [primaryMood, probabilities, tags];
}
