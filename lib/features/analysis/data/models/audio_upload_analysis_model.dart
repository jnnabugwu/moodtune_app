import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';

class UploadAudioFeaturesModel {
  const UploadAudioFeaturesModel({
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
    required this.energyLabel,
    required this.brightnessLabel,
    required this.textureLabel,
  });

  factory UploadAudioFeaturesModel.fromJson(Map<String, dynamic> json) {
    return UploadAudioFeaturesModel(
      tempo: (json['tempo'] as num?)?.toDouble() ?? 0,
      beatStrength: (json['beat_strength'] as num?)?.toDouble() ?? 0,
      spectralCentroid:
          (json['spectral_centroid'] as num?)?.toDouble() ?? 0,
      spectralRolloff:
          (json['spectral_rolloff'] as num?)?.toDouble() ?? 0,
      spectralBandwidth:
          (json['spectral_bandwidth'] as num?)?.toDouble() ?? 0,
      harmonicRatio: (json['harmonic_ratio'] as num?)?.toDouble() ?? 0,
      zeroCrossingRate:
          (json['zero_crossing_rate'] as num?)?.toDouble() ?? 0,
      rmsEnergy: (json['rms_energy'] as num?)?.toDouble() ?? 0,
      dynamicRange: (json['dynamic_range'] as num?)?.toDouble() ?? 0,
      mfccMean: (json['mfcc_mean'] as List<dynamic>? ?? [])
          .map((e) => (e as num).toDouble())
          .toList(),
      durationSeconds:
          (json['duration_seconds'] as num?)?.toDouble() ?? 0,
      energyLabel: json['energy_label'] as String? ?? '',
      brightnessLabel: json['brightness_label'] as String? ?? '',
      textureLabel: json['texture_label'] as String? ?? '',
    );
  }

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
  final String energyLabel;
  final String brightnessLabel;
  final String textureLabel;

  UploadAudioFeatures toDomain() {
    return UploadAudioFeatures(
      tempo: tempo,
      beatStrength: beatStrength,
      spectralCentroid: spectralCentroid,
      spectralRolloff: spectralRolloff,
      spectralBandwidth: spectralBandwidth,
      harmonicRatio: harmonicRatio,
      zeroCrossingRate: zeroCrossingRate,
      rmsEnergy: rmsEnergy,
      dynamicRange: dynamicRange,
      mfccMean: mfccMean,
      durationSeconds: durationSeconds,
      energyLabel: energyLabel,
      brightnessLabel: brightnessLabel,
      textureLabel: textureLabel,
    );
  }
}

class UploadMoodResultModel {
  const UploadMoodResultModel({
    required this.primaryMood,
    required this.moodScores,
    required this.confidence,
    required this.reasoning,
    required this.audioFeatures,
    required this.descriptors,
  });

  factory UploadMoodResultModel.fromJson(Map<String, dynamic> json) {
    final scores = (json['mood_scores'] as Map<String, dynamic>? ?? {})
        .map((key, value) => MapEntry(key, (value as num).toDouble()));
    return UploadMoodResultModel(
      primaryMood: json['primary_mood'] as String? ?? '',
      moodScores: scores,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      reasoning: json['reasoning'] as String? ?? '',
      audioFeatures: UploadAudioFeaturesModel.fromJson(
        json['audio_features'] as Map<String, dynamic>? ?? {},
      ),
      descriptors: (json['descriptors'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  final String primaryMood;
  final Map<String, double> moodScores;
  final double confidence;
  final String reasoning;
  final UploadAudioFeaturesModel audioFeatures;
  final List<String> descriptors;

  UploadMoodResult toDomain() {
    return UploadMoodResult(
      primaryMood: primaryMood,
      moodScores: moodScores,
      confidence: confidence,
      reasoning: reasoning,
      audioFeatures: audioFeatures.toDomain(),
      descriptors: descriptors,
    );
  }
}

class AudioUploadAnalysisModel {
  const AudioUploadAnalysisModel({
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
    this.jamendoTrackUrl,
  });

  factory AudioUploadAnalysisModel.fromJson(Map<String, dynamic> json) {
    return AudioUploadAnalysisModel(
      id: json['id'] as String? ?? '',
      filename: json['filename'] as String? ?? '',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      durationSeconds:
          (json['duration_seconds'] as num?)?.toDouble() ?? 0,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      album: json['album'] as String?,
      mood: UploadMoodResultModel.fromJson(
        json['mood'] as Map<String, dynamic>? ?? {},
      ),
      analysisMethod:
          json['analysis_method'] as String? ?? 'direct_audio',
      processedAt:
          DateTime.tryParse(json['processed_at'] as String? ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      processingTimeSeconds:
          (json['processing_time_seconds'] as num?)?.toDouble() ?? 0,
      jamendoTrackUrl: json['jamendo_track_url'] as String?,
    );
  }

  final String id;
  final String filename;
  final int fileSizeBytes;
  final double durationSeconds;
  final String? title;
  final String? artist;
  final String? album;
  final UploadMoodResultModel mood;
  final String analysisMethod;
  final DateTime processedAt;
  final double processingTimeSeconds;
  final String? jamendoTrackUrl;

  AudioUploadAnalysis toDomain() {
    return AudioUploadAnalysis(
      id: id,
      filename: filename,
      fileSizeBytes: fileSizeBytes,
      durationSeconds: durationSeconds,
      title: title,
      artist: artist,
      album: album,
      mood: mood.toDomain(),
      analysisMethod: analysisMethod,
      processedAt: processedAt,
      processingTimeSeconds: processingTimeSeconds,
      jamendoTrackUrl: jamendoTrackUrl,
    );
  }
}
