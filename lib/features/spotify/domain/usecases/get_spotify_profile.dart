import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Use case for fetching the user's Spotify profile
class GetSpotifyProfile {
  const GetSpotifyProfile(this._repository);

  final SpotifyRepository _repository;

  /// Fetches the user's Spotify profile
  ResultFuture<SpotifyProfile> call() async {
    return _repository.getProfile();
  }
}
