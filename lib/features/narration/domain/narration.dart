import 'package:equatable/equatable.dart';

/// Where a [MoodNarration] came from.
enum NarrationSource { onDevice, template }

class MoodNarration extends Equatable {
  const MoodNarration({required this.text, required this.source});

  final String text;
  final NarrationSource source;

  @override
  List<Object?> get props => [text, source];
}

/// Structured facts the model is allowed to narrate. Deliberately excludes
/// track title, artist and filename so the model can't invent facts about
/// them; it only explains a result the classifier already produced.
///
/// Facts are pre-phrased ("a warm tone", not "Brightness: Warm") because the
/// on-device model echoes raw labels verbatim ("bright brightness"). See
/// `narrationInputFor` for how they are built from a result.
class NarrationInput extends Equatable {
  const NarrationInput({
    required this.mood,
    required this.moodSummary,
    required this.tempo,
    required this.tempoFeel,
    required this.energy,
    required this.tone,
    required this.texture,
    required this.descriptors,
  });

  final String mood;
  final String moodSummary;
  final int tempo;
  final String tempoFeel;
  final String energy;
  final String tone;
  final String texture;
  final List<String> descriptors;

  Map<String, Object> toMap() => {
    'mood': mood,
    'moodSummary': moodSummary,
    'tempo': tempo,
    'tempoFeel': tempoFeel,
    'energy': energy,
    'tone': tone,
    'texture': texture,
    'descriptors': descriptors,
  };

  @override
  List<Object?> get props => [
    mood,
    moodSummary,
    tempo,
    tempoFeel,
    energy,
    tone,
    texture,
    descriptors,
  ];
}

/// A local language model that can turn a [NarrationInput] into prose.
abstract interface class NarrationEngine {
  Future<bool> isAvailable();

  /// Engines must abandon generation once [timeout] elapses: by then the
  /// caller has already returned template copy, so further work only burns
  /// battery on output nobody will read.
  Future<String> narrate(NarrationInput input, {required Duration timeout});
}
