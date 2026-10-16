import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/routing/route_names.dart';
import 'package:moodtune_app/features/analysis/presentation/bloc/analysis_bloc.dart';
import 'package:moodtune_app/features/analysis/presentation/view/analysis_loading_page.dart';
import 'package:moodtune_app/features/analysis/presentation/view/upload_music_page.dart';

import '../../../../helpers/helpers.dart';

/// Hand-rolled [FilePicker] that returns a queued result.
///
/// Extending [FilePicker] (rather than mocking it) passes the platform
/// interface token check without depending on plugin_platform_interface.
class _FakeFilePicker extends FilePicker {
  FilePickerResult? nextResult;
  int calls = 0;
  FileType? lastType;
  List<String>? lastAllowedExtensions;
  bool? lastWithData;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    calls++;
    lastType = type;
    lastAllowedExtensions = allowedExtensions;
    lastWithData = withData;
    return nextResult;
  }
}

class _FakeAnalysisEvent extends Fake implements AnalysisEvent {}

const int _mb = 1024 * 1024;
final _bytes = Uint8List.fromList([1, 2, 3, 4]);

FilePickerResult _result(String name, int size, {bool withBytes = true}) =>
    FilePickerResult([
      PlatformFile(name: name, size: size, bytes: withBytes ? _bytes : null),
    ]);

const _homeText = 'home';
const _pagePath = '/page';

void main() {
  late _FakeFilePicker picker;
  late MockAnalysisBloc bloc;

  setUpAll(() => registerFallbackValue(_FakeAnalysisEvent()));

  setUp(() {
    picker = _FakeFilePicker();
    FilePicker.platform = picker;
    bloc = mockAnalysisBloc();
  });

  /// Gives the ListView enough room to build every child.
  void useTallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Object? loadingExtra;

  Future<GoRouter> pumpPage(WidgetTester tester) {
    useTallView(tester);
    loadingExtra = null;
    return tester.pumpApp(
      const UploadMusicPage(),
      analysisBloc: bloc,
      extraRoutes: [
        GoRoute(
          path: RouteNames.analysisLoading,
          builder: (_, state) {
            loadingExtra = state.extra;
            return const Text('loading-page');
          },
        ),
      ],
    );
  }

  Future<void> pickWith(
    WidgetTester tester,
    FilePickerResult? result, {
    String tapText = 'Tap to choose a file',
  }) async {
    picker.nextResult = result;
    await tester.tap(find.text(tapText));
    await tester.pump();
  }

  CupertinoButton analyzeButton(WidgetTester tester) =>
      tester.widget<CupertinoButton>(
        find.ancestor(
          of: find.text('Analyze song'),
          matching: find.byType(CupertinoButton),
        ),
      );

  Future<void> settleSheet(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group(UploadMusicPage, () {
    testWidgets('renders empty drop zone with analyze disabled', (
      tester,
    ) async {
      await pumpPage(tester);

      expect(find.text('Upload Music'), findsOneWidget);
      expect(find.text('Choose a file to analyze'), findsOneWidget);
      expect(
        find.text('MP3 · M4A · FLAC · WAV · OGG · max 15 MB'),
        findsOneWidget,
      );
      expect(find.text('Tap to choose a file'), findsOneWidget);
      expect(find.text('Add song details'), findsOneWidget);
      expect(analyzeButton(tester).onPressed, isNull);
    });

    testWidgets('requests audio files with data from the picker', (
      tester,
    ) async {
      await pumpPage(tester);

      await pickWith(tester, null);

      expect(picker.calls, 1);
      expect(picker.lastType, FileType.custom);
      expect(picker.lastAllowedExtensions, [
        'mp3',
        'm4a',
        'flac',
        'wav',
        'ogg',
      ]);
      expect(picker.lastWithData, isTrue);
    });

    testWidgets('stays empty when picking is cancelled', (tester) async {
      await pumpPage(tester);

      await pickWith(tester, null);

      expect(find.text('Tap to choose a file'), findsOneWidget);
      expect(analyzeButton(tester).onPressed, isNull);
    });

    testWidgets('stays empty when the picker returns no files', (tester) async {
      await pumpPage(tester);

      await pickWith(tester, const FilePickerResult([]));

      expect(find.text('Tap to choose a file'), findsOneWidget);
    });

    testWidgets('stays empty when the picked file has no bytes', (
      tester,
    ) async {
      await pumpPage(tester);

      await pickWith(tester, _result('song.mp3', 1000, withBytes: false));

      expect(find.text('Tap to choose a file'), findsOneWidget);
      expect(find.text('song.mp3'), findsNothing);
    });

    testWidgets('shows selected file with size and estimate', (tester) async {
      await pumpPage(tester);

      await pickWith(tester, _result('song.mp3', 1000));

      expect(find.text('song.mp3'), findsOneWidget);
      expect(find.text('0.0 MB  ·  Analysis takes ~15 secs'), findsOneWidget);
      expect(find.text('Change file'), findsOneWidget);
      expect(find.text('Tap to choose a file'), findsNothing);
      expect(analyzeButton(tester).onPressed, isNotNull);
    });

    testWidgets('accepts upper-case extensions', (tester) async {
      await pumpPage(tester);

      await pickWith(tester, _result('LOUD.FLAC', 1000));

      expect(find.text('LOUD.FLAC'), findsOneWidget);
      expect(analyzeButton(tester).onPressed, isNotNull);
    });

    for (final (size, label) in [
      (4000000, '3.8 MB  ·  Analysis takes ~30 secs'),
      (8000000, '7.6 MB  ·  Analysis takes ~45 secs'),
      (10000000, '9.5 MB  ·  Analysis takes about a minute'),
    ]) {
      testWidgets('estimates analysis time for $size bytes', (tester) async {
        await pumpPage(tester);

        await pickWith(tester, _result('song.mp3', size));

        expect(find.text(label), findsOneWidget);
      });
    }

    testWidgets('rejects files over 15 MB', (tester) async {
      await pumpPage(tester);

      await pickWith(tester, _result('huge.mp3', 15 * _mb + 1));

      expect(find.text('File is too large — maximum 15 MB.'), findsOneWidget);
      expect(find.text('Choose a different file'), findsOneWidget);
      expect(find.text('huge.mp3'), findsNothing);
      expect(analyzeButton(tester).onPressed, isNull);
    });

    testWidgets('accepts a file of exactly 15 MB', (tester) async {
      await pumpPage(tester);

      await pickWith(tester, _result('edge.mp3', 15 * _mb));

      expect(find.text('edge.mp3'), findsOneWidget);
      expect(analyzeButton(tester).onPressed, isNotNull);
    });

    testWidgets('rejects unsupported formats', (tester) async {
      await pumpPage(tester);

      await pickWith(tester, _result('notes.txt', 1000));

      expect(
        find.text('Unsupported format — use MP3, M4A, FLAC, WAV, or OGG.'),
        findsOneWidget,
      );
      expect(analyzeButton(tester).onPressed, isNull);
    });

    testWidgets('choosing a different file after an error recovers', (
      tester,
    ) async {
      await pumpPage(tester);
      await pickWith(tester, _result('notes.txt', 1000));

      await pickWith(
        tester,
        _result('song.wav', 1000),
        tapText: 'Choose a different file',
      );

      expect(picker.calls, 2);
      expect(find.text('song.wav'), findsOneWidget);
      expect(
        find.text('Unsupported format — use MP3, M4A, FLAC, WAV, or OGG.'),
        findsNothing,
      );
      expect(analyzeButton(tester).onPressed, isNotNull);
    });

    testWidgets('Change file replaces the selection', (tester) async {
      await pumpPage(tester);
      await pickWith(tester, _result('first.mp3', 1000));

      await pickWith(
        tester,
        _result('second.ogg', 1000),
        tapText: 'Change file',
      );

      expect(picker.calls, 2);
      expect(find.text('first.mp3'), findsNothing);
      expect(find.text('second.ogg'), findsOneWidget);
    });

    testWidgets('Change file to an invalid file shows the error', (
      tester,
    ) async {
      await pumpPage(tester);
      await pickWith(tester, _result('first.mp3', 1000));

      await pickWith(
        tester,
        _result('big.m4a', 20 * _mb),
        tapText: 'Change file',
      );

      expect(find.text('File is too large — maximum 15 MB.'), findsOneWidget);
      expect(analyzeButton(tester).onPressed, isNull);
    });

    group('consent sheet', () {
      testWidgets('Cancel closes the sheet without dispatching', (
        tester,
      ) async {
        await pumpPage(tester);
        await pickWith(tester, _result('song.mp3', 1000));

        await tester.tap(find.text('Analyze song'));
        await settleSheet(tester);
        expect(find.text('One quick thing'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await settleSheet(tester);

        expect(find.text('One quick thing'), findsNothing);
        verifyNever(() => bloc.add(any()));
        expect(find.text('loading-page'), findsNothing);
      });

      testWidgets('dismissing via the barrier does not dispatch', (
        tester,
      ) async {
        await pumpPage(tester);
        await pickWith(tester, _result('song.mp3', 1000));

        await tester.tap(find.text('Analyze song'));
        await settleSheet(tester);
        await tester.tapAt(const Offset(10, 10));
        await settleSheet(tester);

        expect(find.text('One quick thing'), findsNothing);
        verifyNever(() => bloc.add(any()));
      });

      testWidgets('confirming dispatches upload and opens loading screen', (
        tester,
      ) async {
        await pumpPage(tester);
        await pickWith(tester, _result('song.mp3', 3000000));

        await tester.tap(find.text('Analyze song'));
        await settleSheet(tester);
        await tester.tap(find.text("Yes, let's hear it"));
        await settleSheet(tester);

        final event =
            verify(() => bloc.add(captureAny())).captured.single
                as AudioUploadRequested;
        expect(event.bytes, _bytes);
        expect(event.filename, 'song.mp3');
        expect(event.title, isEmpty);
        expect(event.artist, isEmpty);
        expect(event.album, isEmpty);

        expect(find.text('loading-page'), findsOneWidget);
        final args = loadingExtra! as AnalysisLoadingArgs;
        expect(args.source, AnalysisSource.upload);
        expect(args.trackDurationSeconds, 150);
      });

      testWidgets('includes trimmed song details in the upload event', (
        tester,
      ) async {
        await pumpPage(tester);
        await pickWith(tester, _result('song.mp3', 1000));

        await tester.tap(find.text('Add song details'));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.enterText(
          find.widgetWithText(CupertinoTextField, 'Title (optional)'),
          '  My Title ',
        );
        await tester.enterText(
          find.widgetWithText(CupertinoTextField, 'Artist (optional)'),
          ' The Artist',
        );
        await tester.enterText(
          find.widgetWithText(CupertinoTextField, 'Album (optional)'),
          'An Album  ',
        );
        await tester.pump();

        await tester.tap(find.text('Analyze song'));
        await settleSheet(tester);
        await tester.tap(find.text("Yes, let's hear it"));
        await settleSheet(tester);

        final event =
            verify(() => bloc.add(captureAny())).captured.single
                as AudioUploadRequested;
        expect(event.title, 'My Title');
        expect(event.artist, 'The Artist');
        expect(event.album, 'An Album');
        expect(event.filename, 'song.mp3');
        expect(find.text('loading-page'), findsOneWidget);
      });
    });

    group('back button', () {
      testWidgets('goes to landing when there is nothing to pop', (
        tester,
      ) async {
        await pumpPage(tester);

        await tester.tap(find.byIcon(CupertinoIcons.back));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text(navigatedTo(RouteNames.landing)), findsOneWidget);
      });

      testWidgets('pops to the previous route when possible', (tester) async {
        useTallView(tester);
        final router = await tester.pumpApp(
          const Center(child: Text(_homeText)),
          analysisBloc: bloc,
          extraRoutes: [
            GoRoute(
              path: _pagePath,
              builder: (_, _) => const UploadMusicPage(),
            ),
          ],
        );
        unawaited(router.push(_pagePath));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text('Upload Music'), findsOneWidget);

        await tester.tap(find.byIcon(CupertinoIcons.back));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(_homeText), findsOneWidget);
        expect(find.text('Upload Music'), findsNothing);
      });
    });
  });
}
