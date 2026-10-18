import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/di/injector.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_assets.dart';
import 'package:moodtune_app/features/spotify/data/repositories/spotify_repository_impl.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    talker.info('onChange(${bloc.runtimeType}, $change)');
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    talker.error('onError(${bloc.runtimeType}, $error)', error, stackTrace);
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    unawaited(
      Sentry.captureException(details.exception, stackTrace: details.stack),
    );
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();
  registerYamnetLicense();

  const apiBaseEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: SpotifyRepositoryImpl.defaultBaseUrl,
  );

  await configureDependencies(
    apiBaseUrl: apiBaseEnv,
    tokenProvider: () async =>
        Supabase.instance.client.auth.currentSession?.accessToken,
  );

  // Log only whether a session exists, never the token itself.
  final hasSession = Supabase.instance.client.auth.currentSession != null;
  talker.info('session: ${hasSession ? 'present' : 'none'}');

  runApp(await builder());
}
