import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

class TrackAnalysisModel {
  const TrackAnalysisModel({
    required this.trackId,
    required this.trackName,
    required this.artists,
    required this.valence,
    required this.energy,
    required this.danceability,
    required this.moodLabel,
  });

  factory TrackAnalysisModel.fromJson(Map<String, dynamic> json) {
    return TrackAnalysisModel(
      trackId: json['track_id'] as String? ?? '',
      trackName: json['track_name'] as String? ?? '',
      artists: (json['artists'] as List<dynamic>? ?? []).cast<String>(),
      valence: (json['valence'] as num?)?.toDouble() ?? 0,
      energy: (json['energy'] as num?)?.toDouble() ?? 0,
      danceability: (json['danceability'] as num?)?.toDouble() ?? 0,
      moodLabel: json['mood_label'] as String? ?? '',
    );
  }

  final String trackId;
  final String trackName;
  final List<String> artists;
  final double valence;
  final double energy;
  final double danceability;
  final String moodLabel;

  TrackAnalysis toDomain() {
    return TrackAnalysis(
      trackId: trackId,
      trackName: trackName,
      artists: artists,
      valence: valence,
      energy: energy,
      danceability: danceability,
      moodLabel: moodLabel,
    );
  }
}
