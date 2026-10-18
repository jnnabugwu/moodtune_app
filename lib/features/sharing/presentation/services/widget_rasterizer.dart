import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Rasterizes a widget offscreen to PNG bytes (R3).
///
/// Builds a private render tree (its own [PipelineOwner] and [BuildOwner])
/// so the widget never appears on screen and the capture does not depend on
/// a frame being scheduled. Text scaling is pinned to 1.0 so the card looks
/// the same whatever the device's accessibility settings.
class WidgetRasterizer {
  const WidgetRasterizer();

  /// Renders [widget] laid out at [logicalSize] and captures it at
  /// [pixelRatio]; the PNG is `logicalSize * pixelRatio` pixels.
  Future<Uint8List> rasterize(
    Widget widget, {
    required Size logicalSize,
    required double pixelRatio,
  }) async {
    final binding = WidgetsFlutterBinding.ensureInitialized();
    final view = binding.platformDispatcher.views.first;

    final boundary = RenderRepaintBoundary();
    final renderView = RenderView(
      view: view,
      configuration: ViewConfiguration(
        logicalConstraints: BoxConstraints.tight(logicalSize),
        physicalConstraints: BoxConstraints.tight(logicalSize * pixelRatio),
        devicePixelRatio: pixelRatio,
      ),
      child: RenderPositionedBox(child: boundary),
    );
    final pipelineOwner = PipelineOwner()..rootNode = renderView;
    final buildOwner = BuildOwner(focusManager: FocusManager());
    renderView.prepareInitialFrame();

    final root = RenderObjectToWidgetAdapter<RenderBox>(
      container: boundary,
      child: MediaQuery(
        data: MediaQueryData(
          size: logicalSize,
          devicePixelRatio: pixelRatio,
          textScaler: TextScaler.noScaling,
        ),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox.fromSize(size: logicalSize, child: widget),
        ),
      ),
    ).attachToRenderTree(buildOwner);

    try {
      buildOwner.buildScope(root);
      pipelineOwner
        ..flushLayout()
        ..flushCompositingBits()
        ..flushPaint();

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      try {
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null) {
          throw StateError('Image encoding returned no bytes');
        }
        return bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
      } finally {
        image.dispose();
      }
    } finally {
      // Unmount the widget subtree, then drop the render tree.
      RenderObjectToWidgetAdapter<RenderBox>(
        container: boundary,
      ).attachToRenderTree(buildOwner, root);
      buildOwner
        ..buildScope(root)
        ..finalizeTree();
      pipelineOwner.rootNode = null;
      renderView.dispose();
    }
  }
}
