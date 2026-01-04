import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';

/// Data model for Spotify connection
class SpotifyConnectionModel extends SpotifyConnection {
  const SpotifyConnectionModel({
    required super.isConnected,
    super.connectedAt,
  });

  /// Creates a [SpotifyConnectionModel] from a domain entity
  factory SpotifyConnectionModel.fromDomain(SpotifyConnection entity) {
    return SpotifyConnectionModel(
      isConnected: entity.isConnected,
      connectedAt: entity.connectedAt,
    );
  }

  /// Creates a [SpotifyConnectionModel] from JSON
  factory SpotifyConnectionModel.fromJson(Map<String, dynamic> json) {
    return SpotifyConnectionModel(
      isConnected: json['is_connected'] as bool? ?? false,
      connectedAt: json['connected_at'] != null
          ? DateTime.parse(json['connected_at'] as String)
          : null,
    );
  }

  /// Converts this model to JSON
  Map<String, dynamic> toJson() {
    return {
      'is_connected': isConnected,
      'connected_at': connectedAt?.toIso8601String(),
    };
  }

  /// Converts this model to a domain entity
  SpotifyConnection toDomain() {
    return SpotifyConnection(
      isConnected: isConnected,
      connectedAt: connectedAt,
    );
  }
}
