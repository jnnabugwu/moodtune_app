import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moodtune_app/features/on_device_mood/data/yamnet_engine.dart';
import 'package:moodtune_app/features/on_device_mood/domain/yamnet_mood_model.dart';

const yamnetMoodConfigAsset = 'assets/models/yamnet_mood.json';
const yamnetLicenseAsset = 'assets/models/YAMNET_LICENSE.txt';

/// The config `version` this code reads.
const yamnetMoodConfigVersion = 1;

/// Loads the mood and tag config exported by the spike.
///
/// Throws [FormatException] if the config is another version or was
/// exported for framing other than [YamnetEngine]'s, which would otherwise
/// load fine and score the wrong windows.
Future<YamnetMoodModel> loadYamnetMoodModel({AssetBundle? bundle}) async {
  final text = await (bundle ?? rootBundle).loadString(yamnetMoodConfigAsset);
  final json = jsonDecode(text) as Map<String, Object?>;
  if (json['version'] != yamnetMoodConfigVersion) {
    throw FormatException(
      'YAMNet mood config version ${json['version']}, '
      'expected $yamnetMoodConfigVersion',
    );
  }
  const input = {
    'sampleRate': YamnetEngine.sampleRate,
    'frameSamples': YamnetEngine.frameSamples,
    'hopSamples': YamnetEngine.hopSamples,
  };
  if (json['input'] case final Map<String, Object?> exported
      when input.entries.every((e) => exported[e.key] == e.value)) {
    return YamnetMoodModel.fromJson(json);
  }
  throw FormatException(
    'YAMNet mood config input ${json['input']} does not match $input',
  );
}

/// Adds YAMNet's Apache 2.0 notice to the app's license registry.
void registerYamnetLicense({AssetBundle? bundle}) {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'YAMNet',
    ], await (bundle ?? rootBundle).loadString(yamnetLicenseAsset));
  });
}
