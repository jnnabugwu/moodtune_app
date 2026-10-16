import 'package:moodtune_app/features/mood_feedback/domain/entities/mood_observation.dart';

/// Wire values shared with the backend's `mood_observations` table.
extension MoodObservationSourceWire on MoodObservationSource {
  String get wireValue => switch (this) {
    MoodObservationSource.upload => 'upload',
    MoodObservationSource.catalog => 'catalog',
  };
}

extension DisplayedMoodSourceWire on DisplayedMoodSource {
  String get wireValue => switch (this) {
    DisplayedMoodSource.onDevice => 'on_device',
    DisplayedMoodSource.backend => 'backend',
  };
}

/// Request body for `POST /mood-observations`.
extension MoodObservationJson on MoodObservation {
  Map<String, dynamic> toJson() => {
    'id': id,
    'source': source.wireValue,
    'analysis_id': analysisId,
    'backend_mood': backendMood,
    'on_device_mood': onDeviceMood,
    'on_device_tags': onDeviceTags,
    'on_device_probabilities': onDeviceProbabilities,
    'on_device_latency_ms': onDeviceLatencyMs,
    'on_device_error': onDeviceError,
    'displayed_mood': displayedMood,
    'displayed_source': displayedSource.wireValue,
    'platform': platform,
    'os_version': osVersion,
    'device_model': deviceModel,
    'app_version': appVersion,
  };
}
