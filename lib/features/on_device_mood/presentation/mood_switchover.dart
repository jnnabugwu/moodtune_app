import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/on_device_mood_classifier.dart';

export 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';

/// Shown under the hero card when on-device narration isn't available. The
/// backend's reasoning describes its own heuristic, which no longer applies.
const onDeviceReasoning =
    'Based on how the song sounds, analyzed on your device.';

/// Makes the on-device mood the one users see (ROADMAP OD-5).
///
/// Classification runs alongside the backend call; [apply] then swaps the
/// on-device mood into the backend's result. Everything degrades to the
/// backend's mood: the remote kill switch being off, no native decoder
/// (Android), a failed download, or a failed classification.
class MoodSwitchover {
  MoodSwitchover({
    required OnDeviceMoodClassifier classifier,
    required AudioDownloader downloader,
    required Future<bool> Function() isEnabled,
    this.isSupported = true,
  }) : _classifier = classifier,
       _downloader = downloader,
       _isEnabled = isEnabled;

  final OnDeviceMoodClassifier _classifier;
  final AudioDownloader _downloader;
  final Future<bool> Function() _isEnabled;

  /// False where there's no native decoder (Android), so nothing is
  /// downloaded or loaded only to fail at the decode step.
  final bool isSupported;

  /// Classifies a file already on the phone (an upload).
  Future<OnDeviceMoodAttempt> classifyFile(String path) async {
    if (!isSupported) return _unsupported;
    if (!await _enabled()) return _disabled;
    return await _classifier.attempt(path);
  }

  /// Downloads a catalog track, classifies it, and deletes the download.
  Future<OnDeviceMoodAttempt> classifyUrl(String url) async {
    if (!isSupported) return _unsupported;
    if (!await _enabled()) return _disabled;
    final String path;
    try {
      path = await _downloader.download(url);
    } on Object catch (error) {
      talker.warning('On-device mood: download failed ($error)');
      return OnDeviceMoodAttempt(
        elapsed: Duration.zero,
        failure: 'download: ${_downloadReason(error)}',
      );
    }
    try {
      return await _classifier.attempt(path);
    } on Object catch (error) {
      // attempt() shouldn't throw, but a catalog result must never fail
      // because of the on-device path.
      talker.warning('On-device mood: classification threw ($error)');
      return const OnDeviceMoodAttempt(
        elapsed: Duration.zero,
        failure: 'classification_failed',
      );
    } finally {
      final dir = File(path).parent;
      await dir.delete(recursive: true).catchError((_) => dir);
    }
  }

  /// The result users see: the backend's analysis with the on-device mood
  /// and sound tags in place of its label and descriptors. Tempo, energy
  /// and the other features stay the backend's. Unchanged when [attempt]
  /// has no mood.
  static AudioUploadAnalysis apply(
    AudioUploadAnalysis analysis,
    OnDeviceMoodAttempt? attempt,
  ) {
    final mood = attempt?.mood;
    if (mood == null) return analysis;
    return analysis.copyWith(
      mood: analysis.mood.copyWith(
        primaryMood: mood.primaryMood,
        reasoning: onDeviceReasoning,
        descriptors: const [],
        soundTags: mood.tags,
        source: MoodSource.onDevice,
        backendPrimaryMood: analysis.mood.primaryMood,
      ),
    );
  }

  /// A failing config check shouldn't block the feature; the config
  /// repository already falls back to "enabled" on network errors.
  Future<bool> _enabled() async {
    try {
      return await _isEnabled();
    } on Object catch (error) {
      talker.warning('On-device mood: switch check failed ($error)');
      return true;
    }
  }

  /// A fixed reason, never the error text: Dio's includes the track URL.
  static String _downloadReason(Object error) =>
      error is DioException ? error.type.name : 'error';

  static const _disabled = OnDeviceMoodAttempt(
    elapsed: Duration.zero,
    failure: 'disabled',
  );

  static const _unsupported = OnDeviceMoodAttempt(
    elapsed: Duration.zero,
    failure: 'unsupported',
  );
}
