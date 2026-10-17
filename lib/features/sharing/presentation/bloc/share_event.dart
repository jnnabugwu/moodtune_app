part of 'share_bloc.dart';

sealed class ShareEvent extends Equatable {
  const ShareEvent();

  @override
  List<Object?> get props => [];
}

/// The share sheet opened for [content]; find out which targets to list.
class ShareOpened extends ShareEvent {
  const ShareOpened(this.content);

  final ShareContent content;

  @override
  List<Object?> get props => [content];
}

/// The user picked [target]. [origin] is the tapped row's global rect, used
/// to anchor the iPad popover (R6).
class ShareTargetSelected extends ShareEvent {
  const ShareTargetSelected(this.target, {this.origin});

  final ShareTarget target;
  final Rect? origin;

  @override
  List<Object?> get props => [target, origin];
}
