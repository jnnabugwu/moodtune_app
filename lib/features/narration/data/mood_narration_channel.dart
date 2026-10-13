import 'package:flutter/services.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/narration/domain/mood_narrator.dart';

/// [NarrationEngine] backed by Apple's on-device Foundation Models through
/// the `moodtune/narration` method channel (see ios/Runner/AppDelegate.swift).
///
/// Platforms without a handler (Android, older iOS builds) throw
/// [MissingPluginException], which [MoodNarrator] treats as unavailable.
class MoodNarrationChannel implements NarrationEngine {
  MoodNarrationChannel({
    MethodChannel channel = const MethodChannel('moodtune/narration'),
  }) : _channel = channel;

  final MethodChannel _channel;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _channel.invokeMethod<bool>('isAvailable') ?? false;
    } on MissingPluginException {
      return false;
    }
  }

  /// The native side replies with `text` and which instruction set produced
  /// it (`full`, or `minimal` after an `unsupportedLanguageOrLocale` retry).
  @override
  Future<String> narrate(NarrationInput input) async {
    final reply = await _channel.invokeMapMethod<String, String>(
      'narrate',
      input.toMap(),
    );
    final text = reply?['text'];
    if (text == null) {
      throw PlatformException(code: 'empty', message: 'No narration returned');
    }
    talker.info('Narration instructions: ${reply?['instructions']}');
    return text;
  }
}
