import 'package:moodtune_app/features/analysis/data/models/audio_features_summary_model.dart';
import 'package:moodtune_app/features/analysis/data/models/mood_distribution_model.dart';
import 'package:moodtune_app/features/analysis/data/models/track_analysis_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

class MoodResultModel {
  const MoodResultModel({
    required this.primaryMood,
    required this.moodCategory,
    required this.moodDescriptors,
    required this.confidence,
    required this.averages,
    required this.moodDistribution,
    required this.topTracks,
    required this.trackCount,
  });

  factory MoodResultModel.fromJson(Map<String, dynamic> json) {
    final topTracksJson = (json['top_tracks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return MoodResultModel(
      primaryMood: json['primary_mood'] as String? ?? '',
      moodCategory: json['mood_category'] as String? ?? '',
      moodDescriptors: (json['mood_descriptors'] as List<dynamic>? ?? [])
          .cast<String>(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      averages: AudioFeaturesSummaryModel.fromJson(
        (json['averages'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      ),
      moodDistribution: MoodDistributionModel.fromJson(
        (json['mood_distribution'] as Map<String, dynamic>?) ??
            <String, dynamic>{},
      ),
      topTracks: topTracksJson
          .map(TrackAnalysisModel.fromJson)
          .toList(growable: false),
      trackCount:
          json['track_count'] as int? ?? (json['trackCount'] as int?) ?? 0,
    );
  }

  final String primaryMood;
  final String moodCategory;
  final List<String> moodDescriptors;
  final double confidence;
  final AudioFeaturesSummaryModel averages;
  final MoodDistributionModel moodDistribution;
  final List<TrackAnalysisModel> topTracks;
  final int trackCount;



  MoodResult toDomain() {
    return MoodResult(
      primaryMood: primaryMood,
      moodCategory: moodCategory,
      moodDescriptors: moodDescriptors,
      confidence: confidence,
      averages: averages.toDomain(),
      moodDistribution: moodDistribution.toDomain(),
      topTracks: topTracks.map((t) => t.toDomain()).toList(),
      trackCount: trackCount,
    );
  }
}
