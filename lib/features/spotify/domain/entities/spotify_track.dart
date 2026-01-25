import 'package:equatable/equatable.dart';

class SpotifyTrack extends Equatable {
  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artists,
    this.previewUrl,
    this.imageUrl,
    this.durationMs,
  });

  final String id;
  final String name;
  final List<String> artists;
  final String? previewUrl;
  final String? imageUrl;
  final int? durationMs;

  @override
  List<Object?> get props => [
    id,
    name,
    artists,
    previewUrl,
    imageUrl,
    durationMs,
  ];
}
