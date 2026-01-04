import 'package:moodtune_app/features/spotify/domain/entities/spotify_playlist.dart';

class SpotifyPlaylistModel extends SpotifyPlaylist {
  const SpotifyPlaylistModel({
    required super.id,
    required super.name,
    super.ownerDisplayName,
    super.imageUrl,
    super.description,
    super.tracksCount,
  });

  factory SpotifyPlaylistModel.fromJson(Map<String, dynamic> json) {
    return SpotifyPlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      ownerDisplayName: json['owner_display_name'] as String?,
      imageUrl: json['image_url'] as String?,
      description: json['description'] as String?,
      tracksCount: json['tracks_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'owner_display_name': ownerDisplayName,
    'image_url': imageUrl,
    'description': description,
    'tracks_count': tracksCount,
  };

  SpotifyPlaylist toDomain() => this;
}
