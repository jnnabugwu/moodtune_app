import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A few fixed-length windows of a track as mono float PCM, ready for an
/// on-device audio model such as YAMNet.
class DecodedAudio extends Equatable {
  const DecodedAudio({
    required this.windows,
    required this.startSeconds,
    required this.durationSeconds,
    required this.sampleRate,
    required this.sourceSampleRate,
    required this.channelCount,
  });

  /// One buffer per window, each `windowSeconds * sampleRate` samples long
  /// (a file shorter than one window comes back whole, as a single window).
  final List<Float32List> windows;

  /// Where each window starts in the track.
  final List<double> startSeconds;

  final double durationSeconds;

  /// Sample rate of [windows].
  final int sampleRate;

  /// Sample rate and channel count of the original file, for diagnostics.
  final double sourceSampleRate;
  final int channelCount;

  @override
  List<Object?> get props => [
    windows,
    startSeconds,
    durationSeconds,
    sampleRate,
    sourceSampleRate,
    channelCount,
  ];
}

/// Decodes the parts of an audio file an on-device model needs.
///
/// Throws `AudioDecodeException` on any failure; callers fall back to the
/// backend's analysis.
abstract interface class AudioWindowDecoder {
  Future<DecodedAudio> decodeWindows(String path);
}
