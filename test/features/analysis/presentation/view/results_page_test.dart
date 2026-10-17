import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/di/injector.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/analysis_loading_page.dart';
import 'package:moodtune_app/features/analysis/presentation/view/results_page.dart';
import 'package:moodtune_app/features/auth/domain/entities/app_user.dart';
import 'package:moodtune_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:moodtune_app/features/mood_feedback/mood_feedback.dart';
import 'package:moodtune_app/features/mood_feedback/presentation/mood_observation_recorder.dart';
import 'package:moodtune_app/features/narration/presentation/mood_narrator.dart';
import 'package:moodtune_app/shared/widgets/mood_descriptor_tags.dart';
import 'package:moodtune_app/shared/widgets/mood_hero_card.dart';
import 'package:moodtune_app/shared/widgets/sign_up_strip.dart';

import '../../../../helpers/helpers.dart';
import '../../../narration/narration_fixtures.dart';
import 'results_fixtures.dart';

const _authenticated = AuthState(
  status: AuthStatus.authenticated,
  user: AppUser(id: 'user-1', email: 'jane@example.com'),
);

const _urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');

class MockObservationRecorder extends Mock implements MoodObservationRecorder {}

void main() {
  // ResultsPage resolves MoodNarrator from getIt. An unavailable engine makes
  // it fall back to the backend's template reasoning, which these tests assert.
  setUp(() {
    getIt.registerSingleton<MoodNarrator>(
      MoodNarrator(engine: FakeNarrationEngine(available: false)),
    );
  });
  tearDown(() => getIt.unregister<MoodNarrator>());

  group('ResultsPage', () {
    Future<void> pumpResults(
      WidgetTester tester, {
      required AnalysisState analysisState,
      AnalysisSource source = AnalysisSource.upload,
      AuthState authState = const AuthState(status: AuthStatus.unauthenticated),
    }) async {
      await tester.pumpApp(
        ResultsPage(source: source),
        analysisBloc: mockAnalysisBloc(analysisState),
        authBloc: mockAuthBloc(authState),
      );
      await tester.pumpAndSettle();
    }

    /// Mounts an upload result whose history save then lands ([saved]) or
    /// does not.
    Future<GoRouter> pumpSaved(
      WidgetTester tester, {
      bool saved = true,
      AuthState authState = _authenticated,
    }) async {
      final analysisBloc = mockAnalysisBloc();
      final landed = AnalysisState(currentUploadAnalysis: testUploadAnalysis());
      whenListen(
        analysisBloc,
        Stream<AnalysisState>.value(landed.copyWith(uploadSaved: saved)),
        initialState: landed,
      );
      final router = await tester.pumpApp(
        const ResultsPage(source: AnalysisSource.upload),
        analysisBloc: analysisBloc,
        authBloc: mockAuthBloc(authState),
      );
      await tester.pump();
      return router;
    }

    group('without a result', () {
      testWidgets('upload source shows empty state and opens source sheet', (
        tester,
      ) async {
        await pumpResults(tester, analysisState: const AnalysisState());

        expect(find.text('Song Analysis'), findsOneWidget);
        expect(find.text('No result available.'), findsOneWidget);
        expect(find.byType(MoodHeroCard), findsNothing);

        await tester.tap(find.text('Analyze a new song'));
        await tester.pumpAndSettle();

        expect(find.text('Analyze a Song'), findsOneWidget);
        await tester.tap(find.text('Upload a Song'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);
      });

      testWidgets('catalog source with no analyses shows empty state', (
        tester,
      ) async {
        await pumpResults(
          tester,
          source: AnalysisSource.catalog,
          analysisState: const AnalysisState(),
        );

        expect(find.text('No result available.'), findsOneWidget);
      });

      // AC1 (#38): a leftover upload result must not show as the catalog's.
      testWidgets('catalog source ignores a leftover upload result', (
        tester,
      ) async {
        await pumpResults(
          tester,
          source: AnalysisSource.catalog,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(),
            catalogStatus: CatalogAnalysisStatus.analyzing,
          ),
        );

        expect(find.text('No result available.'), findsOneWidget);
        expect(find.byType(MoodHeroCard), findsNothing);
      });
    });

    group('upload result (guest)', () {
      testWidgets('renders hero, descriptors, reasoning and sign-up strip', (
        tester,
      ) async {
        await pumpResults(
          tester,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(),
          ),
        );

        expect(find.byType(MoodHeroCard), findsOneWidget);
        expect(find.byType(MoodDescriptorTags), findsOneWidget);
        expect(find.text('danceable'), findsOneWidget);
        expect(
          find.text('Fast tempo and bright timbre suggest an upbeat mood.'),
          findsOneWidget,
        );
        expect(find.text('Audio details'), findsOneWidget);
        expect(find.text('Analyze another song'), findsOneWidget);
        expect(find.byType(SignUpStrip), findsOneWidget);
        expect(find.text('Go to Home'), findsNothing);
        expect(find.text('Via Jamendo Free Music'), findsNothing);
      });

      testWidgets('sign-up strip slides in and pushes sign-in', (tester) async {
        await pumpResults(
          tester,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(),
          ),
        );

        final transform = tester.widget<Transform>(
          find
              .ancestor(
                of: find.byType(SignUpStrip),
                matching: find.byType(Transform),
              )
              .first,
        );
        // Animation finished: strip is fully slid in.
        expect(transform.transform.getTranslation().y, 0);

        await tester.tap(find.text('Sign up'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.signIn)), findsOneWidget);
      });

      testWidgets('audio details expand to show the feature rows', (
        tester,
      ) async {
        await pumpResults(
          tester,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(),
          ),
        );
        expect(find.text('128 BPM'), findsNothing);

        await tester.tap(find.text('Audio details'));
        await tester.pumpAndSettle();

        expect(find.text('Tempo'), findsOneWidget);
        expect(find.text('128 BPM'), findsOneWidget);
        expect(find.text('Energy'), findsOneWidget);
        expect(find.text('High (0.84)'), findsOneWidget);
        expect(find.text('Brightness'), findsOneWidget);
        expect(find.text('Bright (0.71)'), findsOneWidget);
        expect(find.text('Texture'), findsOneWidget);
        expect(find.text('Smooth (0.40)'), findsOneWidget);
      });

      testWidgets('on-device results show sound tags as pills', (tester) async {
        final backend = testUploadAnalysis();
        await pumpResults(
          tester,
          analysisState: AnalysisState(
            currentUploadAnalysis: backend.copyWith(
              mood: backend.mood.copyWith(
                source: MoodSource.onDevice,
                soundTags: const ['vocals', 'piano'],
                descriptors: const [],
              ),
            ),
          ),
        );

        final pills = tester.widget<MoodDescriptorTags>(
          find.byType(MoodDescriptorTags),
        );
        expect(pills.tags, ['vocals', 'piano']);
      });

      testWidgets('asks "Does this feel right?" and sends the answer', (
        tester,
      ) async {
        final recorder = MockObservationRecorder();
        when(
          () => recorder.sendFeedback(
            any(),
            agrees: any(named: 'agrees'),
            userMood: any(named: 'userMood'),
          ),
        ).thenAnswer((_) async {});
        getIt.registerSingleton<MoodObservationRecorder>(recorder);
        addTearDown(() => getIt.unregister<MoodObservationRecorder>());

        await pumpResults(
          tester,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(),
            observationId: 'obs-1',
          ),
        );
        await tester.scrollUntilVisible(
          find.text('Does this feel right?'),
          200,
        );
        await tester.tap(find.bySemanticsLabel('Yes, this feels right'));
        await tester.pumpAndSettle();

        verify(() => recorder.sendFeedback('obs-1', agrees: true)).called(1);
      });

      testWidgets('shows no feedback prompt without an observation', (
        tester,
      ) async {
        await pumpResults(
          tester,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(),
          ),
        );

        expect(find.byType(MoodFeedbackPrompt), findsNothing);
      });

      testWidgets('hides descriptors and reasoning when empty', (tester) async {
        await pumpResults(
          tester,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(
              descriptors: const [],
              reasoning: '',
            ),
          ),
        );

        expect(find.byType(MoodHeroCard), findsOneWidget);
        expect(find.byType(MoodDescriptorTags), findsNothing);
        expect(
          find.text('Fast tempo and bright timbre suggest an upbeat mood.'),
          findsNothing,
        );
      });

      testWidgets('"Analyze another song" opens the source sheet', (
        tester,
      ) async {
        await pumpResults(
          tester,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(),
          ),
        );

        await tester.ensureVisible(find.text('Analyze another song'));
        await tester.tap(find.text('Analyze another song'));
        await tester.pumpAndSettle();

        expect(find.text('Analyze a Song'), findsOneWidget);
        await tester.tap(find.text('Browse Catalog'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.catalog)), findsOneWidget);
      });

      testWidgets('shows the strip immediately when animations are disabled', (
        tester,
      ) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(
          tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );

        await tester.pumpApp(
          const ResultsPage(source: AnalysisSource.upload),
          analysisBloc: mockAnalysisBloc(
            AnalysisState(currentUploadAnalysis: testUploadAnalysis()),
          ),
        );
        // One frame for the post-frame callback, one to rebuild.
        await tester.pump();
        await tester.pump();

        final transform = tester.widget<Transform>(
          find
              .ancestor(
                of: find.byType(SignUpStrip),
                matching: find.byType(Transform),
              )
              .first,
        );
        expect(transform.transform.getTranslation().y, 0);
      });
    });

    group('upload result (authenticated)', () {
      testWidgets('shows "Go to Home" instead of sign-up strip', (
        tester,
      ) async {
        await pumpResults(
          tester,
          authState: _authenticated,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(),
          ),
        );

        expect(find.byType(SignUpStrip), findsNothing);

        await tester.ensureVisible(find.text('Go to Home'));
        await tester.tap(find.text('Go to Home'));
        await tester.pumpAndSettle();

        expect(find.text(navigatedTo(RouteNames.homeAuth)), findsOneWidget);
      });

      // AC1 (#44): the notice appears once the upload is saved, then goes.
      testWidgets('shows "Saved to history" once saved, then dismisses it', (
        tester,
      ) async {
        await pumpSaved(tester);
        expect(find.byType(MoodHeroCard), findsOneWidget);
        expect(find.text('Saved to history'), findsNothing);

        // The notice is scheduled 800 ms after the save, then fades in.
        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();
        expect(find.text('Saved to history'), findsOneWidget);
        final opacity = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: find.text('Saved to history'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(opacity.opacity.value, 1);
        // Non-blocking: the page underneath still takes taps.
        expect(find.text('Go to Home'), findsOneWidget);

        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text('Saved to history'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      // AC2 (#44): a result that was not saved gets no notice.
      testWidgets('no notice when the result was not saved', (tester) async {
        await pumpSaved(tester, saved: false);

        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();

        expect(find.byType(MoodHeroCard), findsOneWidget);
        expect(find.text('Saved to history'), findsNothing);
      });

      // AC3 (#44): the notice is localized.
      testWidgets('shows the Spanish notice in the Spanish locale', (
        tester,
      ) async {
        tester.platformDispatcher.localesTestValue = const [Locale('es')];
        addTearDown(tester.platformDispatcher.clearLocalesTestValue);
        await pumpSaved(tester);

        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();

        expect(find.text('Guardado en el historial'), findsOneWidget);
        expect(find.text('Saved to history'), findsNothing);
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      });

      testWidgets('no notice over a page pushed on top of the results', (
        tester,
      ) async {
        final router = await pumpSaved(tester);
        unawaited(router.push(RouteNames.uploadMusic));
        await tester.pumpAndSettle();
        expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 800));
        await tester.pumpAndSettle();

        expect(find.text('Saved to history'), findsNothing);
      });

      testWidgets('saved notice is skipped if page is disposed first', (
        tester,
      ) async {
        await pumpSaved(tester);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 800));

        expect(find.text('Saved to history'), findsNothing);
        expect(tester.takeException(), isNull);
      });

      testWidgets('guests do not get the saved notice', (tester) async {
        await pumpSaved(
          tester,
          authState: const AuthState(status: AuthStatus.unauthenticated),
        );
        // No 800 ms timer is scheduled, so settling is enough.
        await tester.pumpAndSettle();

        expect(find.byType(SignUpStrip), findsOneWidget);
        expect(find.text('Saved to history'), findsNothing);
      });
    });

    group('catalog result', () {
      late List<MethodCall> launchCalls;

      setUp(() {
        launchCalls = [];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_urlLauncherChannel, (call) async {
              launchCalls.add(call);
              return true;
            });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(_urlLauncherChannel, null);
      });

      testWidgets('renders catalog analysis with Jamendo attribution', (
        tester,
      ) async {
        await pumpResults(
          tester,
          source: AnalysisSource.catalog,
          analysisState: AnalysisState(
            currentCatalogAnalysis: testUploadAnalysis(
              id: 'catalog-1',
              jamendoTrackUrl: 'https://jamendo.com/track/1',
            ),
          ),
        );

        expect(find.byType(MoodHeroCard), findsOneWidget);
        expect(find.text('Test Artist on Jamendo ↗'), findsOneWidget);
        expect(find.text('Via Jamendo Free Music'), findsOneWidget);
      });

      // AC1 (#38): with both results in state, each source shows its own.
      testWidgets('shows the catalog result, not an earlier upload', (
        tester,
      ) async {
        await pumpResults(
          tester,
          source: AnalysisSource.catalog,
          analysisState: AnalysisState(
            currentUploadAnalysis: testUploadAnalysis(artist: 'Upload Artist'),
            currentCatalogAnalysis: testUploadAnalysis(
              id: 'catalog-1',
              artist: 'Catalog Artist',
              jamendoTrackUrl: 'https://jamendo.com/track/1',
            ),
          ),
        );

        expect(find.text('Catalog Artist on Jamendo ↗'), findsOneWidget);
        expect(find.textContaining('Upload Artist'), findsNothing);
      });

      testWidgets('tapping attribution launches the Jamendo page', (
        tester,
      ) async {
        await pumpResults(
          tester,
          source: AnalysisSource.catalog,
          analysisState: AnalysisState(
            currentCatalogAnalysis: testUploadAnalysis(
              jamendoTrackUrl: 'https://jamendo.com/track/1',
            ),
          ),
        );

        await tester.ensureVisible(find.text('Test Artist on Jamendo ↗'));
        await tester.tap(find.text('Test Artist on Jamendo ↗'));
        await tester.pump();

        expect(launchCalls, hasLength(1));
        expect(launchCalls.single.method, 'launch');
        expect(
          (launchCalls.single.arguments as Map)['url'],
          'https://jamendo.com/track/1',
        );
      });

      testWidgets('falls back to "Artist" and disables empty links', (
        tester,
      ) async {
        await pumpResults(
          tester,
          source: AnalysisSource.catalog,
          analysisState: AnalysisState(
            currentCatalogAnalysis: testUploadAnalysis(
              artist: null,
              jamendoTrackUrl: '',
            ),
          ),
        );

        final label = find.text('Artist on Jamendo ↗');
        expect(label, findsOneWidget);
        expect(
          tester.widget<Text>(label).style?.decoration,
          TextDecoration.none,
        );

        await tester.ensureVisible(label);
        await tester.tap(label);
        await tester.pump();

        expect(launchCalls, isEmpty);
      });
    });
  });
}
