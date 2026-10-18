import 'package:equatable/equatable.dart';

/// The caption that goes with a shared card (R7, D1).
///
/// [body] and [link] are kept apart so the X web intent can send them as
/// separate `text` and `url` parameters (R5).
class ShareCaption extends Equatable {
  const ShareCaption({required this.body, required this.link});

  /// The sentence, e.g. `My song "Blinding Lights" feels Charged 🎧 …`.
  final String body;

  /// `https://getmoodtune.com/?utm_source=<target>&utm_medium=share`.
  final Uri link;

  /// What most targets receive: the body followed by the link.
  String get full => '$body $link';

  @override
  List<Object?> get props => [body, link];
}
