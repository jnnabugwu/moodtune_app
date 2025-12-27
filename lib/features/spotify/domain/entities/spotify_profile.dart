import 'package:equatable/equatable.dart';

/// Entity representing a Spotify user profile
class SpotifyProfile extends Equatable {
  const SpotifyProfile({
    required this.id,
    required this.displayName,
    required this.username,
    required this.followersCount,
    required this.followingCount,
    required this.playlistsCount,
    this.avatarUrl,
    this.email,
  });

  final String id;
  final String displayName;
  final String username;
  final int followersCount;
  final int followingCount;
  final int playlistsCount;
  final String? avatarUrl;
  final String? email;

  @override
  List<Object?> get props => [
        id,
        displayName,
        username,
        followersCount,
        followingCount,
        playlistsCount,
        avatarUrl,
        email,
      ];
}
