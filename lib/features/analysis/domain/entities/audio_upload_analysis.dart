import 'package:equatable/equatable.dart';

class UploadAudioFeatures extends Equatable {
  const UploadAudioFeatures({
    required this.tempo,
    required this.beatStrength,
    required this.spectralCentroid,
    required this.spectralRolloff,
    required this.spectralBandwidth,
    required this.harmonicRatio,
    required this.zeroCrossingRate,
    required this.rmsEnergy,
    required this.dynamicRange,
    required this.mfccMean,
    required this.durationSeconds,
  });

  final double tempo;
  final double beatStrength;
  final double spectralCentroid;
  final double spectralRolloff;
  final double spectralBandwidth;
  final double harmonicRatio;
  final double zeroCrossingRate;
  final double rmsEnergy;
  final double dynamicRange;
  final List<double> mfccMean;
  final double durationSeconds;

  @override
  List<Object?> get props => [
    tempo,
    beatStrength,
    spectralCentroid,
    spectralRolloff,
    spectralBandwidth,
    harmonicRatio,
    zeroCrossingRate,
    rmsEnergy,
    dynamicRange,
    mfccMean,
    durationSeconds,
  ];
}

class UploadMoodResult extends Equatable {
  const UploadMoodResult({
    required this.primaryMood,
    required this.moodScores,
    required this.confidence,
    required this.reasoning,
    required this.audioFeatures,
  });

  final String primaryMood;
  final Map<String, double> moodScores;
  final double confidence;
  final String reasoning;
  final UploadAudioFeatures audioFeatures;

  @override
  List<Object?> get props => [
    primaryMood,
    moodScores,
    confidence,
    reasoning,
    audioFeatures,
  ];
}

class AudioUploadAnalysis extends Equatable {
  const AudioUploadAnalysis({
    required this.id,
    required this.filename,
    required this.fileSizeBytes,
    required this.durationSeconds,
    required this.mood,
    required this.analysisMethod,
    required this.processedAt,
    required this.processingTimeSeconds,
    this.title,
    this.artist,
    this.album,
  });

  final String id;
  final String filename;
  final int fileSizeBytes;
  final double durationSeconds;
  final String? title;
  final String? artist;
  final String? album;
  final UploadMoodResult mood;
  final String analysisMethod;
  final DateTime processedAt;
  final double processingTimeSeconds;

  @override
  List<Object?> get props => [
    id,
    filename,
    fileSizeBytes,
    durationSeconds,
    title,
    artist,
    album,
    mood,
    analysisMethod,
    processedAt,
    processingTimeSeconds,
  ];
}
