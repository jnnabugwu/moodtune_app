import 'package:equatable/equatable.dart';

class SpotifyPlaylist extends Equatable {
  const SpotifyPlaylist({
    required this.id,
    required this.name,
    this.ownerDisplayName,
    this.imageUrl,
    this.description,
    this.tracksCount,
  });

  final String id;
  final String name;
  final String? ownerDisplayName;
  final String? imageUrl;
  final String? description;
  final int? tracksCount;

  @override
  List<Object?> get props => [
    id,
    name,
    ownerDisplayName,
    imageUrl,
    description,
    tracksCount,
  ];
}
