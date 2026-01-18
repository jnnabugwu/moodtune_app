import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

class MoodDistributionModel {
  const MoodDistributionModel({
    required this.happy,
    required this.sad,
    required this.energetic,
    required this.calm,
    required this.danceable,
  });


  factory MoodDistributionModel.fromJson(Map<String, dynamic> json) {
    return MoodDistributionModel(
      happy: (json['happy'] as num?)?.toDouble() ?? 0,
      sad: (json['sad'] as num?)?.toDouble() ?? 0,
      energetic: (json['energetic'] as num?)?.toDouble() ?? 0,
      calm: (json['calm'] as num?)?.toDouble() ?? 0,
      danceable: (json['danceable'] as num?)?.toDouble() ?? 0,
    );
  }
  
  final double happy;
  final double sad;
  final double energetic;
  final double calm;
  final double danceable;

  MoodDistribution toDomain() {
    return MoodDistribution(
      happy: happy,
      sad: sad,
      energetic: energetic,
      calm: calm,
      danceable: danceable,
    );
  }
}
