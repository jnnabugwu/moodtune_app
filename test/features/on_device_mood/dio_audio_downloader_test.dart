import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/features/on_device_mood/data/dio_audio_downloader.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;

  setUp(() => dio = MockDio());

  void stubDownload(Future<Response<dynamic>> Function(Invocation) answer) =>
      when(
        () => dio.download(
          any<String>(),
          any<dynamic>(),
          cancelToken: any(named: 'cancelToken'),
          onReceiveProgress: any(named: 'onReceiveProgress'),
        ),
      ).thenAnswer(answer);

  group('DioAudioDownloader', () {
    test('saves Jamendo streams (no extension) as .mp3', () async {
      stubDownload(
        (_) async =>
            Response(requestOptions: RequestOptions(), statusCode: 200),
      );

      final path = await DioAudioDownloader(
        dio: dio,
      ).download('https://prod-1.storage.jamendo.com/?trackid=1&format=mp32');
      addTearDown(() => File(path).parent.delete(recursive: true));

      expect(path, endsWith('/track.mp3'));
    });

    test('keeps a known extension from the URL', () async {
      stubDownload(
        (_) async =>
            Response(requestOptions: RequestOptions(), statusCode: 200),
      );

      final path = await DioAudioDownloader(
        dio: dio,
      ).download('https://example.com/audio/song.m4a?sig=x');
      addTearDown(() => File(path).parent.delete(recursive: true));

      expect(path, endsWith('/track.m4a'));
    });

    test('cancels a download that grows past the size cap', () async {
      CancelToken? token;
      stubDownload((invocation) async {
        token = invocation.namedArguments[#cancelToken] as CancelToken;
        final onProgress =
            invocation.namedArguments[#onReceiveProgress] as ProgressCallback;
        onProgress(11, -1);
        return Response(requestOptions: RequestOptions(), statusCode: 200);
      });

      final path = await DioAudioDownloader(
        dio: dio,
        maxBytes: 10,
      ).download('https://audio');
      addTearDown(() => File(path).parent.delete(recursive: true));

      expect(token?.isCancelled, isTrue);
    });

    test('deletes the temp folder and rethrows when it fails', () async {
      String? savePath;
      stubDownload((invocation) async {
        savePath = invocation.positionalArguments[1] as String;
        throw DioException(requestOptions: RequestOptions());
      });

      await expectLater(
        DioAudioDownloader(dio: dio).download('https://audio'),
        throwsA(isA<DioException>()),
      );
      expect(Directory(File(savePath!).parent.path).existsSync(), isFalse);
    });

    test('cancels a download that runs past the time limit', () async {
      CancelToken? token;
      stubDownload((invocation) async {
        token = invocation.namedArguments[#cancelToken] as CancelToken;
        throw await token!.whenCancel;
      });

      await expectLater(
        DioAudioDownloader(
          dio: dio,
          timeLimit: const Duration(milliseconds: 10),
        ).download('https://audio'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      expect(token?.isCancelled, isTrue);
    });
  });
}
