import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';

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
/// on-device model echoes raw labels verbatim ("bright brightness").
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

  /// Uses the same mood mapping as the hero card, so the narration names
  /// the mood on screen ("serene") rather than the backend's ("calm").
  factory NarrationInput.fromMood(UploadMoodResult mood) {
    final identity = MoodTheme.fromString(mood.primaryMood);
    final features = mood.audioFeatures;
    return NarrationInput(
      mood: MoodTheme.shortLabel(identity).toLowerCase(),
      moodSummary: MoodTheme.quadrantLabel(
        identity,
      ).replaceAll('&', 'and').toLowerCase(),
      tempo: features.tempo.round(),
      tempoFeel: _tempoFeel(features.tempo),
      energy: _energyPhrase(features.energyLabel),
      tone: _tonePhrase(features.brightnessLabel),
      texture: _texturePhrase(features.textureLabel),
      descriptors: mood.descriptors,
    );
  }

  final String mood;
  final String moodSummary;
  final int tempo;
  final String tempoFeel;
  final String energy;
  final String tone;
  final String texture;
  final List<String> descriptors;

  static String _tempoFeel(double bpm) {
    if (bpm < 90) return 'slow';
    if (bpm <= 120) return 'mid-tempo';
    return 'fast';
  }

  /// "High (0.84)" → "high energy".
  static String _energyPhrase(String label) {
    final level = label.split('(').first.trim().toLowerCase();
    return '$level energy';
  }

  static String _tonePhrase(String label) => 'a ${label.toLowerCase()} tone';

  static String _texturePhrase(String label) => switch (label.toLowerCase()) {
    'smooth' => 'a smooth, flowing sound',
    'textured' => 'a layered, textured sound',
    'rough' => 'a rough, gritty sound',
    final other => 'a $other sound',
  };

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

  Future<String> narrate(NarrationInput input);
}

/// Produces the "why this mood" copy for a result.
///
/// The classifier owns the mood label; the model only narrates it. Any
/// failure (unsupported device, timeout, error, or output that fails
/// validation) falls back to the backend's template reasoning, so the
/// results screen never depends on the model.
class MoodNarrator {
  MoodNarrator({
    required NarrationEngine engine,
    this.timeout = const Duration(seconds: 5),
  }) : _engine = engine;

  final NarrationEngine _engine;

  /// Deadline for the whole attempt (availability check plus generation),
  /// so on-device text never replaces the template long after it was read.
  final Duration timeout;
  final Map<String, MoodNarration> _cache = {};

  static const _minLength = 20;
  static const _maxLength = 400;

  /// Topics the prompt carries no facts about, so any mention is invented.
  static final _ungroundedTopics = RegExp(
    r'\b(lyrics?|genres?|artists?|singers?|vocals?)\b',
    caseSensitive: false,
  );

  Future<MoodNarration> narrate(AudioUploadAnalysis analysis) async {
    final cached = _cache[analysis.id];
    if (cached != null) return cached;

    final template = MoodNarration(
      text: analysis.mood.reasoning,
      source: NarrationSource.template,
    );

    try {
      final narration = await _narrateOnDevice(analysis).timeout(timeout);
      if (narration == null) return template;
      _cache[analysis.id] = narration;
      return narration;
    } on TimeoutException {
      talker.warning(
        'Narration timed out after ${timeout.inMilliseconds}ms; '
        'using template',
      );
      return template;
    } on Object catch (error) {
      talker.warning('Narration failed ($error); using template');
      return template;
    }
  }

  /// Returns null when the model is unavailable or its output is rejected.
  Future<MoodNarration?> _narrateOnDevice(AudioUploadAnalysis analysis) async {
    if (!await _engine.isAvailable()) {
      talker.info('Narration: on-device model unavailable; using template');
      return null;
    }

    final input = NarrationInput.fromMood(analysis.mood);
    final stopwatch = Stopwatch()..start();
    final text = (await _engine.narrate(input)).trim();
    final elapsed = stopwatch.elapsedMilliseconds;

    if (!isGrounded(text, input)) {
      talker.warning('Narration rejected after ${elapsed}ms: "$text"');
      return null;
    }
    talker.info('Narration generated in ${elapsed}ms');
    return MoodNarration(text: text, source: NarrationSource.onDevice);
  }

  /// Rejects output that is empty, too long, carries links, mentions topics
  /// the model has no facts about, or never names the classified mood or
  /// any of its descriptors.
  static bool isGrounded(String text, NarrationInput input) {
    if (text.length < _minLength || text.length > _maxLength) return false;
    if (text.contains('http://') || text.contains('https://')) return false;
    if (_ungroundedTopics.hasMatch(text)) return false;

    final lower = text.toLowerCase();
    final anchors = [input.mood, ...input.descriptors];
    return anchors.any((word) => lower.contains(word.toLowerCase()));
  }
}
