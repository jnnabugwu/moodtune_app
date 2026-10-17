import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/sharing/sharing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(ShareChannel.name);
  late List<MethodCall> calls;
  Object? Function(MethodCall call)? reply;

  setUp(() {
    calls = [];
    reply = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          final handler = reply;
          return handler == null ? true : handler(call);
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('ShareChannel', () {
    test('isInstagramInstalled and isXInstalled call the platform', () async {
      final shareChannel = ShareChannel();

      expect(await shareChannel.isInstagramInstalled(), isTrue);
      expect(await shareChannel.isXInstalled(), isTrue);
      expect(calls.map((c) => c.method), [
        'isInstagramInstalled',
        'isXInstalled',
      ]);
    });

    test('shareToInstagramStory passes sticker, colours and app id', () async {
      final opened = await ShareChannel().shareToInstagramStory(
        stickerPath: '/tmp/card.png',
        topColor: '#2D1B69',
        bottomColor: '#C0392B',
        appId: '123',
      );

      expect(opened, isTrue);
      expect(calls.single.method, 'shareToInstagramStory');
      expect(calls.single.arguments, {
        'stickerPath': '/tmp/card.png',
        'topColor': '#2D1B69',
        'bottomColor': '#C0392B',
        'appId': '123',
      });
    });

    test('shareImageToX passes the image path and text', () async {
      reply = (_) => false;

      final sent = await ShareChannel().shareImageToX(
        imagePath: '/tmp/card.png',
        text: 'hello',
      );

      expect(sent, isFalse);
      expect(calls.single.arguments, {
        'imagePath': '/tmp/card.png',
        'text': 'hello',
      });
    });

    test('a null reply reads as false', () async {
      reply = (_) => null;

      expect(await ShareChannel().isXInstalled(), isFalse);
    });

    test('a missing native handler reads as false', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);

      expect(await ShareChannel().isInstagramInstalled(), isFalse);
    });

    test('platform errors propagate as PlatformException', () async {
      reply = (_) => throw PlatformException(code: 'share_failed');

      expect(
        () => ShareChannel().isInstagramInstalled(),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
