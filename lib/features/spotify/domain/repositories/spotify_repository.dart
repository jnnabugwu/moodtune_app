import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Abstract repository interface for Spotify operations
///
/// This defines the contract for all Spotify-related data operations.
/// Implementations should handle the conversion from exceptions to failures.
abstract class SpotifyRepository {
  /// Returns the Spotify authorization URL to start the OAuth flow.
  ResultFuture<String> getAuthorizeUrl();

  /// Connects to Spotify using an authorization code
  ///
  /// Returns [SpotifyConnection] on success or [Failure] on error
  ResultFuture<SpotifyConnection> connectSpotify(String authCode);

  /// Checks if the user has a valid Spotify connection
  ///
  /// Returns true if connected, false otherwise, or [Failure] on error
  ResultFuture<bool> checkConnection();

  /// Gets the user's Spotify profile
  ///
  /// Returns [SpotifyProfile] on success or [Failure] on error
  ResultFuture<SpotifyProfile> getProfile();

  /// Gets the user's Spotify playlists
  ///
  /// Returns a list of playlists on success or [Failure] on error
  ResultFuture<List<SpotifyPlaylist>> getPlaylists({
    int limit = 50,
    int offset = 0,
  });

  /// Disconnects the user's Spotify account
  ///
  /// Returns void on success or [Failure] on error
  ResultFuture<void> disconnect();

  /// Gets tracks from a specific playlist
  ///
  /// Returns a list of tracks on success or [Failure] on error
  ResultFuture<List<SpotifyTrack>> getPlaylistTracks({
    required String playlistId,
    int limit = 50,
  });
}
