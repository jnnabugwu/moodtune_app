import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/analysis/domain/domain.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';

import '../../../../helpers/helpers.dart';
import '../../../blocs_fixtures.dart';

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
      verify: (_) => verify(
        () => repository.analyzePlaylist('p1', limit: 20),
      ).called(1),
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
      seed: () => const AnalysisState(
        historyError: 'old',
        historyMoodFilter: 'happy',
      ),
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
      expect(const AnalysisState().props, hasLength(15));
    });
  });

  group('AnalysisEvent props', () {
    test('value equality', () {
      expect(
        const AnalyzePlaylistRequested(playlistId: 'a'),
        const AnalyzePlaylistRequested(playlistId: 'a'),
      );
      expect(
        const AnalyzePlaylistRequested(playlistId: 'a').props,
        ['a', 50],
      );
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
      expect(
        const AudioUploadRequested(bytes: [1], filename: 'f').props,
        [
          [1],
          'f',
          null,
          null,
          null,
        ],
      );
    });
  });
}
