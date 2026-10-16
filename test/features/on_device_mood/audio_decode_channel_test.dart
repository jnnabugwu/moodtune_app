import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/core/error/exceptions.dart';
import 'package:moodtune_app/features/on_device_mood/data/audio_decode_channel.dart';
import 'package:moodtune_app/features/on_device_mood/domain/decoded_audio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const methodChannel = MethodChannel('moodtune/audio_decode');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void reply(Object? Function(MethodCall call) handler) =>
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        return handler(call);
      });

  tearDown(() => messenger.setMockMethodCallHandler(methodChannel, null));

  Map<String, Object?> nativeReply({int windows = 3}) => {
    'windows': [
      for (var i = 0; i < windows; i++) Float32List.fromList([0.1 * i, -0.5]),
    ],
    'startSeconds': [for (var i = 0; i < windows; i++) 10.0 * i],
    'durationSeconds': 274.2,
    'sourceSampleRate': 44100.0,
    'channelCount': 2,
  };

  Matcher throwsDecodeError(String code) => throwsA(
    isA<AudioDecodeException>().having((e) => e.code, 'code', code),
  );

  group('AudioDecodeChannel', () {
    test('parses the native reply into DecodedAudio', () async {
      reply((_) => nativeReply());

      final decoded = await AudioDecodeChannel().decodeWindows('/a.mp3');

      expect(decoded.windows, hasLength(3));
      expect(decoded.windows[1], Float32List.fromList([0.1, -0.5]));
      expect(decoded.startSeconds, [0.0, 10.0, 20.0]);
      expect(decoded.durationSeconds, 274.2);
      expect(decoded.sampleRate, 16000);
      expect(decoded.sourceSampleRate, 44100.0);
      expect(decoded.channelCount, 2);
    });

    test('accepts a single window for short files', () async {
      reply((_) => nativeReply(windows: 1));

      final decoded = await AudioDecodeChannel().decodeWindows('/short.wav');

      expect(decoded.windows, hasLength(1));
    });

    test('sends the path and the YAMNet window spec by default', () async {
      MethodCall? received;
      reply((call) {
        received = call;
        return nativeReply();
      });

      await AudioDecodeChannel().decodeWindows('/song.m4a');

      expect(received?.method, 'decodeWindows');
      expect(received?.arguments, {
        'path': '/song.m4a',
        'positions': [0.25, 0.5, 0.75],
        'windowSeconds': 10.0,
        'sampleRate': 16000,
      });
    });

    test('sends a custom window spec', () async {
      MethodCall? received;
      reply((call) {
        received = call;
        return nativeReply(windows: 1);
      });

      final decoder = AudioDecodeChannel(
        positions: const [0.5],
        windowSeconds: 5,
        sampleRate: 48000,
      );
      final decoded = await decoder.decodeWindows('/song.flac');

      expect(received?.arguments, {
        'path': '/song.flac',
        'positions': [0.5],
        'windowSeconds': 5.0,
        'sampleRate': 48000,
      });
      expect(decoded.sampleRate, 48000);
    });

    test('maps native errors to AudioDecodeException', () async {
      reply(
        (_) => throw PlatformException(
          code: 'unreadable',
          message: "Can't open audio file",
        ),
      );

      expect(
        AudioDecodeChannel().decodeWindows('/song.ogg'),
        throwsDecodeError('unreadable'),
      );
    });

    test('reports unavailable when there is no native handler', () async {
      expect(
        AudioDecodeChannel().decodeWindows('/song.mp3'),
        throwsDecodeError('unavailable'),
      );
    });

    test('rejects a malformed reply', () async {
      reply(
        (_) => {
          ...nativeReply(),
          'windows': <Object?>['not audio'],
        },
      );

      expect(
        AudioDecodeChannel().decodeWindows('/song.mp3'),
        throwsDecodeError('bad_reply'),
      );
    });

    test('rejects an empty reply', () async {
      reply((_) => null);

      expect(
        AudioDecodeChannel().decodeWindows('/song.mp3'),
        throwsDecodeError('bad_reply'),
      );
    });

    group('rejects an invalid window spec without calling native', () {
      final invalid = <String, AudioDecodeChannel Function()>{
        'zero sampleRate': () => AudioDecodeChannel(sampleRate: 0),
        'negative sampleRate': () => AudioDecodeChannel(sampleRate: -16000),
        'zero windowSeconds': () => AudioDecodeChannel(windowSeconds: 0),
        'negative windowSeconds': () => AudioDecodeChannel(windowSeconds: -10),
        'NaN windowSeconds': () =>
            AudioDecodeChannel(windowSeconds: double.nan),
        'infinite windowSeconds': () =>
            AudioDecodeChannel(windowSeconds: double.infinity),
        'no positions': () => AudioDecodeChannel(positions: const []),
        'position above 1': () => AudioDecodeChannel(positions: const [1.5]),
        'negative position': () => AudioDecodeChannel(positions: const [-0.1]),
        'NaN position': () => AudioDecodeChannel(positions: const [double.nan]),
      };

      for (final MapEntry(key: name, value: build) in invalid.entries) {
        test(name, () async {
          var called = false;
          reply((_) {
            called = true;
            return nativeReply();
          });

          await expectLater(
            build().decodeWindows('/song.mp3'),
            throwsDecodeError('bad_args'),
          );
          expect(called, isFalse);
        });
      }
    });

    test('accepts boundary positions 0 and 1', () async {
      reply((_) => nativeReply(windows: 2));

      final decoded = await AudioDecodeChannel(
        positions: const [0, 1],
      ).decodeWindows('/song.mp3');

      expect(decoded.windows, hasLength(2));
    });

    test('is an AudioWindowDecoder', () {
      expect(AudioDecodeChannel(), isA<AudioWindowDecoder>());
    });
  });
}
