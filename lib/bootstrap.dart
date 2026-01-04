import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:moodtune_app/di/injector.dart';
import 'package:moodtune_app/features/spotify/data/repositories/spotify_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  const apiBaseEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: SpotifyRepositoryImpl.defaultBaseUrl,
  );

  await configureDependencies(
    apiBaseUrl: apiBaseEnv,
    tokenProvider: () async =>
        Supabase.instance.client.auth.currentSession?.accessToken,
  );

  runApp(await builder());
}
