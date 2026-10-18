import 'dart:typed_data';

import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/features/sharing/sharing.dart';

/// Shared fixtures for the sharing feature tests.

ShareContent testShareContent({
  MoodIdentity mood = MoodIdentity.charged,
  String? title = 'Blinding Lights',
  String? artist = 'The Weeknd',
  List<String> descriptors = const ['intense', 'driving', 'bright'],
}) => ShareContent(
  mood: mood,
  title: title,
  artist: artist,
  descriptors: descriptors,
);

/// Opaque placeholder bytes, not a decodable PNG; the repository only
/// writes them.
final testShareImage = ShareImage(
  pngBytes: Uint8List.fromList(const [0x89, 0x50, 0x4E, 0x47, 1, 2, 3]),
  width: 1080,
  height: 1350,
);

ShareCaption testShareCaption(ShareTarget target) => ShareCaption(
  body:
      'My song "Blinding Lights" feels Charged 🎧 Find your song\'s mood '
      'on MoodTune',
  link: ShareLinks.forTarget(target),
);

ShareRequest testShareRequest(ShareTarget target) => ShareRequest(
  target: target,
  image: testShareImage,
  caption: testShareCaption(target),
  backgroundTopColor: 0xFF2D1B69,
  backgroundBottomColor: 0xFFC0392B,
);
