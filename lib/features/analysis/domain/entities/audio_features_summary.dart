import 'package:equatable/equatable.dart';

class AudioFeaturesSummary extends Equatable {
  const AudioFeaturesSummary({
    required this.valence,
    required this.energy,
    required this.danceability,
    required this.tempo,
    required this.acousticness,
    required this.instrumentalness,
  });

  final double valence;
  final double energy;
  final double danceability;
  final double tempo;
  final double acousticness;
  final double instrumentalness;

  @override
  List<Object?> get props => [
    valence,
    energy,
    danceability,
    tempo,
    acousticness,
    instrumentalness,
  ];
}
