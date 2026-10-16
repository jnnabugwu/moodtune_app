import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:moodtune_app/core/error/exceptions.dart';
import 'package:moodtune_app/features/on_device_mood/domain/decoded_audio.dart';

/// [AudioWindowDecoder] backed by AVFoundation through the
/// `moodtune/audio_decode` method channel (see
/// ios/Runner/AudioWindowDecoder.swift).
///
/// Defaults match what the YAMNet spike evaluated: three 10 s windows
/// centred at 25%, 50% and 75% of the track, mono, 16 kHz. Platforms without
/// a handler (Android for now) throw an `unavailable` [AudioDecodeException].
class AudioDecodeChannel implements AudioWindowDecoder {
  AudioDecodeChannel({
    MethodChannel channel = const MethodChannel('moodtune/audio_decode'),
    this.positions = const [0.25, 0.5, 0.75],
    this.windowSeconds = 10,
    this.sampleRate = 16000,
  }) : _channel = channel;

  final MethodChannel _channel;
  final List<double> positions;
  final double windowSeconds;
  final int sampleRate;

  @override
  Future<DecodedAudio> decodeWindows(String path) async {
    _checkWindowSpec();
    final Map<String, Object?>? reply;
    try {
      reply = await _channel.invokeMapMethod<String, Object?>(
        'decodeWindows',
        {
          'path': path,
          'positions': positions,
          'windowSeconds': windowSeconds,
          'sampleRate': sampleRate,
        },
      );
    } on MissingPluginException {
      throw const AudioDecodeException(
        'unavailable',
        'No native audio decoder on this platform',
      );
    } on PlatformException catch (error) {
      throw AudioDecodeException(
        error.code,
        error.message ?? 'Audio decode failed',
      );
    }

    if (reply case {
      'windows': final List<Object?> windows,
      'startSeconds': final List<Object?> starts,
      'durationSeconds': final double duration,
      'sourceSampleRate': final double sourceRate,
      'channelCount': final int channels,
    }) {
      final buffers = windows.whereType<Float32List>().toList();
      final startSeconds = starts.whereType<double>().toList();
      if (buffers.isNotEmpty &&
          buffers.length == windows.length &&
          startSeconds.length == buffers.length) {
        return DecodedAudio(
          windows: buffers,
          startSeconds: startSeconds,
          durationSeconds: duration,
          sampleRate: sampleRate,
          sourceSampleRate: sourceRate,
          channelCount: channels,
        );
      }
    }
    throw const AudioDecodeException(
      'bad_reply',
      'Unexpected reply from the native audio decoder',
    );
  }

  /// Rejects a window spec native code can't turn into frame counts. The
  /// Swift decoder checks the same things; failing here skips the round trip.
  void _checkWindowSpec() {
    if (sampleRate <= 0) {
      throw AudioDecodeException(
        'bad_args',
        'sampleRate must be positive, got $sampleRate',
      );
    }
    if (!windowSeconds.isFinite || windowSeconds <= 0) {
      throw AudioDecodeException(
        'bad_args',
        'windowSeconds must be positive and finite, got $windowSeconds',
      );
    }
    if (positions.isEmpty ||
        positions.any((p) => !p.isFinite || p < 0 || p > 1)) {
      throw AudioDecodeException(
        'bad_args',
        'positions must be fractions in [0, 1], got $positions',
      );
    }
  }
}
