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
  });

  final SpotifyStatus status;
  final SpotifyProfile? profile;
  final String? authorizeUrl;
  final String? error;
  final bool isConnected;

  SpotifyState copyWith({
    SpotifyStatus? status,
    SpotifyProfile? profile,
    String? authorizeUrl,
    String? error,
    bool? isConnected,
  }) {
    return SpotifyState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      authorizeUrl: authorizeUrl ?? this.authorizeUrl,
      error: error,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  List<Object?> get props => [
    status,
    profile,
    authorizeUrl,
    error,
    isConnected,
  ];
}
