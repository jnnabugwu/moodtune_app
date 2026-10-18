part of 'share_bloc.dart';

enum ShareStatus {
  initial,

  /// Checking which target apps are installed.
  loadingTargets,

  /// Targets listed; waiting for a tap.
  ready,

  /// Rendering the card and handing it to [ShareState.activeTarget].
  sharing,

  /// The share call returned; see [ShareState.outcome]. The sheet closes.
  done,

  /// Rendering failed or the target rejected the share. The sheet stays
  /// open with an inline message and the targets stay tappable (R10).
  failure,
}

class ShareState extends Equatable {
  const ShareState({
    this.status = ShareStatus.initial,
    this.content,
    this.targets = const [],
    this.activeTarget,
    this.outcome,
    this.failure,
  });

  final ShareStatus status;
  final ShareContent? content;

  /// Targets to list, in display order. "More…" is always last (R1).
  final List<ShareTarget> targets;

  /// The target being shared to, or the one that just finished.
  final ShareTarget? activeTarget;

  /// Set when [status] is [ShareStatus.done].
  final ShareOutcome? outcome;

  /// Set when [status] is [ShareStatus.failure].
  final Failure? failure;

  bool get isSharing => status == ShareStatus.sharing;

  ShareState copyWith({
    ShareStatus? status,
    ShareContent? content,
    List<ShareTarget>? targets,
    ShareTarget? activeTarget,
    ShareOutcome? outcome,
    Failure? failure,
  }) => ShareState(
    status: status ?? this.status,
    content: content ?? this.content,
    targets: targets ?? this.targets,
    activeTarget: activeTarget ?? this.activeTarget,
    // Outcome and failure describe one share call, so they never carry
    // over to the next state unless re-passed.
    outcome: outcome,
    failure: failure,
  );

  @override
  List<Object?> get props => [
    status,
    content,
    targets,
    activeTarget,
    outcome,
    failure,
  ];
}
