import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/analysis/domain/domain.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/mood_feedback/mood_feedback.dart';
import 'package:moodtune_app/features/mood_feedback/presentation/mood_observation_recorder.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/mood_switchover.dart';

import '../../../../helpers/helpers.dart';
import '../../../blocs_fixtures.dart';

class MockMoodSwitchover extends Mock implements MoodSwitchover {}

class MockRecorder extends Mock implements MoodObservationRecorder {}

void main() {
  late MockAnalysisRepository repository;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockAnalysisRepository();
  });

  AnalysisBloc buildBloc() => AnalysisBloc(repository: repository);

  final tUpload = buildUploadAnalysis();
  final tCatalog = buildUploadAnalysis(
    id: 'catalog-1',
    jamendoTrackUrl: 'https://jamendo.com/track/1',
  );
  final tHistory = [
    buildHistoryEntry(id: 'h1', mood: 'Happy'),
    buildHistoryEntry(id: 'h2', mood: 'sad', type: HistoryEntryType.song),
    buildHistoryEntry(id: 'h3', mood: 'happy'),
  ];

  test('initial state is AnalysisState()', () {
    expect(buildBloc().state, const AnalysisState());
  });

  group('AnalyzePlaylistRequested', () {
    blocTest<AnalysisBloc, AnalysisState>(
      'emits [analyzing, success] with the analysis',
      setUp: () => when(
        () => repository.analyzePlaylist('p1', limit: 20),
      ).thenAnswer((_) async => Right(tPlaylistAnalysis)),
      build: buildBloc,
      seed: () => const AnalysisState(error: 'stale'),
      act: (bloc) =>
          bloc.add(const AnalyzePlaylistRequested(playlistId: 'p1', limit: 20)),
      expect: () => [
        const AnalysisState(status: AnalysisStatus.analyzing),
        AnalysisState(
          status: AnalysisStatus.success,
          currentAnalysis: tPlaylistAnalysis,
        ),
      ],
      verify: (_) =>
          verify(() => repository.analyzePlaylist('p1', limit: 20)).called(1),
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'uses default limit of 50 and emits [analyzing, error] on failure',
      setUp: () => when(
        () => repository.analyzePlaylist('p1', limit: 50),
      ).thenAnswer((_) async => const Left(ServerFailure('boom'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AnalyzePlaylistRequested(playlistId: 'p1')),
      expect: () => const [
        AnalysisState(status: AnalysisStatus.analyzing),
        AnalysisState(status: AnalysisStatus.error, error: 'boom'),
      ],
    );
  });

  group('AnalysisHistoryRequested', () {
    blocTest<AnalysisBloc, AnalysisState>(
      'emits loading then history with filter reset',
      setUp: () => when(
        () => repository.getHistory(limit: 10, offset: 5),
      ).thenAnswer((_) async => Right(tHistory)),
      build: buildBloc,
      seed: () =>
          const AnalysisState(historyError: 'old', historyMoodFilter: 'happy'),
      act: (bloc) =>
          bloc.add(const AnalysisHistoryRequested(limit: 10, offset: 5)),
      expect: () => [
        const AnalysisState(historyLoading: true, historyMoodFilter: 'happy'),
        AnalysisState(history: tHistory, filteredHistory: tHistory),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'emits loading then historyError on failure (defaults 50/0)',
      setUp: () => when(
        () => repository.getHistory(limit: 50, offset: 0),
      ).thenAnswer((_) async => const Left(NetworkFailure('offline'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AnalysisHistoryRequested()),
      expect: () => const [
        AnalysisState(historyLoading: true),
        AnalysisState(historyError: 'offline'),
      ],
    );
  });

  group('AnalysisHistoryFilterChanged', () {
    blocTest<AnalysisBloc, AnalysisState>(
      'filters history case-insensitively by mood',
      build: buildBloc,
      seed: () => AnalysisState(history: tHistory, filteredHistory: tHistory),
      act: (bloc) => bloc.add(const AnalysisHistoryFilterChanged('HAPPY')),
      expect: () => [
        AnalysisState(
          history: tHistory,
          filteredHistory: [tHistory[0], tHistory[2]],
          historyMoodFilter: 'HAPPY',
        ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'null mood clears the filter and restores the full list',
      build: buildBloc,
      seed: () => AnalysisState(
        history: tHistory,
        filteredHistory: [tHistory[1]],
        historyMoodFilter: 'sad',
      ),
      act: (bloc) => bloc.add(const AnalysisHistoryFilterChanged(null)),
      expect: () => [
        AnalysisState(history: tHistory, filteredHistory: tHistory),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'empty mood behaves like no filter',
      build: buildBloc,
      seed: () => AnalysisState(
        history: tHistory,
        filteredHistory: [tHistory[1]],
        historyMoodFilter: 'sad',
      ),
      act: (bloc) => bloc.add(const AnalysisHistoryFilterChanged('')),
      expect: () => [
        AnalysisState(
          history: tHistory,
          filteredHistory: tHistory,
          historyMoodFilter: '',
        ),
      ],
    );
  });

  group('AnalysisByIdRequested', () {
    blocTest<AnalysisBloc, AnalysisState>(
      'emits [loading, success]',
      setUp: () => when(
        () => repository.getAnalysisById('a1'),
      ).thenAnswer((_) async => Right(tPlaylistAnalysis)),
      build: buildBloc,
      act: (bloc) => bloc.add(const AnalysisByIdRequested('a1')),
      expect: () => [
        const AnalysisState(status: AnalysisStatus.loading),
        AnalysisState(
          status: AnalysisStatus.success,
          currentAnalysis: tPlaylistAnalysis,
        ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'emits [loading, error] on failure',
      setUp: () => when(
        () => repository.getAnalysisById('a1'),
      ).thenAnswer((_) async => const Left(ServerFailure('not found'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AnalysisByIdRequested('a1')),
      expect: () => const [
        AnalysisState(status: AnalysisStatus.loading),
        AnalysisState(status: AnalysisStatus.error, error: 'not found'),
      ],
    );
  });

  group('AnalyzeSongRequested', () {
    blocTest<AnalysisBloc, AnalysisState>(
      'emits [analyzing, success] with song analysis',
      setUp: () => when(
        () => repository.analyzeSong('t1'),
      ).thenAnswer((_) async => const Right(tSongAnalysis)),
      build: buildBloc,
      act: (bloc) => bloc.add(const AnalyzeSongRequested('t1')),
      expect: () => const [
        AnalysisState(status: AnalysisStatus.analyzing),
        AnalysisState(
          status: AnalysisStatus.success,
          currentSongAnalysis: tSongAnalysis,
        ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'emits [analyzing, error] on failure',
      setUp: () => when(
        () => repository.analyzeSong('t1'),
      ).thenAnswer((_) async => const Left(ServerFailure('song failed'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const AnalyzeSongRequested('t1')),
      expect: () => const [
        AnalysisState(status: AnalysisStatus.analyzing),
        AnalysisState(status: AnalysisStatus.error, error: 'song failed'),
      ],
    );
  });

  group('AudioUploadRequested', () {
    const event = AudioUploadRequested(
      bytes: [1, 2, 3],
      filename: 'song.mp3',
      title: 'T',
      artist: 'A',
      album: 'B',
    );

    void stubUpload(Either<Failure, AudioUploadAnalysis> result) {
      when(
        () => repository.analyzeUploadedAudio(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          title: any(named: 'title'),
          artist: any(named: 'artist'),
          album: any(named: 'album'),
        ),
      ).thenAnswer((_) async => result);
    }

    blocTest<AnalysisBloc, AnalysisState>(
      'emits [uploading, success] and forwards bytes + metadata',
      setUp: () => stubUpload(Right(tUpload)),
      build: buildBloc,
      seed: () => const AnalysisState(uploadError: 'old'),
      act: (bloc) => bloc.add(event),
      expect: () => [
        const AnalysisState(uploadStatus: UploadStatus.uploading),
        AnalysisState(
          uploadStatus: UploadStatus.success,
          currentUploadAnalysis: tUpload,
        ),
      ],
      verify: (_) {
        final captured = verify(
          () => repository.analyzeUploadedAudio(
            bytes: captureAny(named: 'bytes'),
            filename: 'song.mp3',
            title: 'T',
            artist: 'A',
            album: 'B',
          ),
        ).captured;
        expect(captured.single, Uint8List.fromList([1, 2, 3]));
      },
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'emits [uploading, error] on failure',
      setUp: () => stubUpload(const Left(ServerFailure('too large'))),
      build: buildBloc,
      act: (bloc) => bloc.add(event),
      expect: () => const [
        AnalysisState(uploadStatus: UploadStatus.uploading),
        AnalysisState(
          uploadStatus: UploadStatus.error,
          uploadError: 'too large',
        ),
      ],
    );
  });

  group('CatalogTrackAnalyzeRequested', () {
    const event = CatalogTrackAnalyzeRequested(
      audioUrl: 'https://audio',
      trackId: 'j1',
      trackName: 'Track',
      artistName: 'Artist',
      jamendoPageUrl: 'https://jamendo.com/track/1',
    );

    void stubCatalog(Either<Failure, AudioUploadAnalysis> result) {
      when(
        () => repository.analyzeCatalogTrack(
          audioUrl: 'https://audio',
          trackId: 'j1',
          trackName: 'Track',
          artistName: 'Artist',
          jamendoPageUrl: 'https://jamendo.com/track/1',
        ),
      ).thenAnswer((_) async => result);
    }

    blocTest<AnalysisBloc, AnalysisState>(
      'emits [analyzing, success]',
      setUp: () => stubCatalog(Right(tCatalog)),
      build: buildBloc,
      seed: () => const AnalysisState(catalogError: 'old'),
      act: (bloc) => bloc.add(event),
      expect: () => [
        const AnalysisState(catalogStatus: CatalogAnalysisStatus.analyzing),
        AnalysisState(
          catalogStatus: CatalogAnalysisStatus.success,
          currentCatalogAnalysis: tCatalog,
        ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'emits [analyzing, error] on failure',
      setUp: () => stubCatalog(const Left(ServerFailure('jamendo down'))),
      build: buildBloc,
      act: (bloc) => bloc.add(event),
      expect: () => const [
        AnalysisState(catalogStatus: CatalogAnalysisStatus.analyzing),
        AnalysisState(
          catalogStatus: CatalogAnalysisStatus.error,
          catalogError: 'jamendo down',
        ),
      ],
    );
  });

  blocTest<AnalysisBloc, AnalysisState>(
    'AnalysisClearErrorRequested clears all error fields but keeps status',
    build: buildBloc,
    seed: () => const AnalysisState(
      status: AnalysisStatus.error,
      error: 'e',
      historyError: 'h',
      uploadError: 'u',
    ),
    act: (bloc) => bloc.add(const AnalysisClearErrorRequested()),
    expect: () => const [AnalysisState(status: AnalysisStatus.error)],
  );

  group('AnalysisState', () {
    test('copyWith with no args keeps values but drops transient errors', () {
      final state = AnalysisState(
        status: AnalysisStatus.success,
        history: tHistory,
        filteredHistory: tHistory,
        historyMoodFilter: 'happy',
        currentAnalysis: tPlaylistAnalysis,
        currentSongAnalysis: tSongAnalysis,
        currentUploadAnalysis: tUpload,
        error: 'e',
        historyLoading: true,
        historyError: 'h',
        uploadStatus: UploadStatus.success,
        uploadError: 'u',
        catalogStatus: CatalogAnalysisStatus.success,
        currentCatalogAnalysis: tCatalog,
        catalogError: 'c',
      );

      final copy = state.copyWith();

      expect(copy.status, AnalysisStatus.success);
      expect(copy.history, tHistory);
      expect(copy.filteredHistory, tHistory);
      expect(copy.historyMoodFilter, 'happy');
      expect(copy.currentAnalysis, tPlaylistAnalysis);
      expect(copy.currentSongAnalysis, tSongAnalysis);
      expect(copy.currentUploadAnalysis, tUpload);
      expect(copy.historyLoading, isTrue);
      expect(copy.uploadStatus, UploadStatus.success);
      expect(copy.catalogStatus, CatalogAnalysisStatus.success);
      expect(copy.currentCatalogAnalysis, tCatalog);
      expect(copy.error, isNull);
      expect(copy.historyError, isNull);
      expect(copy.uploadError, isNull);
      expect(copy.catalogError, isNull);
    });

    test('copyWith can explicitly set historyMoodFilter to null', () {
      const state = AnalysisState(historyMoodFilter: 'happy');
      expect(state.copyWith(historyMoodFilter: null).historyMoodFilter, isNull);
      expect(state.copyWith(historyMoodFilter: 'sad').historyMoodFilter, 'sad');
    });

    test('props distinguish differing states', () {
      expect(const AnalysisState(), const AnalysisState());
      expect(
        const AnalysisState(),
        isNot(const AnalysisState(catalogError: 'x')),
      );
      expect(const AnalysisState().props, hasLength(17));
    });
  });

  group('AnalysisEvent props', () {
    test('value equality', () {
      expect(
        const AnalyzePlaylistRequested(playlistId: 'a'),
        const AnalyzePlaylistRequested(playlistId: 'a'),
      );
      expect(const AnalyzePlaylistRequested(playlistId: 'a').props, ['a', 50]);
      expect(const AnalysisHistoryRequested().props, [50, 0]);
      expect(const AnalysisHistoryFilterChanged('x').props, ['x']);
      expect(const AnalysisByIdRequested('id').props, ['id']);
      expect(const AnalysisClearErrorRequested().props, isEmpty);
      expect(const AnalyzeSongRequested('t').props, ['t']);
      expect(
        const CatalogTrackAnalyzeRequested(
          audioUrl: 'u',
          trackId: 'i',
          trackName: 'n',
          artistName: 'a',
          jamendoPageUrl: 'p',
        ).props,
        ['u', 'i', 'n', 'a', 'p'],
      );
      expect(const AudioUploadRequested(bytes: [1], filename: 'f').props, [
        [1],
        'f',
        null,
        null,
        null,
        null,
      ]);
    });
  });

  group('on-device switchover', () {
    late MockMoodSwitchover switchover;
    const onDeviceMood = OnDeviceMood(
      primaryMood: 'sad',
      probabilities: {'sad': 0.9, 'energetic': 0.1},
      tags: ['piano'],
    );
    const attempt = OnDeviceMoodAttempt(
      mood: onDeviceMood,
      elapsed: Duration(milliseconds: 80),
    );
    const upload = AudioUploadRequested(
      bytes: [1],
      filename: 'song.mp3',
      path: '/tmp/song.mp3',
    );
    const catalog = CatalogTrackAnalyzeRequested(
      audioUrl: 'https://audio',
      trackId: 'j1',
      trackName: 'Track',
      artistName: 'Artist',
      jamendoPageUrl: 'https://jamendo.com/track/1',
    );

    setUp(() {
      switchover = MockMoodSwitchover();
      when(
        () => repository.analyzeUploadedAudio(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          title: any(named: 'title'),
          artist: any(named: 'artist'),
          album: any(named: 'album'),
        ),
      ).thenAnswer((_) async => Right(tUpload));
      when(
        () => repository.analyzeCatalogTrack(
          audioUrl: any(named: 'audioUrl'),
          trackId: any(named: 'trackId'),
          trackName: any(named: 'trackName'),
          artistName: any(named: 'artistName'),
          jamendoPageUrl: any(named: 'jamendoPageUrl'),
        ),
      ).thenAnswer((_) async => Right(tCatalog));
    });

    AnalysisBloc buildWithSwitchover({
      Duration grace = const Duration(seconds: 3),
    }) => AnalysisBloc(
      repository: repository,
      switchover: switchover,
      onDeviceGrace: grace,
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'shows the on-device mood for an upload with a file path',
      setUp: () => when(
        () => switchover.classifyFile('/tmp/song.mp3'),
      ).thenAnswer((_) async => attempt),
      build: buildWithSwitchover,
      act: (bloc) => bloc.add(upload),
      skip: 1,
      expect: () => [
        AnalysisState(
          uploadStatus: UploadStatus.success,
          currentUploadAnalysis: MoodSwitchover.apply(tUpload, attempt),
          onDeviceAttempt: attempt,
        ),
      ],
      verify: (bloc) {
        final mood = bloc.state.currentUploadAnalysis!.mood;
        expect(mood.primaryMood, 'sad');
        expect(mood.backendPrimaryMood, tUpload.mood.primaryMood);
      },
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'keeps the backend mood when the upload has no file path',
      build: buildWithSwitchover,
      act: (bloc) => bloc.add(
        const AudioUploadRequested(bytes: [1], filename: 'song.mp3'),
      ),
      skip: 1,
      expect: () => [
        AnalysisState(
          uploadStatus: UploadStatus.success,
          currentUploadAnalysis: tUpload,
        ),
      ],
      verify: (_) => verifyNever(() => switchover.classifyFile(any())),
    );

    blocTest<AnalysisBloc, AnalysisState>(
      "shows the backend mood when on-device isn't ready in time",
      setUp: () => when(() => switchover.classifyFile(any())).thenAnswer(
        (_) => Future.delayed(const Duration(milliseconds: 200), () => attempt),
      ),
      build: () => buildWithSwitchover(grace: const Duration(milliseconds: 10)),
      act: (bloc) => bloc.add(upload),
      wait: const Duration(milliseconds: 50),
      skip: 1,
      expect: () => [
        AnalysisState(
          uploadStatus: UploadStatus.success,
          currentUploadAnalysis: tUpload,
          onDeviceAttempt: const OnDeviceMoodAttempt(
            elapsed: Duration(milliseconds: 10),
            failure: 'late',
          ),
        ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'shows the on-device mood for a catalog track',
      setUp: () => when(
        () => switchover.classifyUrl('https://audio'),
      ).thenAnswer((_) async => attempt),
      build: buildWithSwitchover,
      act: (bloc) => bloc.add(catalog),
      skip: 1,
      expect: () => [
        AnalysisState(
          catalogStatus: CatalogAnalysisStatus.success,
          currentCatalogAnalysis: MoodSwitchover.apply(tCatalog, attempt),
          onDeviceAttempt: attempt,
        ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'records the result and exposes the observation id',
      setUp: () {
        when(
          () => switchover.classifyFile(any()),
        ).thenAnswer((_) async => attempt);
      },
      build: () {
        final recorder = MockRecorder();
        when(
          () => recorder.record(
            source: MoodObservationSource.upload,
            backendMood: tUpload.mood.primaryMood,
            displayed: MoodSwitchover.apply(tUpload, attempt),
            attempt: attempt,
          ),
        ).thenReturn('obs-1');
        return AnalysisBloc(
          repository: repository,
          switchover: switchover,
          recorder: recorder,
        );
      },
      act: (bloc) => bloc.add(upload),
      skip: 1,
      expect: () => [
        AnalysisState(
          uploadStatus: UploadStatus.success,
          currentUploadAnalysis: MoodSwitchover.apply(tUpload, attempt),
          onDeviceAttempt: attempt,
          observationId: 'obs-1',
        ),
      ],
    );

    blocTest<AnalysisBloc, AnalysisState>(
      'still reports a backend failure as an error',
      setUp: () {
        when(
          () => switchover.classifyFile(any()),
        ).thenAnswer((_) async => attempt);
        when(
          () => repository.analyzeUploadedAudio(
            bytes: any(named: 'bytes'),
            filename: any(named: 'filename'),
            title: any(named: 'title'),
            artist: any(named: 'artist'),
            album: any(named: 'album'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('down')));
      },
      build: buildWithSwitchover,
      act: (bloc) => bloc.add(upload),
      skip: 1,
      expect: () => const [
        AnalysisState(uploadStatus: UploadStatus.error, uploadError: 'down'),
      ],
    );
  });
}
