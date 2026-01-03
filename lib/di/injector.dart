import 'package:get_it/get_it.dart';
import 'package:moodtune_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';
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
    // Use cases
    ..registerLazySingleton(() => GetAuthorizeUrl(getIt()))
    ..registerLazySingleton(() => ConnectSpotify(getIt()))
    ..registerLazySingleton(() => CheckSpotifyConnection(getIt()))
    ..registerLazySingleton(() => GetSpotifyProfile(getIt()))
    ..registerLazySingleton(() => DisconnectSpotify(getIt()));
}
