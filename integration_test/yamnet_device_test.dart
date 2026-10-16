// Runs the real on-device pipeline (native decoder → YAMNet → interpret) on
// a simulator or phone and checks it against the Python spike:
//
//   flutter test integration_test/yamnet_device_test.dart \
//     --flavor development -d <device id>
//
// The input is a synthetic chord generated here with the same formula as
// spikes/clap/04_export_app_assets.py, so no audio file is bundled.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:moodtune_app/features/on_device_mood/data/audio_decode_channel.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_assets.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_engine.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/on_device_mood_classifier.dart';

import 'yamnet_signal_expected.dart';

/// Scores from different decoders and LiteRT builds differ slightly; the
/// macOS parity check saw at most 0.005.
const _meanTolerance = 0.02;
const _peakTolerance = 0.05;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final expected = jsonDecode(yamnetSignalExpectedJson) as Map<String, Object?>;
  final want = expected['expected']! as Map<String, Object?>;
  late Directory dir;
  late String path;

  setUpAll(() async {
    dir = await Directory.systemTemp.createTemp('yamnet');
    path = '${dir.path}/signal.wav';
    await File(
      path,
    ).writeAsBytes(_wav(_signal(expected), _sampleRate(expected)));
  });

  tearDownAll(() => dir.delete(recursive: true));

  testWidgets('decodes the signal into three 10 s windows at 16 kHz', (
    tester,
  ) async {
    final audio = await AudioDecodeChannel().decodeWindows(path);

    expect(audio.windows, hasLength(3));
    expect(audio.windows.every((w) => w.length == 160000), isTrue);
    expect(audio.sourceSampleRate, _sampleRate(expected));
  });

  testWidgets('YAMNet scores match the Python pipeline', (tester) async {
    final audio = await AudioDecodeChannel().decodeWindows(path);
    final engine = YamnetEngine();

    final stopwatch = Stopwatch()..start();
    final scores = await engine.score(audio);
    final firstMs = stopwatch.elapsedMilliseconds;
    stopwatch.reset();
    await engine.score(audio);
    debugPrint(
      'YAMNet: first run ${firstMs}ms (includes model load), '
      'warm run ${stopwatch.elapsedMilliseconds}ms',
    );

    expect(scores.mean, hasLength(521));
    for (final c
        in (expected['classes']! as List).cast<Map<String, Object?>>()) {
      final index = c['index']! as int;
      expect(
        scores.mean[index],
        closeTo(c['mean']! as double, _meanTolerance),
        reason: 'mean ${c['class']}',
      );
      expect(
        scores.peak[index],
        closeTo(c['peak']! as double, _peakTolerance),
        reason: 'peak ${c['class']}',
      );
    }
    expect((await loadYamnetMoodModel()).tags(scores), want['tags']);
  });

  // A chord isn't music YAMNet hears a mood in: every mood class scores 0,
  // so this checks the "no mood" fallback. Mood-class indices and labels
  // are checked on real tracks by test/.../yamnet_mood_model_test.dart.
  testWidgets('the classifier reproduces the Python mood', (tester) async {
    final classifier = OnDeviceMoodClassifier(
      decoder: AudioDecodeChannel(),
      engine: YamnetEngine(),
      loadModel: loadYamnetMoodModel,
    );

    final mood = await classifier.classify(path);

    expect(mood?.primaryMood, want['primaryMood']);
  });

  testWidgets('an unreadable file falls back to null', (tester) async {
    final classifier = OnDeviceMoodClassifier(
      decoder: AudioDecodeChannel(),
      engine: YamnetEngine(),
      loadModel: loadYamnetMoodModel,
    );

    expect(await classifier.classify('${path}_missing.wav'), isNull);
  });
}

int _sampleRate(Map<String, Object?> spec) => spec['sampleRate']! as int;

/// A chord with a 2 Hz pulse, as 16-bit samples. Same formula as
/// `synthetic_signal()` in the export script.
Int16List _signal(Map<String, Object?> spec) {
  final sampleRate = _sampleRate(spec);
  final count = sampleRate * (spec['seconds']! as int);
  final tones = (spec['tones']! as List).cast<Map<String, Object?>>();
  final pulseHz = spec['pulseHz']! as double;
  final scale = spec['scale']! as int;
  final samples = Int16List(count);
  for (var n = 0; n < count; n++) {
    final t = n / sampleRate;
    var chord = 0.0;
    for (final tone in tones) {
      chord +=
          (tone['amplitude']! as double) *
          math.sin(2 * math.pi * (tone['hz']! as double) * t);
    }
    final envelope = 0.6 + 0.4 * math.sin(2 * math.pi * pulseHz * t);
    samples[n] = (chord * envelope * scale).round().clamp(-32768, 32767);
  }
  return samples;
}

/// Mono 16-bit PCM WAV.
Uint8List _wav(Int16List samples, int sampleRate) {
  final data = samples.buffer.asUint8List(
    samples.offsetInBytes,
    samples.lengthInBytes,
  );
  final header = ByteData(44);
  void ascii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      header.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + data.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header
    ..setUint32(16, 16, Endian.little) // fmt chunk size
    ..setUint16(20, 1, Endian.little) // PCM
    ..setUint16(22, 1, Endian.little) // mono
    ..setUint32(24, sampleRate, Endian.little)
    ..setUint32(28, sampleRate * 2, Endian.little) // byte rate
    ..setUint16(32, 2, Endian.little) // block align
    ..setUint16(34, 16, Endian.little); // bits per sample
  ascii(36, 'data');
  header.setUint32(40, data.length, Endian.little);
  return (BytesBuilder()
        ..add(header.buffer.asUint8List())
        ..add(data))
      .takeBytes();
}
