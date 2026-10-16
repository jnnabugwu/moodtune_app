import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';

/// Downloads a catalog track to a temp file so it can be classified on the
/// device. Jamendo streams are full tracks (~5 MB), so the size is capped
/// and the download aborted if a server sends more.
class DioAudioDownloader implements AudioDownloader {
  DioAudioDownloader({Dio? dio, this.maxBytes = 30 * 1024 * 1024})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );

  final Dio _dio;
  final int maxBytes;

  @override
  Future<File> download(String url) async {
    final dir = await Directory.systemTemp.createTemp('moodtune_audio');
    final file = File('${dir.path}/track${_extension(url)}');
    final cancel = CancelToken();
    try {
      await _dio.download(
        url,
        file.path,
        cancelToken: cancel,
        onReceiveProgress: (received, _) {
          if (received > maxBytes) cancel.cancel('larger than $maxBytes bytes');
        },
      );
      return file;
    } on Object {
      await dir.delete(recursive: true).catchError((_) => dir);
      rethrow;
    }
  }

  /// AVAudioFile picks its decoder from the extension. Jamendo stream URLs
  /// have none (`/?trackid=...&format=mp32`), so default to `.mp3`.
  static String _extension(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final match = RegExp(
      r'\.(mp3|m4a|aac|wav|flac|ogg)$',
    ).firstMatch(path.toLowerCase());
    return match == null ? '.mp3' : '.${match.group(1)}';
  }
}
