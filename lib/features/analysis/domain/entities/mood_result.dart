import 'package:equatable/equatable.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_features_summary.dart';
import 'package:moodtune_app/features/analysis/domain/entities/mood_distribution.dart';
import 'package:moodtune_app/features/analysis/domain/entities/track_analysis.dart';

class MoodResult extends Equatable {
  const MoodResult({
    required this.primaryMood,
    required this.moodCategory,
    required this.moodDescriptors,
    required this.confidence,
    required this.averages,
    required this.moodDistribution,
    required this.topTracks,
    required this.trackCount,
  });

  final String primaryMood;
  final String moodCategory;
  final List<String> moodDescriptors;
  final double confidence;
  final AudioFeaturesSummary averages;
  final MoodDistribution moodDistribution;
  final List<TrackAnalysis> topTracks;
  final int trackCount;

  @override
  List<Object?> get props => [
    primaryMood,
    moodCategory,
    moodDescriptors,
    confidence,
    averages,
    moodDistribution,
    topTracks,
    trackCount,
  ];
}
