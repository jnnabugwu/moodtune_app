/// Where a result can be shared to (R1).
enum ShareTarget {
  /// Instagram's Story composer, with the card as a sticker (D3).
  instagramStory,

  /// X, with the card and caption attached (R5).
  x,

  /// The platform share sheet: "More…" (R6). Always available.
  system;

  /// `utm_source` value for the link in the caption (D1).
  String get utmSource => switch (this) {
    ShareTarget.instagramStory => 'instagram_story',
    ShareTarget.x => 'x',
    ShareTarget.system => 'share_sheet',
  };
}
