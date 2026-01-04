part of 'spotify_bloc.dart';

abstract class SpotifyEvent extends Equatable {
  const SpotifyEvent();

  @override
  List<Object?> get props => [];
}

class SpotifyStarted extends SpotifyEvent {
  const SpotifyStarted();
}

class SpotifyAuthorizeRequested extends SpotifyEvent {
  const SpotifyAuthorizeRequested();
}

class SpotifyAuthCodeReceived extends SpotifyEvent {
  const SpotifyAuthCodeReceived(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class SpotifyProfileRequested extends SpotifyEvent {
  const SpotifyProfileRequested();
}

class SpotifyPlaylistsRequested extends SpotifyEvent {
  const SpotifyPlaylistsRequested({this.limit = 50, this.offset = 0});

  final int limit;
  final int offset;

  @override
  List<Object?> get props => [limit, offset];
}

class SpotifyDisconnectRequested extends SpotifyEvent {
  const SpotifyDisconnectRequested();
}

class SpotifyClearErrorRequested extends SpotifyEvent {
  const SpotifyClearErrorRequested();
}
