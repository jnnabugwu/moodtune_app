import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_litert/flutter_litert.dart';
import 'package:moodtune_app/features/on_device_mood/domain/decoded_audio.dart';
import 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';

/// [AudioClassifierEngine] running YAMNet with LiteRT (`flutter_litert`).
///
/// The bundled `.tflite` takes 15,600 samples (0.975 s at 16 kHz) and
/// returns 521 class scores, computing its own spectrogram. Each track's
/// frames (~57 for three 10 s windows) run in one background isolate, so
/// inference never blocks the UI. The interpreter is loaded once, lazily,
/// and runs are serialised because one interpreter can't run concurrently.
class YamnetEngine implements AudioClassifierEngine {
  YamnetEngine({this.assetPath = 'assets/models/yamnet.tflite'});

  /// YAMNet's fixed input size and the hop it uses on long clips, as in
  /// `spikes/clap/yamnet.py`.
  static const frameSamples = 15600;
  static const hopSamples = 7680;

  final String assetPath;
  Future<Interpreter>? _interpreter;
  Future<void> _queue = Future.value();

  @override
  Future<ClassScores> score(DecodedAudio audio) {
    final run = _queue.then((_) => _score(audio));
    _queue = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<ClassScores> _score(DecodedAudio audio) async {
    final address = (await _load()).address;
    final windows = audio.windows;
    return await Isolate.run(
      () => _scoreInIsolate(address, windows),
      debugName: 'yamnet',
    );
  }

  Future<Interpreter> _load() async {
    final pending = _interpreter ??= Interpreter.fromAsset(assetPath).then(
      // Allocated here so the worker isolate can use it as-is.
      (interpreter) => interpreter..allocateTensors(),
    );
    try {
      return await pending;
    } on Object {
      _interpreter = null; // let the next call retry
      rethrow;
    }
  }

  /// Mean of each window's mean frame score, and the highest score of any
  /// frame, per class. Pure, so it's testable without the native runtime.
  ///
  /// Frames start every [hopSamples] while a full frame fits; a window
  /// shorter than one frame becomes a single zero-padded frame.
  static ClassScores poolFrames(
    List<Float32List> windows, {
    required Float32List Function(Float32List frame) runFrame,
  }) {
    if (windows.isEmpty) throw ArgumentError('No audio windows');
    Float64List? meanOfWindows;
    Float32List? peak;
    for (final window in windows) {
      Float64List? windowSum;
      var frames = 0;
      final lastStart = math.max(window.length - frameSamples, 0);
      for (var start = 0; start <= lastStart; start += hopSamples) {
        final end = math.min(start + frameSamples, window.length);
        final frame = Float32List(frameSamples)
          ..setRange(0, end - start, window, start);
        final scores = runFrame(frame);
        windowSum ??= Float64List(scores.length);
        peak ??= Float32List(scores.length)..fillRange(0, scores.length, -1);
        for (var c = 0; c < scores.length; c++) {
          windowSum[c] += scores[c];
          if (scores[c] > peak[c]) peak[c] = scores[c];
        }
        frames++;
      }
      meanOfWindows ??= Float64List(windowSum!.length);
      for (var c = 0; c < windowSum!.length; c++) {
        meanOfWindows[c] += windowSum[c] / frames / windows.length;
      }
    }
    return ClassScores(mean: Float32List.fromList(meanOfWindows!), peak: peak!);
  }
}

/// Runs in the worker isolate: rebuilds the interpreter from its address
/// and runs every frame. Top-level, so the closure captures only sendable
/// values.
ClassScores _scoreInIsolate(int address, List<Float32List> windows) {
  final interpreter = Interpreter.fromAddress(address);
  final classes = interpreter.getOutputTensor(0).shape.last;
  return YamnetEngine.poolFrames(
    windows,
    runFrame: (frame) {
      final output = Float32List(classes);
      interpreter.run(frame, output);
      return output;
    },
  );
}
