import 'package:get_it/get_it.dart';
import 'package:moodtune_app/features/analysis/data/data.dart';
import 'package:moodtune_app/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:moodtune_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:moodtune_app/features/catalog/data/datasources/jamendo_remote_datasource.dart';
import 'package:moodtune_app/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:moodtune_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:moodtune_app/features/catalog/domain/usecases/search_catalog.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:moodtune_app/features/spotify/data/data.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/features/spotify/domain/usecases/usecases.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies({
  String apiBaseUrl = SpotifyRepositoryImpl.defaultBaseUrl,
  TokenProvider? tokenProvider,
}) async {
  // Repositories
  getIt
    ..registerLazySingleton<AuthRepository>(
      AuthRepositoryImpl.new,
    )
    ..registerLazySingleton<SpotifyRepository>(
      () => SpotifyRepositoryImpl(
        baseUrl: apiBaseUrl,
        tokenProvider: tokenProvider,
      ),
    )
    ..registerLazySingleton<AnalysisRepository>(
      () => AnalysisRepositoryImpl(
        remoteDataSource: AnalysisRemoteDataSource(
          baseUrl: apiBaseUrl,
          tokenProvider: tokenProvider,
        ),
        uploadRemoteDataSource: AudioUploadRemoteDataSource(
          baseUrl: apiBaseUrl,
        ),
      ),
    )
    ..registerLazySingleton<CatalogRepository>(
      () => CatalogRepositoryImpl(
        dataSource: JamendoRemoteDataSource(
          // Injected via --dart-define-from-file=.env
          clientId: const String.fromEnvironment('JAMENDO_CLIENT_ID'),
        ),
      ),
    )
    // Catalog use cases
    ..registerLazySingleton(() => SearchCatalog(getIt()))
    // Catalog BLoC — factory so each screen gets a fresh instance
    ..registerFactory(() => CatalogBloc(searchCatalog: getIt()))
    // Spotify use cases
    ..registerLazySingleton(() => GetAuthorizeUrl(getIt()))
    ..registerLazySingleton(() => ConnectSpotify(getIt()))
    ..registerLazySingleton(() => CheckSpotifyConnection(getIt()))
    ..registerLazySingleton(() => GetSpotifyProfile(getIt()))
    ..registerLazySingleton(() => GetPlaylists(getIt()))
    ..registerLazySingleton(() => DisconnectSpotify(getIt()));
}
