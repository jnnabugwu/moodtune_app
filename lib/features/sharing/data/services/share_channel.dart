import 'package:flutter/services.dart';
import 'package:moodtune_app/core/logging/talker.dart';

/// Dart side of the `moodtune/share` platform channel (D2).
///
/// Native code lives in `ios/Runner/AppDelegate.swift` (`ShareChannel`) and
/// `android/.../MainActivity.kt` (`ShareChannel`). Methods:
///
/// - `isInstagramInstalled` / `isXInstalled` → bool
/// - `shareToInstagramStory {stickerPath, topColor, bottomColor, appId}`
///   → true when Instagram opened, false when it isn't installed
/// - `shareImageToX {imagePath, text}` → true when X opened, false when
///   the platform can't target X directly (iOS; the caller then uses the
///   system sheet)
///
/// Native code reports a missing app by returning `false`, never by
/// throwing; the repository turns that into its `unavailable` failure. A
/// [PlatformException] from native code is a real failure.
class ShareChannel {
  ShareChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(name);

  static const name = 'moodtune/share';

  final MethodChannel _channel;

  Future<bool> isInstagramInstalled() => _invokeBool('isInstagramInstalled');

  Future<bool> isXInstalled() => _invokeBool('isXInstalled');

  /// Opens Instagram's Story composer with the PNG at [stickerPath] as a
  /// sticker over a vertical gradient from [topColor] to [bottomColor]
  /// (`#RRGGBB`). [appId] is the Meta App ID (`source_application`).
  Future<bool> shareToInstagramStory({
    required String stickerPath,
    required String topColor,
    required String bottomColor,
    required String appId,
  }) => _invokeBool('shareToInstagramStory', {
    'stickerPath': stickerPath,
    'topColor': topColor,
    'bottomColor': bottomColor,
    'appId': appId,
  });

  /// Sends the PNG at [imagePath] plus [text] straight to X. Returns false
  /// when the platform can't target one app (iOS).
  Future<bool> shareImageToX({
    required String imagePath,
    required String text,
  }) => _invokeBool('shareImageToX', {'imagePath': imagePath, 'text': text});

  Future<bool> _invokeBool(String method, [Map<String, Object?>? args]) async {
    try {
      return await _channel.invokeMethod<bool>(method, args) ?? false;
    } on MissingPluginException {
      // No native handler on this platform (tests, desktop). Logged so a
      // missing registration on a phone build doesn't pass for "not
      // installed".
      talker.warning('share: no native handler for $name.$method');
      return false;
    }
  }
}
