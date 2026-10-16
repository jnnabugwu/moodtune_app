import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moodtune_app/features/on_device_mood/domain/yamnet_mood_model.dart';

const yamnetMoodConfigAsset = 'assets/models/yamnet_mood.json';
const yamnetLicenseAsset = 'assets/models/YAMNET_LICENSE.txt';

/// Loads the mood and tag config exported by the spike.
Future<YamnetMoodModel> loadYamnetMoodModel({AssetBundle? bundle}) async {
  final json = await (bundle ?? rootBundle).loadString(yamnetMoodConfigAsset);
  return YamnetMoodModel.fromJson(jsonDecode(json) as Map<String, Object?>);
}

/// Adds YAMNet's Apache 2.0 notice to the app's license registry.
void registerYamnetLicense({AssetBundle? bundle}) {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'YAMNet',
    ], await (bundle ?? rootBundle).loadString(yamnetLicenseAsset));
  });
}
