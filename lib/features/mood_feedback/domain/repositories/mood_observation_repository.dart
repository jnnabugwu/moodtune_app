import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/mood_observation.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Records what the app showed for an analysis and the user's feedback.
abstract class MoodObservationRepository {
  /// Upserts [observation] by its id, so retries are safe.
  ResultFuture<void> record(MoodObservation observation);

  /// Answers "Does this feel right?" for the observation with [id].
  /// [userMood] is the bucket the user picked when they disagreed.
  ResultFuture<void> sendFeedback({
    required String id,
    required bool agrees,
    MoodIdentity? userMood,
  });
}
