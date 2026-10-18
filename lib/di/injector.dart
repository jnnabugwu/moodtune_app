import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:moodtune_app/features/analysis/data/data.dart';
import 'package:moodtune_app/features/analysis/domain/repositories/analysis_repository.dart';
import 'package:moodtune_app/features/analysis/presentation/engine_comparison.dart';
import 'package:moodtune_app/features/auth/data/datasources/account_remote_datasource.dart';
import 'package:moodtune_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:moodtune_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:moodtune_app/features/catalog/data/datasources/jamendo_remote_datasource.dart';
import 'package:moodtune_app/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:moodtune_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:moodtune_app/features/catalog/domain/usecases/search_catalog.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:moodtune_app/features/mood_feedback/mood_feedback.dart';
import 'package:moodtune_app/features/mood_feedback/presentation/mood_observation_recorder.dart';
import 'package:moodtune_app/features/narration/data/mood_narration_channel.dart';
import 'package:moodtune_app/features/narration/presentation/mood_narrator.dart';
import 'package:moodtune_app/features/on_device_mood/data/audio_decode_channel.dart';
import 'package:moodtune_app/features/on_device_mood/data/dio_audio_downloader.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_assets.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_engine.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/mood_switchover.dart';
import 'package:moodtune_app/features/on_device_mood/presentation/on_device_mood_classifier.dart';
import 'package:moodtune_app/features/sharing/data/repositories/share_repository_impl.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_card_renderer.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_repository.dart';
import 'package:moodtune_app/features/sharing/presentation/mood_share_card_renderer.dart';
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
      () => AuthRepositoryImpl(
        accountDataSource: AccountRemoteDataSource(
          baseUrl: apiBaseUrl,
          tokenProvider: tokenProvider,
        ),
        clearLocalData: () => getIt<EngineComparisonPreference>().clear(),
      ),
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
          tokenProvider: tokenProvider,
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
    ..registerLazySingleton(() => MoodNarrator(engine: MoodNarrationChannel()))
    ..registerLazySingleton(EngineComparisonPreference.new)
    ..registerLazySingleton(
      () => OnDeviceMoodClassifier(
        decoder: AudioDecodeChannel(),
        engine: YamnetEngine(),
        loadModel: loadYamnetMoodModel,
      ),
    )
    ..registerLazySingleton(
      () => MoodSwitchover(
        classifier: getIt(),
        downloader: DioAudioDownloader(),
        // Remote kill switch: GET /api/v1/config (ON_DEVICE_MOOD_ENABLED).
        isEnabled: () async =>
            (await getIt<AppConfigRepository>().load()).onDeviceMood,
        // Only iOS registers the native decoder (moodtune/audio_decode).
        isSupported: defaultTargetPlatform == TargetPlatform.iOS,
      ),
    )
    // Mood observations + "Does this feel right?" feedback (ROADMAP OD-4)
    ..registerLazySingleton<AppConfigRepository>(
      () => AppConfigRepositoryImpl(
        remoteDataSource: AppConfigRemoteDataSource(baseUrl: apiBaseUrl),
      ),
    )
    ..registerLazySingleton<MoodObservationRepository>(
      () => MoodObservationRepositoryImpl(
        remoteDataSource: MoodObservationRemoteDataSource(
          baseUrl: apiBaseUrl,
          tokenProvider: tokenProvider,
        ),
      ),
    )
    ..registerLazySingleton(() => MoodObservationRecorder(repository: getIt()))
    // Sharing (#35). META_APP_ID is public and comes from --dart-define;
    // without it Instagram Stories is hidden from the share sheet.
    ..registerLazySingleton<ShareRepository>(
      () => ShareRepositoryImpl(
        metaAppId: const String.fromEnvironment('META_APP_ID'),
      ),
    )
    ..registerLazySingleton<ShareCardRenderer>(MoodShareCardRenderer.new)
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
