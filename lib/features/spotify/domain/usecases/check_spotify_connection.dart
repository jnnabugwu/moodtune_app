import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Use case for checking Spotify connection status
class CheckSpotifyConnection {
  const CheckSpotifyConnection(this._repository);

  final SpotifyRepository _repository;

  /// Checks if the user has a valid Spotify connection
  ResultFuture<bool> call() async {
    return _repository.checkConnection();
  }
}
