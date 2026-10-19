import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/domain/domain.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/analysis_loading_page.dart';

import '../../../../helpers/helpers.dart';
import 'flow_fixtures.dart';

Future<void> _pumpLoading(
  WidgetTester tester, {
  AnalysisSource source = AnalysisSource.upload,
  int? trackDurationSeconds,
  AnalysisBloc? analysisBloc,
  List<RouteBase> extraRoutes = const [],
}) async {
  await tester.pumpApp(
    AnalysisLoadingPage(
      source: source,
      trackDurationSeconds: trackDurationSeconds,
    ),
    analysisBloc: analysisBloc ?? mockAnalysisBloc(),
    extraRoutes: extraRoutes,
  );
}

/// Advances fake time by [seconds] one phase tick at a time, then lets the
/// phase cross-fade finish so only the current message is on screen.
Future<void> _advance(WidgetTester tester, int seconds) async {
  for (var elapsed = 0; elapsed < seconds; elapsed += 5) {
    final step = seconds - elapsed < 5 ? seconds - elapsed : 5;
    await tester.pump(Duration(seconds: step));
  }
  await tester.pump(const Duration(milliseconds: 700));
}

/// Unmounts the page so its timers are cancelled before the test ends.
Future<void> _dispose(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

/// The ghost result card is the first AnimatedOpacity on the page.
double _ghostOpacity(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first).opacity;

/// Opacity of the "taking longer" note (0 until the analysis runs long).
double _slowNoteOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.ancestor(
        of: find.text(slowMessage),
        matching: find.byType(AnimatedOpacity),
      ),
    )
    .opacity;

class _FakeAnalysisEvent extends Fake implements AnalysisEvent {}

void main() {
  setUpAll(() => registerFallbackValue(_FakeAnalysisEvent()));

  group(AnalysisLoadingArgs, () {
    test('holds source and optional duration', () {
      const args = AnalysisLoadingArgs(
        source: AnalysisSource.catalog,
        trackDurationSeconds: 200,
      );
      expect(args.source, AnalysisSource.catalog);
      expect(args.trackDurationSeconds, 200);
      expect(
        const AnalysisLoadingArgs(
          source: AnalysisSource.upload,
        ).trackDurationSeconds,
        isNull,
      );
    });
  });

  group(AnalysisLoadingPage, () {
    group('phases', () {
      testWidgets('starts on the first upload phase with ghost hidden', (
        tester,
      ) async {
        await _pumpLoading(tester);

        expect(find.text('Uploading your track…'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(_ghostOpacity(tester), 0);

        await _dispose(tester);
      });

      testWidgets('starts on the first catalog phase', (tester) async {
        await _pumpLoading(tester, source: AnalysisSource.catalog);

        expect(find.text('Fetching the track…'), findsOneWidget);
        expect(find.text('Uploading your track…'), findsNothing);

        await _dispose(tester);
      });

      testWidgets('advances a phase every 5 seconds', (tester) async {
        await _pumpLoading(tester);

        await _advance(tester, 5);
        expect(find.text('Listening to the rhythm…'), findsOneWidget);
        expect(find.text('Uploading your track…'), findsNothing);

        await _advance(tester, 5);
        expect(find.text('Reading the energy…'), findsOneWidget);

        await _advance(tester, 5);
        expect(find.text('Feeling the texture…'), findsOneWidget);

        await _advance(tester, 5);
        expect(find.text('Finding the mood…'), findsOneWidget);

        await _dispose(tester);
      });

      testWidgets('pins the last phase and reveals the ghost card at 28s', (
        tester,
      ) async {
        await _pumpLoading(tester);

        // 25 s: last phase reached, ghost still hidden.
        await _advance(tester, 25);
        expect(find.text('Almost there…'), findsOneWidget);
        expect(_ghostOpacity(tester), 0);

        // 30 s: first tick past the 28 s reveal threshold.
        await _advance(tester, 5);
        expect(find.text('Almost there…'), findsOneWidget);
        expect(_ghostOpacity(tester), 1);

        await _dispose(tester);
      });
    });

    group('running long', () {
      testWidgets('keeps waiting past 35 s with a note', (tester) async {
        await _pumpLoading(tester, trackDurationSeconds: 180);

        await _advance(tester, 34);
        expect(_slowNoteOpacity(tester), 0);

        await _advance(tester, 1);
        expect(_slowNoteOpacity(tester), 1);
        expect(find.text('Almost there…'), findsOneWidget);
        expect(find.text('Try again'), findsNothing);

        await _dispose(tester);
      });

      testWidgets('still navigates when the result arrives late', (
        tester,
      ) async {
        final changes = StreamController<AnalysisState>();
        addTearDown(changes.close);
        const uploading = AnalysisState(uploadStatus: UploadStatus.uploading);
        final bloc = mockAnalysisBloc(uploading);
        whenListen(bloc, changes.stream, initialState: uploading);
        await _pumpLoading(
          tester,
          analysisBloc: bloc,
          extraRoutes: [
            GoRoute(
              path: RouteNames.result,
              builder: (_, _) => const Text('result'),
            ),
          ],
        );
        await _advance(tester, 70);
        expect(_slowNoteOpacity(tester), 1);

        changes.add(
          AnalysisState(
            uploadStatus: UploadStatus.success,
            currentUploadAnalysis: audioUploadAnalysis,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('result'), findsOneWidget);
      });

      testWidgets('Cancel still leaves while running long', (tester) async {
        await _pumpLoading(tester);
        await _advance(tester, 40);

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);
      });

      testWidgets('long tracks (> 4 min) never show the note', (tester) async {
        await _pumpLoading(tester, trackDurationSeconds: 241);

        await _advance(tester, 60);
        expect(_slowNoteOpacity(tester), 0);
        expect(find.text('Almost there…'), findsOneWidget);
        expect(_ghostOpacity(tester), 1);

        await _dispose(tester);
      });

      testWidgets('a 4 min track still shows the note', (tester) async {
        await _pumpLoading(tester, trackDurationSeconds: 240);

        await _advance(tester, 35);
        expect(_slowNoteOpacity(tester), 1);

        await _dispose(tester);
      });
    });

    group('cancel', () {
      testWidgets('returns to upload screen for upload source', (tester) async {
        await _pumpLoading(tester);

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);
      });

      testWidgets('tells the bloc to forget the request', (tester) async {
        final bloc = mockAnalysisBloc();
        await _pumpLoading(tester, analysisBloc: bloc);

        await tester.tap(find.text('Cancel'));
        await tester.pump();

        verify(() => bloc.add(const AnalysisRetryDiscarded())).called(1);
      });

      testWidgets('returns to catalog for catalog source', (tester) async {
        await _pumpLoading(tester, source: AnalysisSource.catalog);

        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(navigatedTo(RouteNames.catalog)), findsOneWidget);
      });
    });

    group('errors', () {
      testWidgets('offline upload error shows offline copy and retry', (
        tester,
      ) async {
        await _pumpLoading(
          tester,
          analysisBloc: mockAnalysisBloc(
            const AnalysisState(
              uploadStatus: UploadStatus.error,
              uploadError: 'Network connection lost',
              uploadErrorKind: AnalysisErrorKind.network,
            ),
          ),
        );

        expect(find.text('Looks like you went offline.'), findsOneWidget);
        expect(find.byIcon(CupertinoIcons.bolt_slash_fill), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);
        expect(find.text('Cancel'), findsNWidgets(2));
        expect(find.text('Uploading your track…'), findsNothing);

        await _dispose(tester);
      });

      testWidgets('rate-limit error shows OK that cancels to upload (AC3)', (
        tester,
      ) async {
        await _pumpLoading(
          tester,
          analysisBloc: mockAnalysisBloc(
            const AnalysisState(
              uploadStatus: UploadStatus.error,
              uploadError: 'Too many requests',
              uploadErrorKind: AnalysisErrorKind.rateLimit,
            ),
          ),
        );

        expect(
          find.text("You've done a lot of listening today."),
          findsOneWidget,
        );
        expect(find.byIcon(CupertinoIcons.timer), findsOneWidget);
        expect(find.text('Try again'), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(navigatedTo(RouteNames.uploadMusic)), findsOneWidget);
      });

      testWidgets('generic catalog error shows fallback copy', (tester) async {
        await _pumpLoading(
          tester,
          source: AnalysisSource.catalog,
          analysisBloc: mockAnalysisBloc(
            const AnalysisState(
              catalogStatus: CatalogAnalysisStatus.error,
              catalogError: 'Server exploded',
            ),
          ),
        );

        expect(
          find.text("Something went wrong. It's not your file — try again."),
          findsOneWidget,
        );
        expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);

        await tester.tap(find.text('Cancel').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(navigatedTo(RouteNames.catalog)), findsOneWidget);
      });

      // #41 R1
      for (final (source, state, target) in [
        (
          AnalysisSource.upload,
          const AnalysisState(
            uploadStatus: UploadStatus.error,
            uploadError: 'Server exploded',
          ),
          AnalysisRetryTarget.upload,
        ),
        (
          AnalysisSource.catalog,
          const AnalysisState(
            catalogStatus: CatalogAnalysisStatus.error,
            catalogError: 'Server exploded',
          ),
          AnalysisRetryTarget.catalog,
        ),
      ]) {
        testWidgets('Try again asks the bloc to re-send the ${source.name}', (
          tester,
        ) async {
          final bloc = mockAnalysisBloc(state);
          await _pumpLoading(tester, source: source, analysisBloc: bloc);

          await tester.tap(find.text('Try again'));
          await tester.pump();

          verify(() => bloc.add(AnalysisRetryRequested(target))).called(1);
          verifyNever(() => bloc.add(any()));

          await _dispose(tester);
        });
      }

      // #41 R3
      testWidgets('nothing to retry shows a clear error with only OK', (
        tester,
      ) async {
        await _pumpLoading(
          tester,
          source: AnalysisSource.catalog,
          analysisBloc: mockAnalysisBloc(
            const AnalysisState(
              catalogStatus: CatalogAnalysisStatus.error,
              catalogError: AnalysisBloc.retryUnavailableMessage,
              catalogErrorKind: AnalysisErrorKind.retryUnavailable,
            ),
          ),
        );

        expect(
          find.text('We lost track of that song. Go back and pick it again.'),
          findsOneWidget,
        );
        expect(find.text('Try again'), findsNothing);

        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(navigatedTo(RouteNames.catalog)), findsOneWidget);
      });

      testWidgets('ignores upload errors when source is catalog', (
        tester,
      ) async {
        await _pumpLoading(
          tester,
          source: AnalysisSource.catalog,
          analysisBloc: mockAnalysisBloc(
            const AnalysisState(
              uploadStatus: UploadStatus.error,
              uploadError: 'Network down',
              uploadErrorKind: AnalysisErrorKind.network,
            ),
          ),
        );

        expect(find.text('Fetching the track…'), findsOneWidget);
        expect(find.text('Looks like you went offline.'), findsNothing);

        await _dispose(tester);
      });

      testWidgets('ignores catalog errors when source is upload', (
        tester,
      ) async {
        await _pumpLoading(
          tester,
          analysisBloc: mockAnalysisBloc(
            const AnalysisState(
              catalogStatus: CatalogAnalysisStatus.error,
              catalogError: 'Network down',
              catalogErrorKind: AnalysisErrorKind.network,
            ),
          ),
        );

        expect(find.text('Uploading your track…'), findsOneWidget);

        await _dispose(tester);
      });

      testWidgets('catalog rate-limit error shows the rate-limit screen', (
        tester,
      ) async {
        await _pumpLoading(
          tester,
          source: AnalysisSource.catalog,
          analysisBloc: mockAnalysisBloc(
            const AnalysisState(
              catalogStatus: CatalogAnalysisStatus.error,
              catalogError: 'Slow down',
              catalogErrorKind: AnalysisErrorKind.rateLimit,
            ),
          ),
        );

        expect(
          find.text("You've done a lot of listening today."),
          findsOneWidget,
        );
        expect(find.text('OK'), findsOneWidget);

        await _dispose(tester);
      });

      for (final message in [
        'Failed to generate mood',
        'File size limit exceeded',
        'Rate of 429 per network connection',
      ]) {
        testWidgets('server error "$message" shows the generic screen (AC4)', (
          tester,
        ) async {
          await _pumpLoading(
            tester,
            analysisBloc: mockAnalysisBloc(
              AnalysisState(
                uploadStatus: UploadStatus.error,
                uploadError: message,
                uploadErrorKind: AnalysisErrorKind.other,
              ),
            ),
          );

          expect(
            find.text("Something went wrong. It's not your file — try again."),
            findsOneWidget,
          );
          expect(
            find.text("You've done a lot of listening today."),
            findsNothing,
          );
          expect(find.text('Looks like you went offline.'), findsNothing);
          expect(find.text('Try again'), findsOneWidget);

          await _dispose(tester);
        });
      }

      testWidgets('error emitted mid-analysis replaces the loading view', (
        tester,
      ) async {
        final bloc = mockAnalysisBloc(
          const AnalysisState(uploadStatus: UploadStatus.uploading),
        );
        whenListen(
          bloc,
          Stream.fromIterable([
            const AnalysisState(
              uploadStatus: UploadStatus.error,
              uploadError: 'socket closed',
              uploadErrorKind: AnalysisErrorKind.network,
            ),
          ]),
          initialState: const AnalysisState(
            uploadStatus: UploadStatus.uploading,
          ),
        );
        await _pumpLoading(tester, analysisBloc: bloc);
        await tester.pump();

        expect(find.text('Looks like you went offline.'), findsOneWidget);

        await _dispose(tester);
      });
    });

    group('success', () {
      testWidgets('upload success navigates to result with upload source', (
        tester,
      ) async {
        final bloc = mockAnalysisBloc(
          const AnalysisState(uploadStatus: UploadStatus.uploading),
        );
        whenListen(
          bloc,
          Stream.fromIterable([
            AnalysisState(
              uploadStatus: UploadStatus.success,
              currentUploadAnalysis: audioUploadAnalysis,
            ),
          ]),
          initialState: const AnalysisState(
            uploadStatus: UploadStatus.uploading,
          ),
        );

        Object? receivedExtra;
        await _pumpLoading(
          tester,
          analysisBloc: bloc,
          extraRoutes: [
            GoRoute(
              path: RouteNames.result,
              builder: (_, state) {
                receivedExtra = state.extra;
                return const Text('result');
              },
            ),
          ],
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('result'), findsOneWidget);
        expect(receivedExtra, AnalysisSource.upload);
      });

      testWidgets('catalog success navigates to result with catalog source', (
        tester,
      ) async {
        final bloc = mockAnalysisBloc();
        whenListen(
          bloc,
          Stream.fromIterable([
            AnalysisState(
              catalogStatus: CatalogAnalysisStatus.success,
              currentCatalogAnalysis: audioUploadAnalysis,
            ),
          ]),
          initialState: const AnalysisState(),
        );

        Object? receivedExtra;
        await _pumpLoading(
          tester,
          source: AnalysisSource.catalog,
          analysisBloc: bloc,
          extraRoutes: [
            GoRoute(
              path: RouteNames.result,
              builder: (_, state) {
                receivedExtra = state.extra;
                return const Text('result');
              },
            ),
          ],
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('result'), findsOneWidget);
        expect(receivedExtra, AnalysisSource.catalog);
      });

      testWidgets('upload success is ignored for catalog source', (
        tester,
      ) async {
        final bloc = mockAnalysisBloc();
        whenListen(
          bloc,
          Stream.fromIterable([
            AnalysisState(
              uploadStatus: UploadStatus.success,
              currentUploadAnalysis: audioUploadAnalysis,
            ),
          ]),
          initialState: const AnalysisState(),
        );

        await _pumpLoading(
          tester,
          source: AnalysisSource.catalog,
          analysisBloc: bloc,
        );
        await tester.pump();

        expect(find.textContaining('navigated:'), findsNothing);
        expect(find.text('Fetching the track…'), findsOneWidget);

        await _dispose(tester);
      });

      testWidgets('success without an analysis does not navigate', (
        tester,
      ) async {
        final bloc = mockAnalysisBloc();
        whenListen(
          bloc,
          Stream.fromIterable([
            const AnalysisState(uploadStatus: UploadStatus.success),
          ]),
          initialState: const AnalysisState(),
        );

        await _pumpLoading(tester, analysisBloc: bloc);
        await tester.pump();

        expect(find.textContaining('navigated:'), findsNothing);
        expect(find.text('Uploading your track…'), findsOneWidget);

        await _dispose(tester);
      });

      testWidgets('navigation on success stops the timeout', (tester) async {
        final bloc = mockAnalysisBloc();
        whenListen(
          bloc,
          Stream.fromIterable([
            AnalysisState(
              uploadStatus: UploadStatus.success,
              currentUploadAnalysis: audioUploadAnalysis,
            ),
          ]),
          initialState: const AnalysisState(),
        );

        await _pumpLoading(tester, analysisBloc: bloc);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(navigatedTo(RouteNames.result)), findsOneWidget);

        await tester.pump(const Duration(seconds: 40));
        expect(find.text(navigatedTo(RouteNames.result)), findsOneWidget);
      });
    });
  });

  // #41: with a real bloc, "Try again" re-sends the request and a success
  // then shows the result.
  group('Try again with a real bloc', () {
    late MockAnalysisRepository repository;

    setUpAll(() {
      registerFallbackValue(Uint8List(0));
      registerFallbackValue(
        const ResultHistoryRecord(
          source: ResultHistorySource.upload,
          title: 'fallback',
          displayedMood: 'happy',
          displayedSource: MoodSource.backend,
          backendMood: 'happy',
        ),
      );
    });

    setUp(() {
      repository = MockAnalysisRepository();
      when(
        () => repository.saveResultToHistory(any()),
      ).thenAnswer((_) async => const Right(false));
    });

    /// A real bloc, built inside the test so its streams run on the test's
    /// fake clock.
    AnalysisBloc buildBloc() {
      final bloc = AnalysisBloc(repository: repository);
      addTearDown(bloc.close);
      return bloc;
    }

    final resultRoute = GoRoute(
      path: RouteNames.result,
      builder: (_, _) => const Text('result'),
    );

    // AC1
    testWidgets('re-sends a failed upload once and shows the result', (
      tester,
    ) async {
      final retry = Completer<Either<Failure, AudioUploadAnalysis>>();
      final answers = [
        Future.value(
          const Left<Failure, AudioUploadAnalysis>(ServerFailure('down')),
        ),
        retry.future,
      ];
      when(
        () => repository.analyzeUploadedAudio(
          bytes: any(named: 'bytes'),
          filename: any(named: 'filename'),
          title: any(named: 'title'),
          artist: any(named: 'artist'),
          album: any(named: 'album'),
        ),
      ).thenAnswer((_) => answers.removeAt(0));

      final bloc = buildBloc()
        ..add(
          const AudioUploadRequested(
            bytes: [1, 2, 3],
            filename: 'song.mp3',
            title: 'T',
          ),
        );
      await _pumpLoading(
        tester,
        analysisBloc: bloc,
        extraRoutes: [resultRoute],
      );
      await tester.pump();
      expect(find.text('Try again'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      // R2: the old error is gone while the retry runs.
      expect(find.text('Try again'), findsNothing);
      expect(find.text('Uploading your track…'), findsOneWidget);

      retry.complete(Right(audioUploadAnalysis));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('result'), findsOneWidget);
      final bytes = verify(
        () => repository.analyzeUploadedAudio(
          bytes: captureAny(named: 'bytes'),
          filename: 'song.mp3',
          title: 'T',
          artist: any(named: 'artist'),
          album: any(named: 'album'),
        ),
      ).captured;
      expect(bytes, [
        Uint8List.fromList([1, 2, 3]),
        Uint8List.fromList([1, 2, 3]),
      ]);
    });

    // AC2
    testWidgets('re-sends a failed catalog analysis once and shows the '
        'result', (tester) async {
      final retry = Completer<Either<Failure, AudioUploadAnalysis>>();
      final answers = [
        Future.value(
          const Left<Failure, AudioUploadAnalysis>(NetworkFailure('offline')),
        ),
        retry.future,
      ];
      when(
        () => repository.analyzeCatalogTrack(
          audioUrl: any(named: 'audioUrl'),
          trackId: any(named: 'trackId'),
          trackName: any(named: 'trackName'),
          artistName: any(named: 'artistName'),
          jamendoPageUrl: any(named: 'jamendoPageUrl'),
        ),
      ).thenAnswer((_) => answers.removeAt(0));

      final bloc = buildBloc()
        ..add(
          const CatalogTrackAnalyzeRequested(
            audioUrl: 'https://audio',
            trackId: 'j1',
            trackName: 'Track',
            artistName: 'Artist',
            jamendoPageUrl: 'https://jamendo.com/track/1',
          ),
        );
      await _pumpLoading(
        tester,
        source: AnalysisSource.catalog,
        analysisBloc: bloc,
        extraRoutes: [resultRoute],
      );
      await tester.pump();
      expect(find.text('Looks like you went offline.'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(find.text('Looks like you went offline.'), findsNothing);
      expect(find.text('Fetching the track…'), findsOneWidget);

      retry.complete(Right(audioUploadAnalysis));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('result'), findsOneWidget);
      verify(
        () => repository.analyzeCatalogTrack(
          audioUrl: 'https://audio',
          trackId: 'j1',
          trackName: 'Track',
          artistName: 'Artist',
          jamendoPageUrl: 'https://jamendo.com/track/1',
        ),
      ).called(2);
    });
  });
}
