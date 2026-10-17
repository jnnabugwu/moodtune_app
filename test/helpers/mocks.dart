import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_target.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_card_renderer.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_repository.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockAnalysisBloc extends MockBloc<AnalysisEvent, AnalysisState>
    implements AnalysisBloc {}

class MockSpotifyBloc extends MockBloc<SpotifyEvent, SpotifyState>
    implements SpotifyBloc {}

class MockCatalogBloc extends MockBloc<CatalogEvent, CatalogState>
    implements CatalogBloc {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAnalysisRepository extends Mock implements AnalysisRepository {}

class MockSpotifyRepository extends Mock implements SpotifyRepository {}

class MockCatalogRepository extends Mock implements CatalogRepository {}

class MockShareRepository extends Mock implements ShareRepository {}

class MockShareCardRenderer extends Mock implements ShareCardRenderer {}

/// Registers mocked sharing services in GetIt so pages that open the share
/// sheet (`ResultsPage`, `HistoryPage`) can be pumped. Returns them for
/// stubbing. Unregisters on tear-down.
({MockShareRepository repository, MockShareCardRenderer renderer})
registerSharingMocks() {
  registerFallbackValue(ShareTarget.system);
  final repository = MockShareRepository();
  final renderer = MockShareCardRenderer();
  when(() => repository.isAvailable(any())).thenAnswer((_) async => true);
  GetIt.instance
    ..registerSingleton<ShareRepository>(repository)
    ..registerSingleton<ShareCardRenderer>(renderer);
  addTearDown(() async {
    await GetIt.instance.unregister<ShareRepository>();
    await GetIt.instance.unregister<ShareCardRenderer>();
  });
  return (repository: repository, renderer: renderer);
}

MockAuthBloc mockAuthBloc([AuthState state = const AuthState()]) {
  final bloc = MockAuthBloc();
  when(() => bloc.state).thenReturn(state);
  return bloc;
}

MockAnalysisBloc mockAnalysisBloc([
  AnalysisState state = const AnalysisState(),
]) {
  final bloc = MockAnalysisBloc();
  when(() => bloc.state).thenReturn(state);
  return bloc;
}

MockSpotifyBloc mockSpotifyBloc([SpotifyState state = const SpotifyState()]) {
  final bloc = MockSpotifyBloc();
  when(() => bloc.state).thenReturn(state);
  return bloc;
}

MockCatalogBloc mockCatalogBloc([CatalogState state = const CatalogInitial()]) {
  final bloc = MockCatalogBloc();
  when(() => bloc.state).thenReturn(state);
  return bloc;
}
