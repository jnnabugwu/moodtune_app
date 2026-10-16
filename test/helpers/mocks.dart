import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
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
