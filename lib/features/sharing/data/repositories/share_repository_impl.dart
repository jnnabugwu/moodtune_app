import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/sharing/data/services/share_channel.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_outcome.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_request.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_target.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_repository.dart';
import 'package:moodtune_app/features/sharing/domain/share_failures.dart';
import 'package:moodtune_app/utils/typedef.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

/// Calls the platform share sheet; defaults to `share_plus`.
typedef SystemShare = Future<ShareResult> Function(ShareParams params);

/// Opens a URL in the browser; defaults to `url_launcher`.
typedef OpenUrl = Future<bool> Function(Uri url);

/// Reports an unexpected error; defaults to Sentry.
typedef ReportError = Future<void> Function(Object error, StackTrace stack);

/// Routes a [ShareRequest] to Instagram (own channel), X (targeted intent
/// on Android, system sheet on iOS, web intent when X is missing) or the
/// system sheet (`share_plus`), and maps every exception to a `Failure`.
///
/// The PNG is written to a temp file for the call and deleted afterwards
/// (R3). Platform exceptions with code `unavailable` map to
/// [ShareUnavailableFailure]; everything else to [ShareFailure].
class ShareRepositoryImpl implements ShareRepository {
  ShareRepositoryImpl({
    required String metaAppId,
    ShareChannel? channel,
    SystemShare? systemShare,
    OpenUrl? openUrl,
    ReportError? reportError,
    Directory? tempDirectory,
    TargetPlatform? platform,
  }) : _metaAppId = metaAppId.trim(),
       _channel = channel ?? ShareChannel(),
       _systemShare = systemShare ?? SharePlus.instance.share,
       _openUrl = openUrl ?? _launchExternal,
       _reportError = reportError ?? _reportToSentry,
       _tempDirectory = tempDirectory ?? Directory.systemTemp,
       _platform = platform ?? defaultTargetPlatform;

  final String _metaAppId;
  final ShareChannel _channel;
  final SystemShare _systemShare;
  final OpenUrl _openUrl;
  final ReportError _reportError;
  final Directory _tempDirectory;
  final TargetPlatform _platform;

  static const _xWebIntent = 'https://x.com/intent/post';

  static Future<bool> _launchExternal(Uri url) =>
      launcher.launchUrl(url, mode: launcher.LaunchMode.externalApplication);

  static Future<void> _reportToSentry(Object error, StackTrace stack) async {
    await Sentry.captureException(error, stackTrace: stack);
  }

  @override
  Future<bool> isAvailable(ShareTarget target) async {
    switch (target) {
      case ShareTarget.system:
        return true;
      case ShareTarget.x:
        // X stays offered: without the app the web intent takes over (R5).
        return true;
      case ShareTarget.instagramStory:
        if (_metaAppId.isEmpty) {
          talker.warning(
            'share: META_APP_ID is empty, hiding Instagram Stories',
          );
          return false;
        }
        try {
          return await _channel.isInstagramInstalled();
        } on PlatformException catch (e) {
          talker.warning('share: isInstagramInstalled failed: ${e.message}');
          return false;
        }
    }
  }

  @override
  ResultFuture<ShareOutcome> share(ShareRequest request) async {
    File? file;
    try {
      file = await _writeTempPng(request);
      final outcome = switch (request.target) {
        ShareTarget.instagramStory => await _shareToInstagram(request, file),
        ShareTarget.x => await _shareToX(request, file),
        ShareTarget.system => await _shareToSystem(request, file),
      };
      return Right(outcome);
    } on PlatformException catch (e, stack) {
      if (e.code == 'unavailable') {
        return Left(ShareUnavailableFailure(e.message ?? e.code));
      }
      await _reportError(e, stack);
      return Left(ShareFailure(e.message ?? e.code));
    } on FileSystemException catch (e, stack) {
      await _reportError(e, stack);
      return Left(ShareRenderFailure(e.message));
    } on Exception catch (e, stack) {
      await _reportError(e, stack);
      return Left(ShareFailure(e.toString()));
    } finally {
      await _delete(file);
    }
  }

  Future<ShareOutcome> _shareToInstagram(
    ShareRequest request,
    File file,
  ) async {
    if (_metaAppId.isEmpty) {
      throw PlatformException(
        code: 'unavailable',
        message: 'META_APP_ID is not set',
      );
    }
    final opened = await _channel.shareToInstagramStory(
      stickerPath: file.path,
      topColor: _hex(request.backgroundTopColor),
      bottomColor: _hex(request.backgroundBottomColor),
      appId: _metaAppId,
    );
    if (!opened) {
      throw PlatformException(
        code: 'unavailable',
        message: 'Instagram is not installed',
      );
    }
    // Instagram gives no result back; opening the composer is completion.
    return ShareOutcome.completed;
  }

  Future<ShareOutcome> _shareToX(ShareRequest request, File file) async {
    final installed = await _channel.isXInstalled();
    if (!installed) return await _openXWebIntent(request);

    if (_platform == TargetPlatform.android) {
      final sent = await _channel.shareImageToX(
        imagePath: file.path,
        text: request.caption.full,
      );
      if (sent) return ShareOutcome.completed;
      // X couldn't take the image: fall back to the web intent (R5).
      return await _openXWebIntent(request);
    }
    // iOS can't target one app; the system sheet lists X.
    return await _shareToSystem(request, file);
  }

  Future<ShareOutcome> _openXWebIntent(ShareRequest request) async {
    final url = Uri.parse(_xWebIntent).replace(
      queryParameters: {
        'text': request.caption.body,
        'url': request.caption.link.toString(),
      },
    );
    final opened = await _openUrl(url);
    if (!opened) {
      throw PlatformException(
        code: 'launch_failed',
        message: 'Could not open the X web intent',
      );
    }
    return ShareOutcome.completed;
  }

  Future<ShareOutcome> _shareToSystem(ShareRequest request, File file) async {
    final result = await _systemShare(
      ShareParams(
        text: request.caption.full,
        files: [XFile(file.path, mimeType: 'image/png')],
        fileNameOverrides: const ['moodtune-mood.png'],
        sharePositionOrigin: request.sharePositionOrigin,
      ),
    );
    return switch (result.status) {
      ShareResultStatus.dismissed => ShareOutcome.dismissed,
      ShareResultStatus.success ||
      ShareResultStatus.unavailable => ShareOutcome.completed,
    };
  }

  Future<File> _writeTempPng(ShareRequest request) async {
    final dir = Directory('${_tempDirectory.path}/moodtune_share');
    await dir.create(recursive: true);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final file = File('${dir.path}/moodtune-$stamp.png');
    return await file.writeAsBytes(request.image.pngBytes, flush: true);
  }

  Future<void> _delete(File? file) async {
    if (file == null) return;
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException catch (e) {
      talker.warning('share: could not delete ${file.path}: ${e.message}');
    }
  }

  /// `#RRGGBB` for Instagram's background colour extras.
  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
