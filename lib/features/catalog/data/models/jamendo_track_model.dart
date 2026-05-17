import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';

class JamendoTrackModel {
  const JamendoTrackModel({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumImageUrl,
    required this.durationSeconds,
    required this.tags,
    required this.audioUrl,
    required this.jamendoPageUrl,
    required this.audiodownloadAllowed,
  });

  factory JamendoTrackModel.fromJson(Map<String, dynamic> json) {
    // Jamendo returns audiodownload_allowed as int (1/0) or bool
    final rawAllowed = json['audiodownload_allowed'];
    final downloadAllowed =
        rawAllowed == true || rawAllowed == 1 || rawAllowed == '1';

    // Tags live inside musicinfo.tags
    // Combine vartags + genres (up to 2 shown in UI)
    final musicInfo = json['musicinfo'] as Map<String, dynamic>? ?? {};
    final tagMap = musicInfo['tags'] as Map<String, dynamic>? ?? {};
    final vartags = (tagMap['vartags'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
    final genres = (tagMap['genres'] as List<dynamic>? ?? [])
        .map((e) => e as String)
        .toList();
    // Prefer vartags first; fall back to genres to fill up to 2 slots
    final tags = [...vartags, ...genres].take(2).toList();

    return JamendoTrackModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      artistName: json['artist_name'] as String? ?? '',
      albumImageUrl: json['album_image'] as String? ?? '',
      durationSeconds: (json['duration'] as num?)?.toInt() ?? 0,
      tags: tags,
      audioUrl: json['audiodownload'] as String? ?? '',
      jamendoPageUrl: json['shareurl'] as String? ?? '',
      audiodownloadAllowed: downloadAllowed,
    );
  }

  final String id;
  final String name;
  final String artistName;
  final String albumImageUrl;
  final int durationSeconds;
  final List<String> tags;
  final String audioUrl;
  final String jamendoPageUrl;
  final bool audiodownloadAllowed;

  JamendoTrack toDomain() {
    return JamendoTrack(
      id: id,
      name: name,
      artistName: artistName,
      albumImageUrl: albumImageUrl,
      duration: Duration(seconds: durationSeconds),
      tags: tags,
      audioUrl: audioUrl,
      jamendoPageUrl: jamendoPageUrl,
      audiodownloadAllowed: audiodownloadAllowed,
    );
  }
}
