import 'package:moodtune_app/features/sharing/domain/entities/share_content.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_image.dart';

/// Turns [ShareContent] into the 1080×1350 PNG card (R3).
///
/// The widget that draws the card lives in presentation, so the concrete
/// renderer does too; the BLoC only sees this contract.
abstract class ShareCardRenderer {
  Future<ShareImage> render(ShareContent content);
}
