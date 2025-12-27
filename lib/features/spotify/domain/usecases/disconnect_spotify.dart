import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Use case for disconnecting from Spotify
class DisconnectSpotify {
  const DisconnectSpotify(this._repository);

  final SpotifyRepository _repository;

  /// Disconnects the user's Spotify account
  ResultFuture<void> call() async {
    return _repository.disconnect();
  }
}
