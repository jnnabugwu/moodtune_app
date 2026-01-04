import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moodtune_app/core/routing/app_router.dart';
import 'package:moodtune_app/di/injector.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/features/spotify/domain/usecases/usecases.dart';
import 'package:moodtune_app/features/spotify/presentation/presentation.dart';
import 'package:moodtune_app/l10n/l10n.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: getIt<SpotifyRepository>(),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(getIt()),
          ),
          BlocProvider(
            create: (_) => SpotifyBloc(
              getAuthorizeUrl: getIt<GetAuthorizeUrl>(),
              connectSpotify: getIt<ConnectSpotify>(),
              checkSpotifyConnection: getIt<CheckSpotifyConnection>(),
              getSpotifyProfile: getIt<GetSpotifyProfile>(),
              disconnectSpotify: getIt<DisconnectSpotify>(),
            ),
          ),
        ],
        child: ShadApp.custom(
          appBuilder: (context) => CupertinoApp.router(
            theme: CupertinoTheme.of(context),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: AppRouter.router,
          ),
          themeMode: ThemeMode.dark,
          darkTheme: ShadThemeData(
            brightness: Brightness.dark,
            colorScheme: const ShadSlateColorScheme.dark(),
          ),
        ),
      ),
    );
  }
}
