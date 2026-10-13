import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/mood_distribution_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('MoodDistributionModel', () {
    test('fromJson parses every bucket', () {
      final model = MoodDistributionModel.fromJson(moodDistributionJson());

      expect(model.happy, 0.4);
      expect(model.sad, 0.1);
      expect(model.energetic, 0.3);
      expect(model.calm, 0.1);
      expect(model.danceable, 0.1);
    });

    test('fromJson coerces ints and defaults missing/null to 0', () {
      final model = MoodDistributionModel.fromJson(<String, dynamic>{
        'happy': 1,
        'sad': null,
      });

      expect(model.happy, 1.0);
      expect(model.happy, isA<double>());
      expect(model.sad, 0);
      expect(model.energetic, 0);
      expect(model.calm, 0);
      expect(model.danceable, 0);
    });

    test('toDomain maps every bucket', () {
      expect(
        MoodDistributionModel.fromJson(moodDistributionJson()).toDomain(),
        const MoodDistribution(
          happy: 0.4,
          sad: 0.1,
          energetic: 0.3,
          calm: 0.1,
          danceable: 0.1,
        ),
      );
    });
  });
}
