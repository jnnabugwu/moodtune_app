import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';

/// Shared fixtures for catalog tests.

JamendoTrack buildJamendoTrack({
  String id = '1',
  String name = 'Sunny Day',
  String artistName = 'The Testers',
  Duration duration = const Duration(seconds: 125),
  List<String> tags = const ['pop', 'happy'],
  bool audiodownloadAllowed = true,
}) {
  return JamendoTrack(
    id: id,
    name: name,
    artistName: artistName,
    // Empty so widget tests do not hit Image.network.
    albumImageUrl: '',
    duration: duration,
    tags: tags,
    audioUrl: 'https://audio.example/$id.mp3',
    jamendoPageUrl: 'https://jamendo.example/track/$id',
    audiodownloadAllowed: audiodownloadAllowed,
  );
}

/// A raw Jamendo `/tracks/` result item.
Map<String, dynamic> buildJamendoJson({
  Object id = 1,
  String name = 'Sunny Day',
  Object? audiodownloadAllowed = true,
  List<String> vartags = const ['happy'],
  List<String> genres = const ['pop', 'rock'],
}) {
  return {
    'id': id,
    'name': name,
    'artist_name': 'The Testers',
    'album_image': 'https://img.example/$id.jpg',
    'duration': 125,
    'audio': 'https://audio.example/$id.mp3',
    'shareurl': 'https://jamendo.example/track/$id',
    'audiodownload_allowed': audiodownloadAllowed,
    'musicinfo': {
      'tags': {'vartags': vartags, 'genres': genres},
    },
  };
}
