import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';
import 'package:moodtune_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Returns a list of Jamendo tracks matching the given query and/or mood tag.
/// Results are pre-filtered to audiodownloadAllowed == true by the repository.
class SearchCatalog {
  const SearchCatalog(this._repository);

  final CatalogRepository _repository;

  ResultFuture<List<JamendoTrack>> call({
    String? query,
    String? moodTag,
  }) => _repository.searchTracks(query: query, moodTag: moodTag);
}
