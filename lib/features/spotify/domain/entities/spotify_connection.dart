import 'package:equatable/equatable.dart';

/// Entity representing the Spotify connection status
class SpotifyConnection extends Equatable {
  const SpotifyConnection({
    required this.isConnected,
    this.connectedAt,
  });

  final bool isConnected;
  final DateTime? connectedAt;

  @override
  List<Object?> get props => [isConnected, connectedAt];
}
