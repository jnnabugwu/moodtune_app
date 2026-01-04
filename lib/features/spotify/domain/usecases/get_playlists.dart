import 'package:moodtune_app/features/spotify/domain/entities/spotify_playlist.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

class GetPlaylists {
  const GetPlaylists(this._repository);

  final SpotifyRepository _repository;

  ResultFuture<List<SpotifyPlaylist>> call({
    int limit = 50,
    int offset = 0,
  }) {
    return _repository.getPlaylists(limit: limit, offset: offset);
  }
}
