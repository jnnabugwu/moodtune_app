import 'package:moodtune_app/features/sharing/domain/entities/share_outcome.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_request.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_target.dart';
import 'package:moodtune_app/utils/typedef.dart';

/// Hands a rendered card to a target app. The plugin and platform-channel
/// layer sits behind this contract; presentation never imports it (D2).
abstract class ShareRepository {
  /// Whether [target] can be offered, directly or through a fallback, and
  /// any config it needs is present. [ShareTarget.system] is always
  /// available (R1); [ShareTarget.x] is too, because the web intent covers
  /// a missing app (R5). Implementations return false instead of throwing.
  Future<bool> isAvailable(ShareTarget target);

  /// Shares [request] and reports how it ended. A user cancelling is a
  /// [ShareOutcome.dismissed], not a failure (R10).
  ResultFuture<ShareOutcome> share(ShareRequest request);
}
