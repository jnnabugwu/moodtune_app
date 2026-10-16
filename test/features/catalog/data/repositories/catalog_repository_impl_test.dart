import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/exceptions.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/catalog/data/datasources/jamendo_remote_datasource.dart';
import 'package:moodtune_app/features/catalog/data/models/jamendo_track_model.dart';
import 'package:moodtune_app/features/catalog/data/repositories/catalog_repository_impl.dart';

import '../../catalog_fixtures.dart';

class _MockJamendoRemoteDataSource extends Mock
    implements JamendoRemoteDataSource {}

void main() {
  late _MockJamendoRemoteDataSource dataSource;
  late CatalogRepositoryImpl repository;

  setUp(() {
    dataSource = _MockJamendoRemoteDataSource();
    repository = CatalogRepositoryImpl(dataSource: dataSource);
  });

  void stubSearch(Future<List<JamendoTrackModel>> Function() answer) {
    when(
      () => dataSource.searchTracks(
        query: any(named: 'query'),
        moodTag: any(named: 'moodTag'),
      ),
    ).thenAnswer((_) => answer());
  }

  test('filters out non-downloadable tracks and maps to domain', () async {
    final allowed = JamendoTrackModel.fromJson(buildJamendoJson());
    final blocked = JamendoTrackModel.fromJson(
      buildJamendoJson(id: 2, audiodownloadAllowed: 0),
    );
    stubSearch(() async => [allowed, blocked]);

    final result = await repository.searchTracks(query: 'q', moodTag: 'm');

    final tracks = result.getOrElse(() => throw StateError('expected Right'));
    expect(tracks, [allowed.toDomain()]);
    verify(() => dataSource.searchTracks(query: 'q', moodTag: 'm')).called(1);
  });

  test('maps ServerException to ServerFailure with its message', () async {
    stubSearch(() async => throw const ServerException('jamendo 500'));

    expect(
      await repository.searchTracks(query: 'q'),
      isA<Left<Failure, dynamic>>().having(
        (l) => l.fold((f) => f, (_) => null),
        'failure',
        const ServerFailure('jamendo 500'),
      ),
    );
  });

  test('maps other exceptions to ServerFailure(toString)', () async {
    final error = Exception('weird');
    stubSearch(() async => throw error);

    final result = await repository.searchTracks();

    expect(result.fold((f) => f, (_) => null), ServerFailure(error.toString()));
  });

  test('returns empty Right when nothing is downloadable', () async {
    stubSearch(
      () async => [
        JamendoTrackModel.fromJson(buildJamendoJson(audiodownloadAllowed: 0)),
      ],
    );
    final result = await repository.searchTracks(moodTag: 'serene');
    expect(result.isRight(), isTrue);
    expect(result.getOrElse(() => throw StateError('')), isEmpty);
  });
}
