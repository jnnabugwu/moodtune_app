import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/spotify/data/models/models.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Lightweight in-app implementation that simulates Spotify connectivity.
/// Replace with a real data source (REST/gRPC) once backend endpoints are wired.
class SpotifyRepositoryImpl implements SpotifyRepository {
  SpotifyRepositoryImpl({
    Dio? dio,
  }) : _dio = dio ?? Dio();

  // ignore: unused_field
  final Dio _dio;

  bool _isConnected = false;
  SpotifyProfileModel? _profile;

  @override
  ResultFuture<String> getAuthorizeUrl() async {
    // In a real implementation, fetch from backend authorize endpoint.
    return right('https://accounts.spotify.com/authorize');
  }

  @override
  ResultFuture<SpotifyConnection> connectSpotify(String authCode) async {
    // TODO: Replace mock with actual backend call using [_dio] and [authCode].
    _isConnected = true;
    _profile = const SpotifyProfileModel(
      id: 'sample-user-id',
      displayName: 'Sam Lee',
      username: 'samlee',
      followersCount: 0,
      followingCount: 2,
      playlistsCount: 3,
      email: 'samlee@example.com',
    );

    return right(
      SpotifyConnection(
        isConnected: _isConnected,
        connectedAt: DateTime.now(),
      ),
    );
  }

  @override
  ResultFuture<bool> checkConnection() async {
    return right(_isConnected);
  }

  @override
  ResultFuture<void> disconnect() async {
    _isConnected = false;
    _profile = null;
    return right(null);
  }

  @override
  ResultFuture<SpotifyProfile> getProfile() async {
    if (!_isConnected || _profile == null) {
      return left(
        const ServerFailure('No Spotify connection found'),
      );
    }
    return right(_profile!.toDomain());
  }
}

