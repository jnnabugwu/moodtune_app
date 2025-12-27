import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Use case for connecting to Spotify
class ConnectSpotify {
  const ConnectSpotify(this._repository);

  final SpotifyRepository _repository;

  /// Connects to Spotify using the provided authorization code
  ResultFuture<SpotifyConnection> call(String authCode) async {
    return _repository.connectSpotify(authCode);
  }
}
