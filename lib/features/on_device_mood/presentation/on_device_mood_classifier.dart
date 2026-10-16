import 'dart:async';

import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/on_device_mood/domain/decoded_audio.dart';
import 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';
import 'package:moodtune_app/features/on_device_mood/domain/yamnet_mood_model.dart';

export 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';

/// Classifies a local audio file's mood and sound tags on the device:
/// decode three windows natively, run YAMNet, interpret the scores.
///
/// Any failure (no native decoder, unreadable file, model error, timeout)
/// returns null, so callers keep the backend's result and never depend on
/// the on-device path.
class OnDeviceMoodClassifier {
  OnDeviceMoodClassifier({
    required AudioWindowDecoder decoder,
    required AudioClassifierEngine engine,
    required Future<YamnetMoodModel> Function() loadModel,
    this.timeout = const Duration(seconds: 5),
  }) : _decoder = decoder,
       _engine = engine,
       _loadModel = loadModel;

  final AudioWindowDecoder _decoder;
  final AudioClassifierEngine _engine;
  final Future<YamnetMoodModel> Function() _loadModel;

  /// Deadline for the whole attempt. Work already running isn't cancelled;
  /// the caller just stops waiting for it.
  final Duration timeout;
  Future<YamnetMoodModel>? _model;

  Future<OnDeviceMood?> classify(String path) async {
    try {
      return await _classify(path).timeout(timeout);
    } on TimeoutException {
      talker.warning(
        'On-device mood timed out after ${timeout.inMilliseconds}ms; '
        'keeping backend mood',
      );
      return null;
    } on Object catch (error) {
      talker.warning('On-device mood failed ($error); keeping backend mood');
      return null;
    }
  }

  Future<OnDeviceMood> _classify(String path) async {
    final stopwatch = Stopwatch()..start();
    final model = await _modelOnce();
    final audio = await _decoder.decodeWindows(path);
    final decodeMs = stopwatch.elapsedMilliseconds;
    final mood = model.interpret(await _engine.score(audio));
    final p = mood.probabilities[mood.primaryMood]!;
    talker.info(
      'On-device mood: ${mood.primaryMood} (p=${p.toStringAsFixed(2)}), '
      'tags ${mood.tags}, ${stopwatch.elapsedMilliseconds}ms '
      '(decode ${decodeMs}ms)',
    );
    return mood;
  }

  Future<YamnetMoodModel> _modelOnce() async {
    final pending = _model ??= _loadModel();
    try {
      return await pending;
    } on Object {
      _model = null; // let the next call retry
      rethrow;
    }
  }
}
