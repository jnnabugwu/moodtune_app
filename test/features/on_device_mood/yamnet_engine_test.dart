import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_engine.dart';

void main() {
  group('YamnetEngine.poolFrames', () {
    const frame = YamnetEngine.frameSamples;
    const hop = YamnetEngine.hopSamples;

    /// A fake model: class 0 scores the frame's first sample, class 1 its
    /// last, so tests can see exactly which samples each frame held.
    Float32List firstAndLast(Float32List f) =>
        Float32List.fromList([f.first, f.last]);

    Float32List ramp(int length) =>
        Float32List.fromList([for (var i = 0; i < length; i++) i.toDouble()]);

    test('cuts a 10 s window into 19 frames, like the spike', () {
      final starts = <double>[];
      YamnetEngine.poolFrames(
        [ramp(160000)],
        runFrame: (f) {
          starts.add(f.first);
          return firstAndLast(f);
        },
      );

      expect(starts, hasLength(19));
      expect(starts.first, 0);
      expect(starts[1], hop.toDouble());
      expect(starts.last, (18 * hop).toDouble());
    });

    test('zero-pads a window shorter than one frame', () {
      final scores = YamnetEngine.poolFrames([
        ramp(1000),
      ], runFrame: firstAndLast);

      expect(scores.mean[0], 0); // first sample
      expect(scores.mean[1], 0); // padded tail
    });

    test('averages each window, then averages the windows', () {
      // Window A: one frame scoring 1; window B: two frames scoring 3 and 5.
      final a = Float32List(frame)..fillRange(0, frame, 1);
      final b = Float32List(frame + hop)
        ..fillRange(0, hop, 3)
        ..fillRange(hop, frame + hop, 5);

      final scores = YamnetEngine.poolFrames([
        a,
        b,
      ], runFrame: (f) => Float32List.fromList([f.first]));

      // Mean of window means (1 and 4), not of all three frames (3).
      expect(scores.mean[0], closeTo(2.5, 1e-6));
      expect(scores.peak[0], 5);
    });

    test('keeps the highest frame score as the peak', () {
      final scores = YamnetEngine.poolFrames([
        ramp(frame + 2 * hop),
      ], runFrame: firstAndLast);

      expect(scores.peak[0], (2 * hop).toDouble());
      expect(scores.peak[1], (frame + 2 * hop - 1).toDouble());
    });

    test('rejects audio with no windows', () {
      expect(
        () => YamnetEngine.poolFrames([], runFrame: firstAndLast),
        throwsArgumentError,
      );
    });
  });
}
