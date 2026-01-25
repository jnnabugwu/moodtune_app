import 'package:moodtune_app/features/analysis/domain/entities/song_analysis_result.dart';

class SongMoodResultModel {
  const SongMoodResultModel({
    required this.primaryMood,
    required this.confidence,
    required this.valence,
    required this.energy,
  });

  factory SongMoodResultModel.fromJson(Map<String, dynamic> json) {
    return SongMoodResultModel(
      primaryMood: json['primary_mood'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      valence: (json['valence'] as num?)?.toDouble() ?? 0,
      energy: (json['energy'] as num?)?.toDouble() ?? 0,
    );
  }

  final String primaryMood;
  final double confidence;
  final double valence;
  final double energy;

  SongMoodResult toDomain() {
    return SongMoodResult(
      primaryMood: primaryMood,
      confidence: confidence,
      valence: valence,
      energy: energy,
    );
  }
}

class SongAudioFeaturesModel {
  const SongAudioFeaturesModel({
    required this.tempo,
    required this.energy,
    required this.valence,
    required this.danceability,
    required this.loudness,
  });

  factory SongAudioFeaturesModel.fromJson(Map<String, dynamic> json) {
    return SongAudioFeaturesModel(
      tempo: (json['tempo'] as num?)?.toDouble() ?? 0,
      energy: (json['energy'] as num?)?.toDouble() ?? 0,
      valence: (json['valence'] as num?)?.toDouble() ?? 0,
      danceability: (json['danceability'] as num?)?.toDouble() ?? 0,
      loudness: (json['loudness'] as num?)?.toDouble() ?? 0,
    );
  }

  final double tempo;
  final double energy;
  final double valence;
  final double danceability;
  final double loudness;

  SongAudioFeatures toDomain() {
    return SongAudioFeatures(
      tempo: tempo,
      energy: energy,
      valence: valence,
      danceability: danceability,
      loudness: loudness,
    );
  }
}

class SongAnalysisResultModel {
  const SongAnalysisResultModel({
    required this.trackName,
    required this.artistName,
    required this.trackId,
    required this.mood,
    required this.features,
    required this.success,
    this.message = '',
  });

  factory SongAnalysisResultModel.fromJson(Map<String, dynamic> json) {
    return SongAnalysisResultModel(
      trackName: json['track_name'] as String? ?? '',
      artistName: json['artist_name'] as String? ?? '',
      trackId: json['track_id'] as String?,
      mood: SongMoodResultModel.fromJson(
        (json['mood'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      features: SongAudioFeaturesModel.fromJson(
        (json['features'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
    );
  }

  final String trackName;
  final String artistName;
  final String? trackId;
  final SongMoodResultModel mood;
  final SongAudioFeaturesModel features;
  final bool success;
  final String message;

  SongAnalysisResult toDomain() {
    return SongAnalysisResult(
      trackName: trackName,
      artistName: artistName,
      trackId: trackId,
      mood: mood.toDomain(),
      features: features.toDomain(),
      success: success,
      message: message,
    );
  }
}
