import 'package:equatable/equatable.dart';

class TrackAnalysis extends Equatable {
  const TrackAnalysis({
    required this.trackId,
    required this.trackName,
    required this.artists,
    required this.valence,
    required this.energy,
    required this.danceability,
    required this.moodLabel,
  });

  final String trackId;
  final String trackName;
  final List<String> artists;
  final double valence;
  final double energy;
  final double danceability;
  final String moodLabel;

  @override
  List<Object?> get props => [
    trackId,
    trackName,
    artists,
    valence,
    energy,
    danceability,
    moodLabel,
  ];
}
