import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/catalog/presentation/bloc/catalog_bloc.dart';
import 'package:moodtune_app/features/spotify/presentation/bloc/spotify_bloc.dart';
import 'package:moodtune_app/l10n/l10n.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'mocks.dart';

/// Path the widget under test is mounted at.
const testRoutePath = '/__test__';

/// Text rendered when the widget under test navigates to any other route.
/// Assert navigation with `expect(find.text(navigatedTo('/sign-in')), ...)`.
String navigatedTo(String location) => 'navigated:$location';

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside the same shell the real app uses (ShadApp +
  /// CupertinoApp.router + localizations) with mock global BLoCs.
  ///
  /// Any BLoC not supplied is replaced by a fresh mock in its default state.
  /// Navigation away from the widget renders a placeholder whose text is
  /// [navigatedTo] of the new location, so tests can assert on routing.
  ///
  /// Returns the [GoRouter] so tests can inspect `routerDelegate` or push.
  Future<GoRouter> pumpApp(
    Widget widget, {
    AuthBloc? authBloc,
    AnalysisBloc? analysisBloc,
    SpotifyBloc? spotifyBloc,
    CatalogBloc? catalogBloc,
    Object? extra,
    List<RouteBase> extraRoutes = const [],
  }) async {
    final router = GoRouter(
      initialLocation: testRoutePath,
      initialExtra: extra,
      routes: [
        GoRoute(path: testRoutePath, builder: (_, _) => widget),
        ...extraRoutes,
      ],
      errorBuilder: (_, state) => CupertinoPageScaffold(
        child: Center(child: Text(navigatedTo(state.uri.toString()))),
      ),
    );

    await pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc ?? mockAuthBloc()),
          BlocProvider<AnalysisBloc>.value(
            value: analysisBloc ?? mockAnalysisBloc(),
          ),
          BlocProvider<SpotifyBloc>.value(
            value: spotifyBloc ?? mockSpotifyBloc(),
          ),
          BlocProvider<CatalogBloc>.value(
            value: catalogBloc ?? mockCatalogBloc(),
          ),
        ],
        child: ShadApp.custom(
          appBuilder: (context) => CupertinoApp.router(
            theme: CupertinoTheme.of(context),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
          themeMode: ThemeMode.light,
          theme: ShadThemeData(
            brightness: Brightness.light,
            colorScheme: const ShadSlateColorScheme.light(),
          ),
        ),
      ),
    );
    return router;
  }

  /// Pumps a plain widget (no routing, no BLoCs) with theme + localizations.
  /// Use for leaf widgets in `lib/shared/widgets` and feature `widgets/`.
  Future<void> pumpWidgetInShell(Widget widget) {
    return pumpWidget(
      ShadApp.custom(
        appBuilder: (context) => CupertinoApp(
          theme: CupertinoTheme.of(context),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CupertinoPageScaffold(child: widget),
        ),
        themeMode: ThemeMode.light,
        theme: ShadThemeData(
          brightness: Brightness.light,
          colorScheme: const ShadSlateColorScheme.light(),
        ),
      ),
    );
  }
}
