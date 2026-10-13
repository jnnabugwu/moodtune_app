import 'dart:async';

import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/narration/domain/narration.dart';

export 'package:moodtune_app/features/narration/domain/narration.dart';

/// Builds the model's facts from a result. Uses the same mood mapping as the
/// hero card, so the narration names the mood on screen ("serene") rather
/// than the backend's ("calm").
NarrationInput narrationInputFor(UploadMoodResult mood) {
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

String _tempoFeel(double bpm) {
  if (bpm < 90) return 'slow';
  if (bpm <= 120) return 'mid-tempo';
  return 'fast';
}

/// "High (0.84)" → "high energy".
String _energyPhrase(String label) {
  final level = label.split('(').first.trim().toLowerCase();
  return '$level energy';
}

String _tonePhrase(String label) => 'a ${label.toLowerCase()} tone';

String _texturePhrase(String label) => switch (label.toLowerCase()) {
  'smooth' => 'a smooth, flowing sound',
  'textured' => 'a layered, textured sound',
  'rough' => 'a rough, gritty sound',
  final other => 'a $other sound',
};

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

  /// The prompt asks for under 50 words (60 for the minimal instructions).
  static const _maxWords = 60;

  static final _links = RegExp(r'https?://|www\.', caseSensitive: false);

  /// Things the prompt carries no facts about, so any mention is invented:
  /// song metadata, instruments, recording and structure, and the app's own
  /// analysis, which the instructions forbid mentioning.
  static final _ungroundedTopics = RegExp(
    r'\b('
    'lyrics?|genres?|artists?|singers?|vocals?|vocalists?|'
    'drums?|drummers?|guitars?|piano|keys|synths?|synthesizers?|bass|'
    'strings|violins?|cellos?|horns?|brass|saxophones?|trumpets?|choirs?|'
    'live|recordings?|recorded|studio|albums?|chorus|verses?|bridge|'
    r'confidence|scores?|classif\w*|analy[sz]\w*|apps?|algorithms?'
    r')\b',
    caseSensitive: false,
  );

  static final _whitespace = RegExp(r'\s+');

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
      // Results parsed without an id share '', so caching them would hand
      // one song's narration to another.
      if (analysis.id.isNotEmpty) _cache[analysis.id] = narration;
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
    // The parser defaults a missing tempo to 0, which would reach the model
    // as a fact ("slow, at 0 BPM").
    if (analysis.mood.audioFeatures.tempo <= 0) {
      talker.info('Narration: no tempo in result; using template');
      return null;
    }

    final budget = Stopwatch()..start();
    if (!await _engine.isAvailable()) {
      talker.info('Narration: on-device model unavailable; using template');
      return null;
    }

    // Hand the engine whatever is left of [timeout] so it can cancel the
    // model itself; the `.timeout` in [narrate] only stops Dart waiting.
    final remaining = timeout - budget.elapsed;
    if (remaining <= Duration.zero) return null;

    final input = narrationInputFor(analysis.mood);
    final stopwatch = Stopwatch()..start();
    final text = (await _engine.narrate(input, timeout: remaining)).trim();
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
  ///
  /// This cannot prove every claim comes from the facts; it blocks the
  /// categories of invention the model has been seen to produce.
  static bool isGrounded(String text, NarrationInput input) {
    if (text.length < _minLength || text.length > _maxLength) return false;
    if (text.split(_whitespace).length > _maxWords) return false;
    if (_links.hasMatch(text)) return false;
    if (_ungroundedTopics.hasMatch(text)) return false;

    final lower = text.toLowerCase();
    return [input.mood, ...input.descriptors]
        .map((word) => word.trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .any(lower.contains);
  }
}
