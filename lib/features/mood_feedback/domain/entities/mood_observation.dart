import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/device_details.dart';

/// Which analysis flow produced the backend mood.
enum MoodObservationSource { upload, catalog }

/// Which model's mood the results screen showed.
enum DisplayedMoodSource { onDevice, backend }

/// One analysis the user viewed: the backend mood next to the on-device
/// mood, what was displayed, and coarse device context.
///
/// PRIVACY: never add filenames, titles, artists or audio here. The backend
/// table deliberately has no columns for them.
class MoodObservation extends Equatable {
  const MoodObservation({
    required this.id,
    required this.source,
    required this.backendMood,
    required this.displayedMood,
    required this.displayedSource,
    this.analysisId,
    this.onDeviceMood,
    this.onDeviceTags = const [],
    this.onDeviceProbabilities,
    this.onDeviceLatencyMs,
    this.onDeviceError,
    this.platform,
    this.osVersion,
    this.deviceModel,
    this.appVersion,
  });

  /// Client-generated UUID v4 (see [newId]). The same id is used later to
  /// attach feedback, so keep it alongside the displayed result.
  final String id;
  final MoodObservationSource source;

  /// Backend analysis id, when the backend returned one.
  final String? analysisId;

  /// Backend label: `happy`, `energetic`, `calm`, `angry` or `sad`.
  final String backendMood;

  /// On-device label (same vocabulary), or null when it didn't run/failed.
  final String? onDeviceMood;

  /// Sound tags such as "vocals" (backend keeps at most 10, 40 chars each).
  final List<String> onDeviceTags;

  /// Softmax mood probabilities (at most 10 entries, each 0..1).
  final Map<String, double>? onDeviceProbabilities;
  final int? onDeviceLatencyMs;

  /// Why on-device classification failed (backend keeps at most 500 chars).
  final String? onDeviceError;

  /// The label the results screen showed.
  final String displayedMood;
  final DisplayedMoodSource displayedSource;

  final String? platform;
  final String? osVersion;
  final String? deviceModel;
  final String? appVersion;

  /// A random (version 4) UUID for [id].
  static String newId([Random? random]) {
    final rng = random ?? Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  /// Fills any device field that is still null from [details].
  MoodObservation withDeviceDetails(DeviceDetails details) {
    return MoodObservation(
      id: id,
      source: source,
      analysisId: analysisId,
      backendMood: backendMood,
      onDeviceMood: onDeviceMood,
      onDeviceTags: onDeviceTags,
      onDeviceProbabilities: onDeviceProbabilities,
      onDeviceLatencyMs: onDeviceLatencyMs,
      onDeviceError: onDeviceError,
      displayedMood: displayedMood,
      displayedSource: displayedSource,
      platform: platform ?? details.platform,
      osVersion: osVersion ?? details.osVersion,
      deviceModel: deviceModel ?? details.deviceModel,
      appVersion: appVersion ?? details.appVersion,
    );
  }

  @override
  List<Object?> get props => [
    id,
    source,
    analysisId,
    backendMood,
    onDeviceMood,
    onDeviceTags,
    onDeviceProbabilities,
    onDeviceLatencyMs,
    onDeviceError,
    displayedMood,
    displayedSource,
    platform,
    osVersion,
    deviceModel,
    appVersion,
  ];
}
