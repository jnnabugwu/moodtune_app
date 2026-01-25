import 'package:moodtune_app/features/spotify/domain/entities/spotify_track.dart';

class SpotifyTrackModel extends SpotifyTrack {
  const SpotifyTrackModel({
    required super.id,
    required super.name,
    required super.artists,
    super.previewUrl,
    super.imageUrl,
    super.durationMs,
  });

  factory SpotifyTrackModel.fromJson(Map<String, dynamic> json) {
    return SpotifyTrackModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      artists: (json['artists'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      previewUrl: json['preview_url'] as String?,
      imageUrl: json['image_url'] as String?,
      durationMs: json['duration_ms'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artists': artists,
      'preview_url': previewUrl,
      'image_url': imageUrl,
      'duration_ms': durationMs,
    };
  }

  SpotifyTrack toDomain() {
    return SpotifyTrack(
      id: id,
      name: name,
      artists: artists,
      previewUrl: previewUrl,
      imageUrl: imageUrl,
      durationMs: durationMs,
    );
  }
}
