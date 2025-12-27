import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Abstract repository interface for Spotify operations
/// 
/// This defines the contract for all Spotify-related data operations.
/// Implementations should handle the conversion from exceptions to failures.
abstract class SpotifyRepository {
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

  /// Disconnects the user's Spotify account
  /// 
  /// Returns void on success or [Failure] on error
  ResultFuture<void> disconnect();
}
