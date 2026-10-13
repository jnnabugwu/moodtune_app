import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/catalog/domain/usecases/search_catalog.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';

import '../../../../helpers/helpers.dart';
import '../../catalog_fixtures.dart';

void main() {
  late MockCatalogRepository repository;

  const debounce = Duration(milliseconds: 350);
  final tracks = [buildJamendoTrack(), buildJamendoTrack(id: '2')];

  setUp(() {
    repository = MockCatalogRepository();
  });

  CatalogBloc buildBloc() =>
      CatalogBloc(searchCatalog: SearchCatalog(repository));

  test('initial state is CatalogInitial', () {
    expect(buildBloc().state, const CatalogInitial());
  });

  group('CatalogSearchRequested', () {
    blocTest<CatalogBloc, CatalogState>(
      'emits [loading, loaded] after the debounce',
      setUp: () => when(
        () => repository.searchTracks(query: 'jazz', moodTag: 'serene'),
      ).thenAnswer((_) async => Right(tracks)),
      build: buildBloc,
      act: (bloc) => bloc.add(
        const CatalogSearchRequested(query: 'jazz', moodTag: 'serene'),
      ),
      wait: debounce,
      expect: () => [const CatalogLoading(), CatalogLoaded(tracks)],
    );

    blocTest<CatalogBloc, CatalogState>(
      'emits [loading, error] on failure',
      setUp: () => when(
        () => repository.searchTracks(moodTag: 'charged'),
      ).thenAnswer((_) async => const Left(ServerFailure('jamendo down'))),
      build: buildBloc,
      act: (bloc) => bloc.add(const CatalogSearchRequested(moodTag: 'charged')),
      wait: debounce,
      expect: () => const [CatalogLoading(), CatalogError('jamendo down')],
    );

    blocTest<CatalogBloc, CatalogState>(
      'emits CatalogInitial without searching when query and mood are empty',
      build: buildBloc,
      seed: () => CatalogLoaded(tracks),
      act: (bloc) =>
          bloc.add(const CatalogSearchRequested(query: '', moodTag: '')),
      wait: debounce,
      expect: () => const [CatalogInitial()],
      verify: (_) => verifyNever(
        () => repository.searchTracks(
          query: any(named: 'query'),
          moodTag: any(named: 'moodTag'),
        ),
      ),
    );

    blocTest<CatalogBloc, CatalogState>(
      'emits CatalogInitial when query and mood are null',
      build: buildBloc,
      seed: () => const CatalogError('x'),
      act: (bloc) => bloc.add(const CatalogSearchRequested()),
      wait: debounce,
      expect: () => const [CatalogInitial()],
    );

    blocTest<CatalogBloc, CatalogState>(
      'debounces rapid events and only searches the last one',
      setUp: () => when(
        () => repository.searchTracks(
          query: any(named: 'query'),
          moodTag: any(named: 'moodTag'),
        ),
      ).thenAnswer((_) async => Right(tracks)),
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CatalogSearchRequested(query: 'j'))
        ..add(const CatalogSearchRequested(query: 'ja'))
        ..add(const CatalogSearchRequested(query: 'jazz')),
      wait: debounce,
      expect: () => [const CatalogLoading(), CatalogLoaded(tracks)],
      verify: (_) {
        verify(() => repository.searchTracks(query: 'jazz')).called(1);
        verifyNever(() => repository.searchTracks(query: 'j'));
        verifyNever(() => repository.searchTracks(query: 'ja'));
      },
    );
  });

  blocTest<CatalogBloc, CatalogState>(
    'CatalogCleared resets to CatalogInitial immediately',
    build: buildBloc,
    seed: () => CatalogLoaded(tracks),
    act: (bloc) => bloc.add(const CatalogCleared()),
    expect: () => const [CatalogInitial()],
  );

  group('states and events', () {
    test('state props', () {
      expect(const CatalogInitial().props, isEmpty);
      expect(const CatalogLoading().props, isEmpty);
      expect(CatalogLoaded(tracks).props, [tracks]);
      expect(const CatalogError('m').props, ['m']);
      expect(const CatalogError('a'), isNot(const CatalogError('b')));
    });

    test('event props', () {
      expect(
        const CatalogSearchRequested(query: 'q', moodTag: 'm').props,
        ['q', 'm'],
      );
      // Non-const on purpose: exercises the runtime constructor.
      // ignore: prefer_const_constructors
      expect(CatalogCleared(), const CatalogCleared());
      expect(const CatalogCleared().props, isEmpty);
    });
  });
}
