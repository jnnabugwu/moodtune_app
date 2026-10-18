import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

/// Request body for `POST /song/history`.
extension ResultHistoryRecordJson on ResultHistoryRecord {
  Map<String, dynamic> toJson() => {
    'source': source.name,
    'title': title,
    'artist': artist,
    'track_id': trackId,
    'displayed_mood': displayedMood,
    'displayed_source': displayedSource == MoodSource.onDevice
        ? 'on_device'
        : 'backend',
    'backend_mood': backendMood,
    'on_device_mood': onDeviceMood,
    'confidence': confidence,
    'observation_id': observationId,
    'title_from_filename': titleFromFilename,
  };
}
