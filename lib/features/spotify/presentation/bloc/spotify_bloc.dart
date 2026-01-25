// Need to ignore for this filie because of the bloc pattern
// ignore_for_file: avoid_redundant_argument_values

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/features/spotify/domain/usecases/usecases.dart';

part 'spotify_event.dart';
part 'spotify_state.dart';

class SpotifyBloc extends Bloc<SpotifyEvent, SpotifyState> {
  SpotifyBloc({
    required GetAuthorizeUrl getAuthorizeUrl,
    required ConnectSpotify connectSpotify,
    required CheckSpotifyConnection checkSpotifyConnection,
    required GetSpotifyProfile getSpotifyProfile,
    required DisconnectSpotify disconnectSpotify,
    required GetPlaylists getPlaylists,
    required SpotifyRepository repository,
  }) : _getAuthorizeUrl = getAuthorizeUrl,
       _connectSpotify = connectSpotify,
       _checkSpotifyConnection = checkSpotifyConnection,
       _getSpotifyProfile = getSpotifyProfile,
       _disconnectSpotify = disconnectSpotify,
       _getPlaylists = getPlaylists,
       _repository = repository,
       super(const SpotifyState()) {
    on<SpotifyStarted>(_onStarted);
    on<SpotifyAuthorizeRequested>(_onAuthorizeRequested);
    on<SpotifyAuthCodeReceived>(_onAuthCodeReceived);
    on<SpotifyProfileRequested>(_onProfileRequested);
    on<SpotifyDisconnectRequested>(_onDisconnectRequested);
    on<SpotifyClearErrorRequested>(_onClearErrorRequested);
    on<SpotifyPlaylistsRequested>(_onPlaylistsRequested);
    on<SpotifyPlaylistTracksRequested>(_onPlaylistTracksRequested);
  }

  final GetAuthorizeUrl _getAuthorizeUrl;
  final ConnectSpotify _connectSpotify;
  final CheckSpotifyConnection _checkSpotifyConnection;
  final GetSpotifyProfile _getSpotifyProfile;
  final DisconnectSpotify _disconnectSpotify;
  final GetPlaylists _getPlaylists;
  final SpotifyRepository _repository;

  Future<void> _onStarted(
    SpotifyStarted event,
    Emitter<SpotifyState> emit,
  ) async {
    // #region agent log
    // ignore: avoid_print
    print(
      'AGENTLOG ${{
        'sessionId': 'debug-session',
        'runId': 'prefix-connect',
        'hypothesisId': 'H-start',
        'location': 'spotify_bloc.dart:_onStarted',
        'message': 'SpotifyStarted received',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }}',
    );
    // #endregion
    emit(state.copyWith(status: SpotifyStatus.loading, error: null));
    final result = await _checkSpotifyConnection();
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: SpotifyStatus.error,
          error: failure.message,
          isConnected: false,
        ),
      ),
      (isConnected) async {
        if (!isConnected) {
          emit(
            state.copyWith(
              status: SpotifyStatus.disconnected,
              isConnected: false,
            ),
          );
          return;
        }
        await _loadProfile(emit);
      },
    );
  }

  Future<void> _onAuthorizeRequested(
    SpotifyAuthorizeRequested event,
    Emitter<SpotifyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SpotifyStatus.launching,
      ),
    );

    final result = await _getAuthorizeUrl();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SpotifyStatus.error,
          error: failure.message,
        ),
      ),
      (url) => emit(
        state.copyWith(
          status: SpotifyStatus.awaitingCode,
          authorizeUrl: url,
        ),
      ),
    );
  }

  Future<void> _onAuthCodeReceived(
    SpotifyAuthCodeReceived event,
    Emitter<SpotifyState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SpotifyStatus.connecting,
        error: null,
      ),
    );

    final result = await _connectSpotify(event.code);
    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: SpotifyStatus.error,
          error: failure.message,
          isConnected: false,
        ),
      ),
      (_) async {
        await _loadProfile(emit);
      },
    );
  }

  Future<void> _onProfileRequested(
    SpotifyProfileRequested event,
    Emitter<SpotifyState> emit,
  ) async {
    await _loadProfile(emit);
  }

  Future<void> _onDisconnectRequested(
    SpotifyDisconnectRequested event,
    Emitter<SpotifyState> emit,
  ) async {
    final result = await _disconnectSpotify();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SpotifyStatus.error,
          error: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: SpotifyStatus.disconnected,
          isConnected: false,
          profile: null,
          authorizeUrl: null,
        ),
      ),
    );
  }

  void _onClearErrorRequested(
    SpotifyClearErrorRequested event,
    Emitter<SpotifyState> emit,
  ) {
    emit(state.copyWith(status: SpotifyStatus.initial));
  }

  Future<void> _loadProfile(Emitter<SpotifyState> emit) async {
    emit(
      state.copyWith(
        status: SpotifyStatus.loading,
        error: null,
      ),
    );

    final result = await _getSpotifyProfile();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SpotifyStatus.error,
          error: failure.message,
          isConnected: false,
        ),
      ),
      (profile) {
        final updated = state.copyWith(
          status: SpotifyStatus.connected,
          isConnected: true,
          profile: profile,
        );
        emit(updated);
        add(const SpotifyPlaylistsRequested(limit: 3, offset: 0));
      },
    );
  }

  Future<void> _onPlaylistsRequested(
    SpotifyPlaylistsRequested event,
    Emitter<SpotifyState> emit,
  ) async {
    final result = await _getPlaylists(
      limit: event.limit,
      offset: event.offset,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          error: failure.message,
        ),
      ),
      (playlists) => emit(
        state.copyWith(
          playlists: playlists,
        ),
      ),
    );
  }

  Future<void> _onPlaylistTracksRequested(
    SpotifyPlaylistTracksRequested event,
    Emitter<SpotifyState> emit,
  ) async {
    emit(
      state.copyWith(
        playlistTracksLoading: true,
        playlistTracksError: null,
      ),
    );

    final result = await _repository.getPlaylistTracks(
      playlistId: event.playlistId,
      limit: event.limit,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          playlistTracksLoading: false,
          playlistTracksError: failure.message,
        ),
      ),
      (tracks) => emit(
        state.copyWith(
          playlistTracksLoading: false,
          playlistTracks: tracks,
        ),
      ),
    );
  }
}
