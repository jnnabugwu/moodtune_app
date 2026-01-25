import 'package:equatable/equatable.dart';

class SongMoodResult extends Equatable {
  const SongMoodResult({
    required this.primaryMood,
    required this.confidence,
    required this.valence,
    required this.energy,
  });

  final String primaryMood;
  final double confidence;
  final double valence;
  final double energy;

  @override
  List<Object?> get props => [primaryMood, confidence, valence, energy];
}

class SongAudioFeatures extends Equatable {
  const SongAudioFeatures({
    required this.tempo,
    required this.energy,
    required this.valence,
    required this.danceability,
    required this.loudness,
  });

  final double tempo;
  final double energy;
  final double valence;
  final double danceability;
  final double loudness;

  @override
  List<Object?> get props => [tempo, energy, valence, danceability, loudness];
}

class SongAnalysisResult extends Equatable {
  const SongAnalysisResult({
    required this.trackName,
    required this.artistName,
    required this.trackId,
    required this.mood,
    required this.features,
    required this.success,
    this.message = '',
  });

  final String trackName;
  final String artistName;
  final String? trackId;
  final SongMoodResult mood;
  final SongAudioFeatures features;
  final bool success;
  final String message;

  @override
  List<Object?> get props => [
    trackName,
    artistName,
    trackId,
    mood,
    features,
    success,
    message,
  ];
}
