/// How a share call ended. Cancelling is an outcome, not a failure (R10).
enum ShareOutcome {
  /// The target app took the content. On Android and macOS this only means
  /// the user picked an action, not that it was posted.
  completed,

  /// The user closed the share UI without picking anything.
  dismissed,
}
