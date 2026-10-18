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
/// The PNG is written to its own temp folder, only for targets that attach
/// it, and deleted afterwards (R3). Platform exceptions with code
/// `unavailable` map to [ShareUnavailableFailure]; everything else to
/// [ShareFailure].
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
    final card = _TempCard(_tempDirectory, request.image.pngBytes);
    try {
      final outcome = switch (request.target) {
        ShareTarget.instagramStory => await _shareToInstagram(request, card),
        ShareTarget.x => await _shareToX(request, card),
        ShareTarget.system => await _shareToSystem(request, card),
      };
      return Right(outcome);
    } on PlatformException catch (e, stack) {
      if (e.code == 'unavailable') {
        return Left(ShareUnavailableFailure(e.message ?? e.code));
      }
      await _report(e, stack);
      return Left(ShareFailure(e.message ?? e.code));
    } on FileSystemException catch (e, stack) {
      await _report(e, stack);
      return Left(ShareRenderFailure(e.message));
    } on Exception catch (e, stack) {
      await _report(e, stack);
      return Left(ShareFailure(e.toString()));
    } finally {
      await card.delete();
    }
  }

  /// Reporting is best effort: a telemetry outage must not turn a handled
  /// failure into an unhandled one.
  Future<void> _report(Object error, StackTrace stack) async {
    try {
      await _reportError(error, stack);
      // Any failure while reporting is swallowed, Errors included.
      // ignore: avoid_catches_without_on_clauses
    } catch (e) {
      talker.warning('share: could not report an error: $e');
    }
  }

  Future<ShareOutcome> _shareToInstagram(
    ShareRequest request,
    _TempCard card,
  ) async {
    if (_metaAppId.isEmpty) {
      throw PlatformException(
        code: 'unavailable',
        message: 'META_APP_ID is not set',
      );
    }
    final opened = await _channel.shareToInstagramStory(
      stickerPath: (await card.file).path,
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

  Future<ShareOutcome> _shareToX(ShareRequest request, _TempCard card) async {
    final installed = await _channel.isXInstalled();
    if (!installed) return await _openXWebIntent(request);

    if (_platform == TargetPlatform.android) {
      final sent = await _channel.shareImageToX(
        imagePath: (await card.file).path,
        text: request.caption.full,
      );
      if (sent) return ShareOutcome.completed;
      // X couldn't take the image: fall back to the web intent (R5).
      return await _openXWebIntent(request);
    }
    // iOS can't target one app; the system sheet lists X.
    return await _shareToSystem(request, card);
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

  Future<ShareOutcome> _shareToSystem(
    ShareRequest request,
    _TempCard card,
  ) async {
    final file = await card.file;
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

  /// `#RRGGBB` for Instagram's background colour extras.
  static String _hex(int argb) =>
      '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

/// The card PNG for one share, written on first use into a folder of its
/// own, so concurrent shares never overwrite or delete each other's file.
class _TempCard {
  _TempCard(this._root, this._pngBytes);

  final Directory _root;
  final List<int> _pngBytes;
  Directory? _dir;
  Future<File>? _file;

  Future<File> get file => _file ??= _write();

  Future<File> _write() async {
    final parent = Directory('${_root.path}/moodtune_share');
    await parent.create(recursive: true);
    final dir = _dir = await parent.createTemp('card_');
    final file = File('${dir.path}/moodtune-mood.png');
    return await file.writeAsBytes(_pngBytes, flush: true);
  }

  /// Removes the folder, including a partly written file.
  Future<void> delete() async {
    final dir = _dir;
    if (dir == null) return;
    try {
      if (dir.existsSync()) await dir.delete(recursive: true);
    } on FileSystemException catch (e) {
      talker.warning('share: could not delete the card: ${e.message}');
    }
  }
}
