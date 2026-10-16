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

/// The outcome of one on-device classification, kept for comparison with
/// the backend (ROADMAP OD-4) whether or not it succeeded.
class OnDeviceMoodAttempt extends Equatable {
  const OnDeviceMoodAttempt({required this.elapsed, this.mood, this.failure});

  /// Null when the attempt failed or was skipped.
  final OnDeviceMood? mood;

  /// Time spent classifying (decode + model), excluding any download.
  final Duration elapsed;

  /// Why there's no [mood], as a fixed category so no file path or URL is
  /// recorded:
  ///
  /// * `disabled`: the remote kill switch is off.
  /// * `unsupported`: no native decoder on this platform (Android).
  /// * `download: <reason>`: fetching a catalog track failed, e.g.
  ///   `download: receiveTimeout`.
  /// * `timeout`: classification ran past its deadline.
  /// * `late`: the backend answered and the grace period ran out first.
  /// * `decode: <code>`: the native decoder's error code, e.g.
  ///   `decode: unreadable`.
  /// * `classification_failed`: anything else (model load or inference).
  final String? failure;

  @override
  List<Object?> get props => [mood, elapsed, failure];
}

/// Fetches a remote track to a local file the native decoder can open.
abstract interface class AudioDownloader {
  /// Returns the downloaded file's path. The file must sit alone in a new
  /// temp directory: callers delete that whole directory when done.
  Future<String> download(String url);
}
