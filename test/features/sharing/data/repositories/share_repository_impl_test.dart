import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/sharing/sharing.dart';
import 'package:share_plus/share_plus.dart';

import '../../sharing_fixtures.dart';

class MockShareChannel extends Mock implements ShareChannel {}

void main() {
  late MockShareChannel channel;
  late Directory tempDir;
  late List<ShareParams> systemShares;
  late List<Uri> openedUrls;
  late List<Object> reported;
  var systemResult = const ShareResult('x', ShareResultStatus.success);
  var openUrlResult = true;

  setUpAll(talker.disable);

  tearDownAll(talker.enable);

  setUp(() {
    channel = MockShareChannel();
    tempDir = Directory.systemTemp.createTempSync('share_repo_test');
    systemShares = [];
    openedUrls = [];
    reported = [];
    systemResult = const ShareResult('x', ShareResultStatus.success);
    openUrlResult = true;
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  ShareRepositoryImpl buildRepository({
    String metaAppId = '1234567890',
    TargetPlatform platform = TargetPlatform.iOS,
  }) => ShareRepositoryImpl(
    metaAppId: metaAppId,
    channel: channel,
    systemShare: (params) async {
      systemShares.add(params);
      // The temp file must still exist while the share call runs.
      expect(File(params.files!.single.path).existsSync(), isTrue);
      return systemResult;
    },
    openUrl: (url) async {
      openedUrls.add(url);
      return openUrlResult;
    },
    reportError: (error, _) async => reported.add(error),
    tempDirectory: tempDir,
    platform: platform,
  );

  List<File> tempPngs() => Directory(
    '${tempDir.path}/moodtune_share',
  ).listSync().whereType<File>().toList();

  group('isAvailable', () {
    test('"More…" and X are always offered', () async {
      final repository = buildRepository();

      expect(await repository.isAvailable(ShareTarget.system), isTrue);
      expect(await repository.isAvailable(ShareTarget.x), isTrue);
      verifyNever(() => channel.isXInstalled());
    });

    test('Instagram follows the installed check (R1)', () async {
      when(() => channel.isInstagramInstalled()).thenAnswer((_) async => true);
      expect(
        await buildRepository().isAvailable(ShareTarget.instagramStory),
        isTrue,
      );

      when(() => channel.isInstagramInstalled()).thenAnswer((_) async => false);
      expect(
        await buildRepository().isAvailable(ShareTarget.instagramStory),
        isFalse,
      );
    });

    test('Instagram is hidden without a META_APP_ID (R4)', () async {
      expect(
        await buildRepository(
          metaAppId: '  ',
        ).isAvailable(ShareTarget.instagramStory),
        isFalse,
      );
      verifyNever(() => channel.isInstagramInstalled());
    });

    test('Instagram is hidden when the check throws', () async {
      when(
        () => channel.isInstagramInstalled(),
      ).thenThrow(PlatformException(code: 'boom'));

      expect(
        await buildRepository().isAvailable(ShareTarget.instagramStory),
        isFalse,
      );
    });
  });

  group('share to Instagram Stories', () {
    test('sends the sticker path, gradient colours and app id', () async {
      String? stickerPath;
      when(
        () => channel.shareToInstagramStory(
          stickerPath: any(named: 'stickerPath'),
          topColor: any(named: 'topColor'),
          bottomColor: any(named: 'bottomColor'),
          appId: any(named: 'appId'),
        ),
      ).thenAnswer((invocation) async {
        stickerPath = invocation.namedArguments[#stickerPath] as String;
        expect(File(stickerPath!).readAsBytesSync(), testShareImage.pngBytes);
        return true;
      });

      final result = await buildRepository().share(
        testShareRequest(ShareTarget.instagramStory),
      );

      expect(result.toOption().toNullable(), ShareOutcome.completed);
      verify(
        () => channel.shareToInstagramStory(
          stickerPath: stickerPath!,
          topColor: '#2D1B69',
          bottomColor: '#C0392B',
          appId: '1234567890',
        ),
      ).called(1);
      // The temp file is deleted once the share call returns (R3).
      expect(tempPngs(), isEmpty);
    });

    test('maps "not installed" to ShareUnavailableFailure', () async {
      when(
        () => channel.shareToInstagramStory(
          stickerPath: any(named: 'stickerPath'),
          topColor: any(named: 'topColor'),
          bottomColor: any(named: 'bottomColor'),
          appId: any(named: 'appId'),
        ),
      ).thenAnswer((_) async => false);

      final result = await buildRepository().share(
        testShareRequest(ShareTarget.instagramStory),
      );

      expect(
        result.swap().toOption().toNullable(),
        isA<ShareUnavailableFailure>(),
      );
      expect(reported, isEmpty);
      expect(tempPngs(), isEmpty);
    });

    test('fails as unavailable without a META_APP_ID', () async {
      final result = await buildRepository(
        metaAppId: '',
      ).share(testShareRequest(ShareTarget.instagramStory));

      expect(
        result.swap().toOption().toNullable(),
        isA<ShareUnavailableFailure>(),
      );
      verifyNever(
        () => channel.shareToInstagramStory(
          stickerPath: any(named: 'stickerPath'),
          topColor: any(named: 'topColor'),
          bottomColor: any(named: 'bottomColor'),
          appId: any(named: 'appId'),
        ),
      );
    });

    test(
      'maps other platform errors to ShareFailure and reports them',
      () async {
        final error = PlatformException(code: 'read_failed', message: 'nope');
        when(
          () => channel.shareToInstagramStory(
            stickerPath: any(named: 'stickerPath'),
            topColor: any(named: 'topColor'),
            bottomColor: any(named: 'bottomColor'),
            appId: any(named: 'appId'),
          ),
        ).thenThrow(error);

        final result = await buildRepository().share(
          testShareRequest(ShareTarget.instagramStory),
        );

        expect(
          result.swap().toOption().toNullable(),
          const ShareFailure('nope'),
        );
        expect(reported, [error]);
        expect(tempPngs(), isEmpty);
      },
    );
  });

  group('share to X', () {
    test('on Android sends the image straight to X when installed', () async {
      when(() => channel.isXInstalled()).thenAnswer((_) async => true);
      when(
        () => channel.shareImageToX(
          imagePath: any(named: 'imagePath'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => true);

      final request = testShareRequest(ShareTarget.x);
      final result = await buildRepository(
        platform: TargetPlatform.android,
      ).share(request);

      expect(result.toOption().toNullable(), ShareOutcome.completed);
      verify(
        () => channel.shareImageToX(
          imagePath: any(named: 'imagePath'),
          text: request.caption.full,
        ),
      ).called(1);
      expect(systemShares, isEmpty);
      expect(openedUrls, isEmpty);
    });

    test('on iOS uses the system sheet when X is installed', () async {
      when(() => channel.isXInstalled()).thenAnswer((_) async => true);

      final request = testShareRequest(ShareTarget.x);
      final result = await buildRepository().share(request);

      expect(result.toOption().toNullable(), ShareOutcome.completed);
      expect(systemShares.single.text, request.caption.full);
      expect(systemShares.single.files, hasLength(1));
      verifyNever(
        () => channel.shareImageToX(
          imagePath: any(named: 'imagePath'),
          text: any(named: 'text'),
        ),
      );
    });

    test('opens the web intent when X is not installed (R5, AC4)', () async {
      when(() => channel.isXInstalled()).thenAnswer((_) async => false);

      final request = testShareRequest(ShareTarget.x);
      final result = await buildRepository().share(request);

      expect(result.toOption().toNullable(), ShareOutcome.completed);
      final url = openedUrls.single;
      expect(url.scheme, 'https');
      expect(url.host, 'x.com');
      expect(url.path, '/intent/post');
      expect(url.queryParameters['text'], request.caption.body);
      expect(url.queryParameters['url'], request.caption.link.toString());
      expect(systemShares, isEmpty);
    });

    test('falls back to the web intent when X rejects the image', () async {
      when(() => channel.isXInstalled()).thenAnswer((_) async => true);
      when(
        () => channel.shareImageToX(
          imagePath: any(named: 'imagePath'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => false);

      final result = await buildRepository(
        platform: TargetPlatform.android,
      ).share(testShareRequest(ShareTarget.x));

      expect(result.toOption().toNullable(), ShareOutcome.completed);
      expect(openedUrls, hasLength(1));
    });

    test('fails when the browser cannot open the web intent', () async {
      when(() => channel.isXInstalled()).thenAnswer((_) async => false);
      openUrlResult = false;

      final result = await buildRepository().share(
        testShareRequest(ShareTarget.x),
      );

      expect(result.swap().toOption().toNullable(), isA<ShareFailure>());
      expect(reported, hasLength(1));
    });
  });

  group('share to the system sheet', () {
    test('passes image, caption and popover origin (R6)', () async {
      const origin = Rect.fromLTWH(10, 20, 30, 40);
      final request = ShareRequest(
        target: ShareTarget.system,
        image: testShareImage,
        caption: testShareCaption(ShareTarget.system),
        backgroundTopColor: 0,
        backgroundBottomColor: 0,
        sharePositionOrigin: origin,
      );

      final result = await buildRepository().share(request);

      expect(result.toOption().toNullable(), ShareOutcome.completed);
      final params = systemShares.single;
      expect(params.text, request.caption.full);
      expect(params.sharePositionOrigin, origin);
      expect(params.files!.single.mimeType, 'image/png');
      expect(params.fileNameOverrides, ['moodtune-mood.png']);
      expect(tempPngs(), isEmpty);
    });

    test('a dismissed sheet is an outcome, not a failure (R10, AC7)', () async {
      systemResult = const ShareResult('', ShareResultStatus.dismissed);

      final result = await buildRepository().share(
        testShareRequest(ShareTarget.system),
      );

      expect(result.toOption().toNullable(), ShareOutcome.dismissed);
      expect(reported, isEmpty);
    });

    test('an unavailable result counts as completed', () async {
      systemResult = ShareResult.unavailable;

      final result = await buildRepository().share(
        testShareRequest(ShareTarget.system),
      );

      expect(result.toOption().toNullable(), ShareOutcome.completed);
    });

    test('maps a throwing share call to ShareFailure', () async {
      final repository = ShareRepositoryImpl(
        metaAppId: '1',
        channel: channel,
        systemShare: (_) async => throw const FormatException('bad'),
        openUrl: (_) async => true,
        reportError: (error, _) async => reported.add(error),
        tempDirectory: tempDir,
        platform: TargetPlatform.iOS,
      );

      final result = await repository.share(
        testShareRequest(ShareTarget.system),
      );

      expect(result.swap().toOption().toNullable(), isA<ShareFailure>());
      expect(reported.single, isA<FormatException>());
      expect(tempPngs(), isEmpty);
    });

    test('maps a file system error to ShareRenderFailure', () async {
      final repository = ShareRepositoryImpl(
        metaAppId: '1',
        channel: channel,
        systemShare: (_) async => systemResult,
        openUrl: (_) async => true,
        reportError: (error, _) async => reported.add(error),
        // A file where the directory should be makes the write fail.
        tempDirectory: Directory(File('${tempDir.path}/blocker').path)
          ..parent.createSync(),
        platform: TargetPlatform.iOS,
      );
      File('${tempDir.path}/blocker').writeAsStringSync('not a dir');

      final result = await repository.share(
        testShareRequest(ShareTarget.system),
      );

      expect(result.swap().toOption().toNullable(), isA<ShareRenderFailure>());
      expect(reported.single, isA<FileSystemException>());
    });
  });
}
