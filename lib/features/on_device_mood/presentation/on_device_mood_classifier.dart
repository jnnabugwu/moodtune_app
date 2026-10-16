import 'dart:async';

import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/on_device_mood/domain/decoded_audio.dart';
import 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';
import 'package:moodtune_app/features/on_device_mood/domain/yamnet_mood_model.dart';

export 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';

/// Classifies a local audio file's mood and sound tags on the device:
/// decode three windows natively, run YAMNet, interpret the scores.
///
/// Any failure (no native decoder, unreadable file, model error, timeout,
/// no mood in the audio) returns null, so callers keep the backend's result
/// and never depend on the on-device path.
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

  /// Deadline for the whole attempt. Native decoding and inference can't be
  /// cancelled, so the caller just stops waiting; until that work finishes,
  /// further attempts return null straight away instead of piling up.
  final Duration timeout;
  Future<YamnetMoodModel>? _model;
  Future<OnDeviceMood?>? _running;

  Future<OnDeviceMood?> classify(String path) async {
    if (_running != null) {
      talker.warning(
        'On-device mood: previous attempt still running; keeping backend mood',
      );
      return null;
    }
    final run = _running = _classify(path).whenComplete(() {
      _running = null;
    });
    try {
      return await run.timeout(timeout);
    } on TimeoutException {
      talker.warning(
        'On-device mood timed out after ${timeout.inMilliseconds}ms; '
        'keeping backend mood',
      );
      return null;
    } on Object catch (error, stackTrace) {
      talker.warning(
        'On-device mood failed ($error); keeping backend mood',
        error,
        stackTrace,
      );
      return null;
    }
  }

  Future<OnDeviceMood?> _classify(String path) async {
    final stopwatch = Stopwatch()..start();
    final model = await _modelOnce();
    final decodeStopwatch = Stopwatch()..start();
    final audio = await _decoder.decodeWindows(path);
    final decodeMs = decodeStopwatch.elapsedMilliseconds;
    final mood = model.interpret(await _engine.score(audio));
    if (mood == null) {
      talker.info(
        'On-device mood: no mood in the audio, ${stopwatch.elapsedMilliseconds}'
        'ms; keeping backend mood',
      );
      return null;
    }
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
