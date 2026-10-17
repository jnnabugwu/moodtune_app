import 'package:moodtune_app/features/sharing/data/services/widget_rasterizer.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_content.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_image.dart';
import 'package:moodtune_app/features/sharing/domain/repositories/share_card_renderer.dart';
import 'package:moodtune_app/features/sharing/presentation/widgets/mood_share_card.dart';

/// Renders [MoodShareCard] offscreen to the 1080×1350 PNG (R3).
class MoodShareCardRenderer implements ShareCardRenderer {
  const MoodShareCardRenderer({
    WidgetRasterizer rasterizer = const WidgetRasterizer(),
  }) : _rasterizer = rasterizer;

  final WidgetRasterizer _rasterizer;

  @override
  Future<ShareImage> render(ShareContent content) async {
    final bytes = await _rasterizer.rasterize(
      MoodShareCard(content: content),
      logicalSize: MoodShareCard.logicalSize,
      pixelRatio: MoodShareCard.exportPixelRatio,
    );
    final size = MoodShareCard.logicalSize * MoodShareCard.exportPixelRatio;
    return ShareImage(
      pngBytes: bytes,
      width: size.width.round(),
      height: size.height.round(),
    );
  }
}
