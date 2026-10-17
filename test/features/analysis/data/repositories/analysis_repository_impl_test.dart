import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/analysis/data/datasources/analysis_datasource.dart';
import 'package:moodtune_app/features/analysis/data/datasources/audio_upload_datasource.dart';
import 'package:moodtune_app/features/analysis/data/repositories/analysis_repository_impl.dart';
import 'package:moodtune_app/features/analysis/domain/entities/entities.dart';
import 'package:moodtune_app/features/analysis/domain/repositories/analysis_repository.dart';

import '../analysis_data_fixtures.dart';

class _MockAnalysisRemote extends Mock implements AnalysisRemoteDataSource {}

class _MockUploadRemote extends Mock implements AudioUploadRemoteDataSource {}

DioException _dioError({
  DioExceptionType type = DioExceptionType.badResponse,
  Object? data,
  String? message,
  int statusCode = 500,
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: type,
    message: message,
    response: data == null
        ? null
        : Response<Object?>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
  );
}

Failure _leftOf<T>(Either<Failure, T> either) =>
    either.fold((f) => f, (r) => fail('expected Left but got Right($r)'));

T _rightOf<T>(Either<Failure, T> either) =>
    either.fold((f) => fail('expected Right but got Left($f)'), (r) => r);

void main() {
  late _MockAnalysisRemote remote;
  late _MockUploadRemote uploadRemote;
  late AnalysisRepositoryImpl repo;

  setUp(() {
    remote = _MockAnalysisRemote();
    uploadRemote = _MockUploadRemote();
    repo = AnalysisRepositoryImpl(
      remoteDataSource: remote,
      uploadRemoteDataSource: uploadRemote,
    );
  });

  test('is an AnalysisRepository and builds default datasources', () {
    expect(AnalysisRepositoryImpl(), isA<AnalysisRepository>());
  });

  group('analyzePlaylist', () {
    test('returns mapped PlaylistAnalysis on success', () async {
      when(
        () => remote.analyzePlaylist('pl-1', limit: 50),
      ).thenAnswer((_) async => playlistAnalysisJson());

      final analysis = _rightOf(await repo.analyzePlaylist('pl-1'));

      expect(analysis.id, 'analysis-1');
      expect(analysis.playlistName, 'Road Trip');
      expect(analysis.moodResult.primaryMood, 'Happy');
      expect(analysis.moodResult.topTracks, hasLength(2));
    });

    test('forwards a custom limit', () async {
      when(
        () => remote.analyzePlaylist(any(), limit: any(named: 'limit')),
      ).thenAnswer((_) async => playlistAnalysisJson());

      await repo.analyzePlaylist('pl-1', limit: 7);

      verify(() => remote.analyzePlaylist('pl-1', limit: 7)).called(1);
    });

    test('maps DioException to a Failure', () async {
      when(
        () => remote.analyzePlaylist(any(), limit: any(named: 'limit')),
      ).thenThrow(_dioError(data: {'detail': 'Playlist not found'}));

      expect(
        _leftOf(await repo.analyzePlaylist('pl')),
        const ServerFailure('Playlist not found'),
      );
    });

    test('maps other exceptions to ServerFailure(toString)', () async {
      when(
        () => remote.analyzePlaylist(any(), limit: any(named: 'limit')),
      ).thenThrow(const CacheException('bad'));

      expect(
        _leftOf(await repo.analyzePlaylist('pl')),
        const ServerFailure('CacheException: bad'),
      );
    });
  });

  group('getHistory', () {
    test('reads song history and maps it to HistoryEntry', () async {
      when(() => remote.getSongHistory(limit: 50, offset: 0)).thenAnswer(
        (_) async => [songHistoryJson(), songHistoryJson(id: 'sh-2')],
      );

      final entries = _rightOf(await repo.getHistory());

      expect(entries.map((e) => e.id), ['sh-1', 'sh-2']);
      expect(entries.first.type, HistoryEntryType.song);
      expect(entries.first.title, 'Song');
      expect(entries.first.subtitle, 'Singer');
      expect(entries.first.primaryMood, 'Sad');
    });

    test('returns entries newest first', () async {
      when(() => remote.getSongHistory(limit: 50, offset: 0)).thenAnswer(
        (_) async => [
          songHistoryJson(id: 'old', createdAt: '2025-01-01T00:00:00.000Z'),
          songHistoryJson(id: 'new', createdAt: '2025-03-01T00:00:00.000Z'),
          songHistoryJson(id: 'mid', createdAt: '2025-02-01T00:00:00.000Z'),
        ],
      );

      final entries = _rightOf(await repo.getHistory());

      expect(entries.map((e) => e.id), ['new', 'mid', 'old']);
    });

    test('forwards limit and offset', () async {
      when(
        () => remote.getSongHistory(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => []);

      final entries = _rightOf(await repo.getHistory(limit: 5, offset: 10));

      expect(entries, isEmpty);
      verify(() => remote.getSongHistory(limit: 5, offset: 10)).called(1);
    });

    test('maps DioException to a Failure', () async {
      when(
        () => remote.getSongHistory(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(_dioError(type: DioExceptionType.connectionTimeout));

      expect(_leftOf(await repo.getHistory()), isA<NetworkFailure>());
    });

    test('maps other exceptions to ServerFailure', () async {
      when(
        () => remote.getSongHistory(
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenThrow(Exception('oops'));

      expect(
        _leftOf(await repo.getHistory()),
        const ServerFailure('Exception: oops'),
      );
    });
  });

  group('getAnalysisById', () {
    test('returns mapped PlaylistAnalysis on success', () async {
      when(
        () => remote.getAnalysisById('a-1'),
      ).thenAnswer((_) async => playlistAnalysisJson());

      final analysis = _rightOf(await repo.getAnalysisById('a-1'));

      expect(analysis.playlistId, 'pl-1');
      expect(analysis.userId, 'user-1');
    });

    test('maps DioException to a Failure', () async {
      when(
        () => remote.getAnalysisById(any()),
      ).thenThrow(_dioError(data: {'message': 'gone'}, statusCode: 404));

      expect(
        _leftOf(await repo.getAnalysisById('a')),
        const ServerFailure('gone'),
      );
    });

    test('maps other exceptions to ServerFailure', () async {
      when(
        () => remote.getAnalysisById(any()),
      ).thenThrow(const ServerException('down'));

      expect(
        _leftOf(await repo.getAnalysisById('a')),
        const ServerFailure('ServerException: down'),
      );
    });
  });

  group('analyzeSong', () {
    test('returns mapped SongAnalysisResult on success', () async {
      when(
        () => remote.analyzeSong('trk-1'),
      ).thenAnswer((_) async => songAnalysisJson());

      final result = _rightOf(await repo.analyzeSong('trk-1'));

      expect(result.trackName, 'Song');
      expect(result.mood.primaryMood, 'Calm');
      expect(result.features.loudness, -7.5);
      expect(result.success, isTrue);
    });

    test('maps DioException to a Failure', () async {
      when(
        () => remote.analyzeSong(any()),
      ).thenThrow(_dioError(type: DioExceptionType.connectionError));

      expect(
        _leftOf(await repo.analyzeSong('t')),
        const NetworkFailure('Network error'),
      );
    });

    test('maps other exceptions to ServerFailure', () async {
      when(
        () => remote.analyzeSong(any()),
      ).thenThrow(const FormatException('bad json'));

      expect(
        _leftOf(await repo.analyzeSong('t')),
        const ServerFailure('FormatException: bad json'),
      );
    });

    test('lets TypeErrors from malformed payloads escape', () async {
      // Documents current behaviour: only `Exception`s are caught, so a
      // payload with a wrongly-typed field throws instead of returning Left.
      when(
        () => remote.analyzeSong(any()),
      ).thenAnswer((_) async => {'track_name': 42});

      await expectLater(repo.analyzeSong('t'), throwsA(isA<TypeError>()));
    });
  });

  group('analyzeUploadedAudio', () {
    final bytes = Uint8List.fromList([1, 2, 3]);

    test('forwards all arguments and maps the response', () async {
      when(
        () => uploadRemote.uploadAndAnalyzeAudio(
          bytes: bytes,
          filename: 'song.mp3',
          title: 'T',
          artist: 'A',
          album: 'Al',
        ),
      ).thenAnswer((_) async => audioUploadJson());

      final analysis = _rightOf(
        await repo.analyzeUploadedAudio(
          bytes: bytes,
          filename: 'song.mp3',
          title: 'T',
          artist: 'A',
          album: 'Al',
        ),
      );

      expect(analysis.id, 'up-1');
      expect(analysis.mood.primaryMood, 'Energetic');
      expect(analysis.mood.audioFeatures.tempo, 128);
      verify(
        () => uploadRemote.uploadAndAnalyzeAudio(
          bytes: bytes,
          filename: 'song.mp3',
          title: 'T',
          artist: 'A',
          album: 'Al',
        ),
      ).called(1);
    });

    test('maps DioException to a Failure', () async {
      when(
        () => uploadRemote.uploadAndAnalyzeAudio(
          bytes: bytes,
          filename: any(named: 'filename'),
        ),
      ).thenThrow(
        _dioError(data: {'detail': 'Unsupported format'}, statusCode: 415),
      );

      expect(
        _leftOf(await repo.analyzeUploadedAudio(bytes: bytes, filename: 'x')),
        const ServerFailure('Unsupported format'),
      );
    });

    test('maps other exceptions to ServerFailure', () async {
      when(
        () => uploadRemote.uploadAndAnalyzeAudio(
          bytes: bytes,
          filename: any(named: 'filename'),
        ),
      ).thenThrow(Exception('disk'));

      expect(
        _leftOf(await repo.analyzeUploadedAudio(bytes: bytes, filename: 'x')),
        const ServerFailure('Exception: disk'),
      );
    });
  });

  group('analyzeCatalogTrack', () {
    Future<Either<Failure, AudioUploadAnalysis>> call() =>
        repo.analyzeCatalogTrack(
          audioUrl: 'https://cdn/a.mp3',
          trackId: 'j1',
          trackName: 'Name',
          artistName: 'Artist',
          jamendoPageUrl: 'https://jamendo/j1',
        );

    void stub(Future<Map<String, dynamic>> Function(Invocation) answer) {
      when(
        () => uploadRemote.analyzeCatalogTrack(
          audioUrl: any(named: 'audioUrl'),
          trackId: any(named: 'trackId'),
          trackName: any(named: 'trackName'),
          artistName: any(named: 'artistName'),
          jamendoPageUrl: any(named: 'jamendoPageUrl'),
        ),
      ).thenAnswer(answer);
    }

    test('forwards all arguments and maps the response', () async {
      stub((_) async => audioUploadJson());

      final analysis = _rightOf(await call());

      expect(analysis.jamendoTrackUrl, 'https://jamendo.com/track/1');
      expect(analysis.analysisMethod, 'catalog');
      verify(
        () => uploadRemote.analyzeCatalogTrack(
          audioUrl: 'https://cdn/a.mp3',
          trackId: 'j1',
          trackName: 'Name',
          artistName: 'Artist',
          jamendoPageUrl: 'https://jamendo/j1',
        ),
      ).called(1);
    });

    test('maps DioException to a Failure', () async {
      stub((_) async => throw _dioError(type: DioExceptionType.receiveTimeout));

      expect(_leftOf(await call()), const NetworkFailure('Network error'));
    });

    test('maps other exceptions to ServerFailure', () async {
      stub((_) async => throw const ServerException('nope'));

      expect(
        _leftOf(await call()),
        const ServerFailure('ServerException: nope'),
      );
    });
  });

  group('DioException mapping', () {
    Future<Failure> mapped(DioException e) async {
      when(() => remote.analyzeSong(any())).thenThrow(e);
      return _leftOf(await repo.analyzeSong('t'));
    }

    test('prefers detail over message in a Map body', () async {
      expect(
        await mapped(_dioError(data: {'detail': 'D', 'message': 'M'})),
        const ServerFailure('D'),
      );
    });

    test('falls back to body message when detail is null', () async {
      expect(
        await mapped(_dioError(data: {'detail': null, 'message': 'M'})),
        const ServerFailure('M'),
      );
    });

    test('stringifies non-string detail values', () async {
      expect(
        await mapped(
          _dioError(
            data: {
              'detail': [
                {'msg': 'field required'},
              ],
            },
            statusCode: 422,
          ),
        ),
        const ServerFailure('[{msg: field required}]'),
      );
    });

    test('falls back to DioException.message when body has neither', () async {
      expect(
        await mapped(_dioError(data: {'error': 'x'}, message: 'Http 500')),
        const ServerFailure('Http 500'),
      );
    });

    test('ignores non-Map bodies and uses DioException.message', () async {
      expect(
        await mapped(_dioError(data: 'Internal Server Error', message: 'm')),
        const ServerFailure('m'),
      );
    });

    test('defaults to "Server error" when there is no message', () async {
      expect(await mapped(_dioError()), const ServerFailure('Server error'));
    });

    for (final type in [
      DioExceptionType.connectionError,
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
    ]) {
      test('$type maps to NetworkFailure', () async {
        expect(
          await mapped(_dioError(type: type, message: 'conn')),
          const NetworkFailure('conn'),
        );
      });
    }

    test('network failure still prefers the body detail', () async {
      expect(
        await mapped(
          _dioError(
            type: DioExceptionType.receiveTimeout,
            data: {'detail': 'slow'},
          ),
        ),
        const NetworkFailure('slow'),
      );
    });

    for (final type in [
      DioExceptionType.sendTimeout,
      DioExceptionType.cancel,
      DioExceptionType.badCertificate,
      DioExceptionType.unknown,
    ]) {
      test('$type maps to ServerFailure', () async {
        expect(
          await mapped(_dioError(type: type)),
          const ServerFailure('Server error'),
        );
      });
    }
  });
}
