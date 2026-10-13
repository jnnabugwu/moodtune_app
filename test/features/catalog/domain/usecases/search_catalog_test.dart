import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';
import 'package:moodtune_app/features/catalog/domain/usecases/search_catalog.dart';

import '../../../../helpers/helpers.dart';
import '../../catalog_fixtures.dart';

void main() {
  late MockCatalogRepository repository;
  late SearchCatalog usecase;

  setUp(() {
    repository = MockCatalogRepository();
    usecase = SearchCatalog(repository);
  });

  test('forwards query and mood tag to the repository', () async {
    final tracks = [buildJamendoTrack()];
    when(
      () => repository.searchTracks(query: 'jazz', moodTag: 'serene'),
    ).thenAnswer((_) async => Right(tracks));

    final result = await usecase(query: 'jazz', moodTag: 'serene');

    expect(result, Right<Failure, List<JamendoTrack>>(tracks));
    verify(
      () => repository.searchTracks(query: 'jazz', moodTag: 'serene'),
    ).called(1);
  });

  test('passes failures through unchanged', () async {
    when(
      () => repository.searchTracks(),
    ).thenAnswer((_) async => const Left(ServerFailure('down')));

    expect(
      await usecase(),
      const Left<Failure, List<JamendoTrack>>(ServerFailure('down')),
    );
  });
}
