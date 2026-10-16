import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';
import 'package:moodtune_app/features/catalog/presentation/widgets/catalog_confirm_sheet.dart';

import '../../../../helpers/helpers.dart';
import '../../../../shared/widget_fixtures.dart';

/// Processing state indices as sent by the native just_audio plugin.
const _ready = 3;
const _completed = 4;

/// Fakes the just_audio + audio_session platform channels so the real
/// `AudioPlayer` created by [CatalogConfirmSheet] can run in widget tests.
class _FakeJustAudioPlatform {
  final calls = <String>[];
  final loadArgs = <Map<dynamic, dynamic>>[];
  final _ids = <String>[];
  late MockStreamHandlerEventSink _events;

  /// When set, `load` waits for this completer before responding.
  Completer<void>? loadGate;

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  static const _main = MethodChannel('com.ryanheise.just_audio.methods');
  static const _session = MethodChannel('com.ryanheise.audio_session');

  void install() {
    _messenger
      ..setMockMethodCallHandler(_session, (_) async => null)
      ..setMockMethodCallHandler(_main, (call) async {
        calls.add(call.method);
        if (call.method == 'init') {
          _registerPlayer((call.arguments as Map)['id'] as String);
          return null;
        }
        return <String, dynamic>{};
      });
  }

  void _registerPlayer(String id) {
    _ids.add(id);
    _messenger
      ..setMockMethodCallHandler(
        MethodChannel('com.ryanheise.just_audio.methods.$id'),
        (call) async {
          calls.add(call.method);
          if (call.method == 'load') {
            loadArgs.add(call.arguments as Map<dynamic, dynamic>);
            await loadGate?.future;
            return <String, dynamic>{'duration': 30 * 1000000};
          }
          return <String, dynamic>{};
        },
      )
      ..setMockStreamHandler(
        EventChannel('com.ryanheise.just_audio.events.$id'),
        MockStreamHandler.inline(
          onListen: (_, sink) {
            _events = sink;
          },
        ),
      )
      ..setMockStreamHandler(
        EventChannel('com.ryanheise.just_audio.data.$id'),
        MockStreamHandler.inline(onListen: (_, _) {}),
      );
  }

  void emit(int processingState, {Duration position = Duration.zero}) {
    _events.success(<String, dynamic>{
      'processingState': processingState,
      'updateTime': DateTime.now().millisecondsSinceEpoch,
      'updatePosition': position.inMicroseconds,
      'bufferedPosition': position.inMicroseconds,
      'duration': 30 * 1000000,
      'icyMetadata': null,
      'currentIndex': 0,
      'androidAudioSessionId': null,
    });
  }

  void uninstall() {
    _messenger
      ..setMockMethodCallHandler(_session, null)
      ..setMockMethodCallHandler(_main, null);
    for (final id in _ids) {
      _messenger
        ..setMockMethodCallHandler(
          MethodChannel('com.ryanheise.just_audio.methods.$id'),
          null,
        )
        ..setMockStreamHandler(
          EventChannel('com.ryanheise.just_audio.events.$id'),
          null,
        )
        ..setMockStreamHandler(
          EventChannel('com.ryanheise.just_audio.data.$id'),
          null,
        );
    }
  }
}

void main() {
  late _FakeJustAudioPlatform platform;

  setUp(() {
    platform = _FakeJustAudioPlatform()..install();
  });

  tearDown(() => platform.uninstall());

  Future<void> openSheet(
    WidgetTester tester, {
    JamendoTrack? track,
    VoidCallback? onConfirm,
  }) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => CupertinoPageScaffold(
          child: Center(
            child: CupertinoButton(
              onPressed: () => showCupertinoModalPopup<void>(
                context: context,
                builder: (_) => CatalogConfirmSheet(
                  track: track ?? buildJamendoTrack(),
                  onConfirm: onConfirm ?? () {},
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// Lets just_audio's internal streams settle. Some of its futures complete
  /// outside the fake-async zone, so a short real-async gap is needed.
  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 1)),
      );
    }
    await tester.pump(const Duration(milliseconds: 20));
  }

  /// Unmounts the tree so the AudioPlayer and its timers are disposed.
  Future<void> closeAll(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  group('CatalogConfirmSheet', () {
    testWidgets('shows track details, copy and actions', (tester) async {
      await openSheet(tester);

      expect(find.text('Sunny Day'), findsOneWidget);
      expect(find.text('The Testers · 3:05'), findsOneWidget);
      expect(
        find.text(
          "We'll analyze the mood of this track from Jamendo's free "
          'music library.',
        ),
        findsOneWidget,
      );
      expect(find.text('Preview (0:30)'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.play_fill), findsOneWidget);
      expect(find.text('Analyze this track'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // No album art URL -> placeholder.
      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(CupertinoIcons.music_note), findsOneWidget);
      // Short track -> no long-track warning.
      expect(find.textContaining('Tracks over 5 minutes'), findsNothing);

      await closeAll(tester);
    });

    testWidgets('warns that only the first 5 minutes of long tracks count', (
      tester,
    ) async {
      await openSheet(
        tester,
        track: buildJamendoTrack(
          duration: const Duration(minutes: 7, seconds: 42),
        ),
      );

      expect(find.text('The Testers · 7:42'), findsOneWidget);
      expect(
        find.text('Tracks over 5 minutes — only the first 5 will be analyzed.'),
        findsOneWidget,
      );

      await closeAll(tester);
    });

    testWidgets('falls back to placeholder when album art fails to load', (
      tester,
    ) async {
      await openSheet(
        tester,
        track: buildJamendoTrack(albumImageUrl: 'https://example.com/a.jpg'),
      );

      expect(find.byType(Image), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byIcon(CupertinoIcons.music_note), findsOneWidget);

      await closeAll(tester);
    });

    testWidgets('Analyze this track closes the sheet and calls onConfirm', (
      tester,
    ) async {
      var confirmed = 0;
      await openSheet(tester, onConfirm: () => confirmed++);

      await tester.tap(find.text('Analyze this track'));
      await tester.pumpAndSettle();

      expect(confirmed, 1);
      expect(find.byType(CatalogConfirmSheet), findsNothing);
      expect(find.text('open'), findsOneWidget);

      await closeAll(tester);
    });

    testWidgets('Cancel closes the sheet without confirming', (tester) async {
      var confirmed = 0;
      await openSheet(tester, onConfirm: () => confirmed++);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(confirmed, 0);
      expect(find.byType(CatalogConfirmSheet), findsNothing);

      await closeAll(tester);
    });

    testWidgets('preview loads a 30s clip, plays, pauses and replays', (
      tester,
    ) async {
      platform.loadGate = Completer<void>();
      await openSheet(tester);

      // Tap preview: loading state while the source is being prepared.
      await tester.tap(find.text('Preview (0:30)'));
      await flush(tester);
      expect(find.text('Loading…'), findsOneWidget);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

      // The clip is requested from the track's audio URL, capped at 30s.
      final source = platform.loadArgs.single['audioSource'] as Map;
      expect(source['type'], 'clipping');
      expect(source['end'], const Duration(seconds: 30).inMicroseconds);
      expect((source['child'] as Map)['uri'], 'https://example.com/audio.mp3');
      expect(platform.calls, isNot(contains('play')));

      // Finish loading -> playback starts.
      platform.loadGate!.complete();
      await flush(tester);
      platform.emit(_ready, position: const Duration(seconds: 12));
      await flush(tester);

      expect(platform.calls, contains('play'));
      expect(find.byIcon(CupertinoIcons.pause_fill), findsOneWidget);
      expect(find.text('0:12 / 0:30'), findsOneWidget);

      // Tap while playing -> pause.
      await tester.tap(find.text('0:12 / 0:30'));
      await flush(tester);
      expect(platform.calls, contains('pause'));
      expect(find.text('Preview (0:30)'), findsOneWidget);

      // Platform reports completion -> "Play again".
      platform.emit(_completed, position: const Duration(seconds: 30));
      await flush(tester);
      expect(find.text('Play again'), findsOneWidget);
      expect(
        find.byIcon(CupertinoIcons.arrow_counterclockwise),
        findsOneWidget,
      );

      // Replay restarts the preview from scratch.
      platform.loadGate = null;
      await tester.tap(find.text('Play again'));
      await flush(tester);
      expect(platform.loadArgs, hasLength(2));
      platform.emit(_ready);
      await flush(tester);
      expect(find.text('0:00 / 0:30'), findsOneWidget);

      await closeAll(tester);
    });

    testWidgets('tapping preview again after pausing restarts playback', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text('Preview (0:30)'));
      await flush(tester);
      platform.emit(_ready, position: const Duration(seconds: 5));
      await flush(tester);
      expect(find.text('0:05 / 0:30'), findsOneWidget);

      await tester.tap(find.text('0:05 / 0:30'));
      await flush(tester);
      expect(find.text('Preview (0:30)'), findsOneWidget);

      await tester.tap(find.text('Preview (0:30)'));
      await flush(tester);
      expect(platform.loadArgs, hasLength(2));

      await closeAll(tester);
    });

    testWidgets('elapsed time never exceeds the 30s preview', (tester) async {
      await openSheet(tester);

      await tester.tap(find.text('Preview (0:30)'));
      await flush(tester);
      platform.emit(_ready, position: const Duration(seconds: 45));
      await flush(tester);

      expect(find.text('0:30 / 0:30'), findsOneWidget);

      await closeAll(tester);
    });
  });
}
