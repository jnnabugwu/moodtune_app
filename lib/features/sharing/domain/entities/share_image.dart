import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A rendered share card as PNG bytes plus its pixel size (R3).
class ShareImage extends Equatable {
  const ShareImage({
    required this.pngBytes,
    required this.width,
    required this.height,
  });

  final Uint8List pngBytes;

  /// Width in pixels (1080 for the 4:5 card).
  final int width;

  /// Height in pixels (1350 for the 4:5 card).
  final int height;

  @override
  List<Object?> get props => [pngBytes, width, height];
}
