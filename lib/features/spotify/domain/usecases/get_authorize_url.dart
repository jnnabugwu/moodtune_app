import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Use case for retrieving the Spotify OAuth authorization URL
class GetAuthorizeUrl {
  const GetAuthorizeUrl(this._repository);

  final SpotifyRepository _repository;

  /// Fetches the authorization URL used to start the OAuth flow.
  ResultFuture<String> call() async {
    return _repository.getAuthorizeUrl();
  }
}

