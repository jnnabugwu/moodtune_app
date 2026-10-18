import 'package:moodtune_app/core/error/failures.dart';

/// The target app rejected the share or the share call itself threw (R10).
class ShareFailure extends Failure {
  const ShareFailure(super.message);
}

/// The target can't be used right now: the app isn't installed, the Meta
/// App ID is missing, or the platform has no share support.
class ShareUnavailableFailure extends Failure {
  const ShareUnavailableFailure(super.message);
}

/// Rasterizing or writing the card failed (R10).
class ShareRenderFailure extends Failure {
  const ShareRenderFailure(super.message);
}
