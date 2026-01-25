import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

class AudioFeaturesSummaryModel {
  const AudioFeaturesSummaryModel({
    required this.valence,
    required this.energy,
    required this.danceability,
    required this.tempo,
    required this.acousticness,
    required this.instrumentalness,
  });

  factory AudioFeaturesSummaryModel.fromJson(Map<String, dynamic> json) {
    return AudioFeaturesSummaryModel(
      valence: (json['valence'] as num?)?.toDouble() ?? 0,
      energy: (json['energy'] as num?)?.toDouble() ?? 0,
      danceability: (json['danceability'] as num?)?.toDouble() ?? 0,
      tempo: (json['tempo'] as num?)?.toDouble() ?? 0,
      acousticness: (json['acousticness'] as num?)?.toDouble() ?? 0,
      instrumentalness: (json['instrumentalness'] as num?)?.toDouble() ?? 0,
    );
  }

  final double valence;
  final double energy;
  final double danceability;
  final double tempo;
  final double acousticness;
  final double instrumentalness;

  AudioFeaturesSummary toDomain() {
    return AudioFeaturesSummary(
      valence: valence,
      energy: energy,
      danceability: danceability,
      tempo: tempo,
      acousticness: acousticness,
      instrumentalness: instrumentalness,
    );
  }
}
