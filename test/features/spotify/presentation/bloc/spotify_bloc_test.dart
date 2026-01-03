import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/features/spotify/domain/usecases/usecases.dart';
import 'package:moodtune_app/features/spotify/presentation/presentation.dart';

class _MockSpotifyRepository extends Mock implements SpotifyRepository {}

void main() {
  late _MockSpotifyRepository repository;
  late SpotifyBloc bloc;

  const tProfile = SpotifyProfile(
    id: 'id-123',
    displayName: 'Sam Lee',
    username: 'samlee',
    followersCount: 1,
    followingCount: 2,
    playlistsCount: 3,
    avatarUrl: null,
    email: 'samlee@example.com',
  );

  setUp(() {
    repository = _MockSpotifyRepository();

    bloc = SpotifyBloc(
      getAuthorizeUrl: GetAuthorizeUrl(repository),
      connectSpotify: ConnectSpotify(repository),
      checkSpotifyConnection: CheckSpotifyConnection(repository),
      getSpotifyProfile: GetSpotifyProfile(repository),
      disconnectSpotify: DisconnectSpotify(repository),
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state is SpotifyState.initial', () {
    expect(bloc.state.status, SpotifyStatus.initial);
  });

  blocTest<SpotifyBloc, SpotifyState>(
    'emits loading then connected with profile on start when already connected',
    setUp: () {
      when(() => repository.checkConnection()).thenAnswer(
        (_) async => const Right(true),
      );
      when(() => repository.getProfile()).thenAnswer(
        (_) async => const Right(tProfile),
      );
    },
    build: () => bloc,
    act: (bloc) => bloc.add(const SpotifyStarted()),
    expect: () => [
      const SpotifyState(status: SpotifyStatus.loading, isConnected: false),
      const SpotifyState(
        status: SpotifyStatus.connected,
        isConnected: true,
        profile: tProfile,
      ),
    ],
    verify: (_) {
      verify(() => repository.checkConnection()).called(1);
      verify(() => repository.getProfile()).called(1);
    },
  );

  blocTest<SpotifyBloc, SpotifyState>(
    'emits launching then awaitingCode with authorize URL on authorize request',
    setUp: () {
      when(() => repository.getAuthorizeUrl()).thenAnswer(
        (_) async => const Right('https://example.com/auth'),
      );
    },
    build: () => bloc,
    act: (bloc) => bloc.add(const SpotifyAuthorizeRequested()),
    expect: () => [
      const SpotifyState(status: SpotifyStatus.launching, isConnected: false),
      const SpotifyState(
        status: SpotifyStatus.awaitingCode,
        isConnected: false,
        authorizeUrl: 'https://example.com/auth',
      ),
    ],
  );

  blocTest<SpotifyBloc, SpotifyState>(
    'emits error when authorize URL retrieval fails',
    setUp: () {
      when(() => repository.getAuthorizeUrl()).thenAnswer(
        (_) async => const Left(ServerFailure('failed')),
      );
    },
    build: () => bloc,
    act: (bloc) => bloc.add(const SpotifyAuthorizeRequested()),
    expect: () => [
      const SpotifyState(status: SpotifyStatus.launching, isConnected: false),
      const SpotifyState(
        status: SpotifyStatus.error,
        isConnected: false,
        error: 'failed',
      ),
    ],
  );

  blocTest<SpotifyBloc, SpotifyState>(
    'connects with auth code and loads profile',
    setUp: () {
      when(() => repository.connectSpotify(any())).thenAnswer(
        (_) async => Right(
          SpotifyConnection(isConnected: true, connectedAt: DateTime.now()),
        ),
      );
      when(() => repository.getProfile()).thenAnswer(
        (_) async => const Right(tProfile),
      );
    },
    build: () => bloc,
    act: (bloc) => bloc.add(const SpotifyAuthCodeReceived('code-123')),
    expect: () => [
      const SpotifyState(
        status: SpotifyStatus.connecting,
        isConnected: false,
      ),
      const SpotifyState(status: SpotifyStatus.loading, isConnected: false),
      const SpotifyState(
        status: SpotifyStatus.connected,
        isConnected: true,
        profile: tProfile,
      ),
    ],
    verify: (_) {
      verify(() => repository.connectSpotify('code-123')).called(1);
      verify(() => repository.getProfile()).called(1);
    },
  );
}
