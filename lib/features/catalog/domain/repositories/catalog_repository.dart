import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';
import 'package:moodtune_app/utils/typedef.dart';

// Consistent with other repository contracts in this codebase (AuthRepository,
// AnalysisRepository). Abstract class is intentional for GetIt DI + testing.
// ignore: one_member_abstracts
abstract class CatalogRepository {
  /// Search Jamendo tracks by free-text query and/or mood tag.
  ///
  /// Results are pre-filtered to [audiodownloadAllowed == true] so the
  /// backend can always stream the audio for analysis.
  ResultFuture<List<JamendoTrack>> searchTracks({
    String? query,
    String? moodTag,
  });
}
