import 'package:moodtune_app/features/sharing/domain/entities/share_target.dart';

/// Links that go into captions (D1). Only `getmoodtune.com` is ours; never
/// link to any other MoodTune-looking domain.
abstract final class ShareLinks {
  static const String host = 'getmoodtune.com';

  /// The public site as shown on the card's bottom row.
  static const String displayDomain = host;

  /// `https://getmoodtune.com/?utm_source=<target>&utm_medium=share`.
  static Uri forTarget(ShareTarget target) => Uri.https(host, '/', {
    'utm_source': target.utmSource,
    'utm_medium': 'share',
  });
}
