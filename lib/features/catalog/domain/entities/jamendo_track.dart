import 'package:equatable/equatable.dart';

class JamendoTrack extends Equatable {
  const JamendoTrack({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumImageUrl,
    required this.duration,
    required this.tags,
    required this.audioUrl,
    required this.jamendoPageUrl,
    required this.audiodownloadAllowed,
  });

  final String id;
  final String name;
  final String artistName;

  /// 48×48 thumbnail URL for track/album art.
  final String albumImageUrl;

  final Duration duration;

  /// Up to 2 tags shown in the UI (e.g. ["pop", "upbeat"]).
  final List<String> tags;

  /// Direct audio stream URL (used by backend for analysis).
  final String audioUrl;

  /// Jamendo artist/track page — shown in attribution row on Results screen.
  final String jamendoPageUrl;

  /// Only tracks where this is true are surfaced in search results.
  final bool audiodownloadAllowed;

  @override
  List<Object?> get props => [
        id,
        name,
        artistName,
        albumImageUrl,
        duration,
        tags,
        audioUrl,
        jamendoPageUrl,
        audiodownloadAllowed,
      ];
}
