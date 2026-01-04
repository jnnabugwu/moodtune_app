part of 'spotify_bloc.dart';

enum SpotifyStatus {
  initial,
  loading,
  launching,
  awaitingCode,
  connecting,
  connected,
  disconnected,
  error,
}

class SpotifyState extends Equatable {
  const SpotifyState({
    this.status = SpotifyStatus.initial,
    this.profile,
    this.authorizeUrl,
    this.error,
    this.isConnected = false,
    this.playlists,
  });

  final SpotifyStatus status;
  final SpotifyProfile? profile;
  final String? authorizeUrl;
  final String? error;
  final bool isConnected;
  final List<SpotifyPlaylist>? playlists;

  SpotifyState copyWith({
    SpotifyStatus? status,
    SpotifyProfile? profile,
    String? authorizeUrl,
    String? error,
    bool? isConnected,
    List<SpotifyPlaylist>? playlists,
  }) {
    return SpotifyState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      authorizeUrl: authorizeUrl ?? this.authorizeUrl,
      error: error,
      isConnected: isConnected ?? this.isConnected,
      playlists: playlists ?? this.playlists,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    authorizeUrl,
    error,
    isConnected,
    playlists,
  ];
}
