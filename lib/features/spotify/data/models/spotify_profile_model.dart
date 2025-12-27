import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';

/// Data model for Spotify user profile
class SpotifyProfileModel extends SpotifyProfile {
  const SpotifyProfileModel({
    required super.id,
    required super.displayName,
    required super.username,
    required super.followersCount,
    required super.followingCount,
    required super.playlistsCount,
    super.avatarUrl,
    super.email,
  });

  /// Creates a [SpotifyProfileModel] from JSON
  factory SpotifyProfileModel.fromJson(Map<String, dynamic> json) {
    return SpotifyProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      username: json['username'] as String? ?? json['id'] as String,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      playlistsCount: json['playlists_count'] as int? ?? 0,
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
    );
  }

  /// Creates a [SpotifyProfileModel] from a domain entity
  factory SpotifyProfileModel.fromDomain(SpotifyProfile entity) {
    return SpotifyProfileModel(
      id: entity.id,
      displayName: entity.displayName,
      username: entity.username,
      followersCount: entity.followersCount,
      followingCount: entity.followingCount,
      playlistsCount: entity.playlistsCount,
      avatarUrl: entity.avatarUrl,
      email: entity.email,
    );
  }

  /// Converts this model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'username': username,
      'followers_count': followersCount,
      'following_count': followingCount,
      'playlists_count': playlistsCount,
      'avatar_url': avatarUrl,
      'email': email,
    };
  }

  /// Converts this model to a domain entity
  SpotifyProfile toDomain() {
    return SpotifyProfile(
      id: id,
      displayName: displayName,
      username: username,
      followersCount: followersCount,
      followingCount: followingCount,
      playlistsCount: playlistsCount,
      avatarUrl: avatarUrl,
      email: email,
    );
  }
}
