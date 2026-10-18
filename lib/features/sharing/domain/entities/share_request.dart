import 'dart:ui' show Rect;

import 'package:equatable/equatable.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_caption.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_image.dart';
import 'package:moodtune_app/features/sharing/domain/entities/share_target.dart';

/// Everything `ShareRepository.share` needs for one target.
class ShareRequest extends Equatable {
  const ShareRequest({
    required this.target,
    required this.image,
    required this.caption,
    required this.backgroundTopColor,
    required this.backgroundBottomColor,
    this.sharePositionOrigin,
  });

  final ShareTarget target;

  /// The 4:5 card. For Instagram it becomes the Story sticker (D3).
  final ShareImage image;

  final ShareCaption caption;

  /// ARGB colours behind the sticker on Instagram: the displayed mood's
  /// gradient start and end (D3).
  final int backgroundTopColor;
  final int backgroundBottomColor;

  /// Global rect of the button that opened the share, so the iPad popover
  /// anchors to it (R6).
  final Rect? sharePositionOrigin;

  @override
  List<Object?> get props => [
    target,
    image,
    caption,
    backgroundTopColor,
    backgroundBottomColor,
    sharePositionOrigin,
  ];
}
