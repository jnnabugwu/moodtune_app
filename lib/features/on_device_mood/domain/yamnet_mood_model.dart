import 'dart:math' as math;

import 'package:moodtune_app/features/on_device_mood/domain/on_device_mood.dart';

/// How to read YAMNet's 521 class scores as a mood and sound tags.
///
/// Loaded from `assets/models/yamnet_mood.json`, which
/// `spikes/clap/04_export_app_assets.py` exports. [interpret] mirrors that
/// script's `interpret`; `test/features/on_device_mood/fixtures/
/// yamnet_golden.json` checks the two agree.
class YamnetMoodModel {
  const YamnetMoodModel({
    required this.moodClasses,
    required this.logScoreMeans,
    required this.epsilon,
    required this.tagClasses,
    required this.tagThreshold,
    required this.maxTags,
  });

  factory YamnetMoodModel.fromJson(Map<String, Object?> json) {
    if (json case {
      'mood': {
        'classes': final List<Object?> moods,
        'logScoreMeans': final Map<String, Object?> means,
        'epsilon': final num epsilon,
      },
      'tags': {
        'classes': final List<Object?> tags,
        'threshold': final num? threshold,
        'max': final int maxTags,
      },
    }) {
      return YamnetMoodModel(
        moodClasses: [
          for (final c in moods)
            if (c case {'index': final int i, 'label': final String label})
              (index: i, label: label)
            else
              throw FormatException('Bad mood class: $c'),
        ],
        logScoreMeans: means.map(
          (label, value) => switch (value) {
            final num mean => MapEntry(label, mean.toDouble()),
            _ => throw FormatException('Bad log-score mean for $label: $value'),
          },
        ),
        epsilon: epsilon.toDouble(),
        tagClasses: [
          for (final c in tags)
            if (c case {'index': final int i, 'tag': final String tag})
              (index: i, tag: tag)
            else
              throw FormatException('Bad tag class: $c'),
        ],
        tagThreshold: threshold?.toDouble(),
        maxTags: maxTags,
      );
    }
    throw const FormatException('Unrecognised YAMNet mood config');
  }

  /// YAMNet's mood classes ("Happy music", ...) and the backend label each
  /// stands for.
  final List<({int index, String label})> moodClasses;

  /// Each label's mean log-score over the reference tracks. Subtracting it
  /// removes AudioSet's bias toward common classes such as "Happy music".
  final Map<String, double> logScoreMeans;

  /// Added before taking logs, so a zero score can't produce -infinity.
  final double epsilon;

  /// Allowed instrument, vocal and genre classes and their display tag.
  /// Several classes can share a tag (all vocal classes become "vocals").
  final List<({int index, String tag})> tagClasses;

  /// Minimum peak score for a tag. Null keeps the top [maxTags] regardless.
  final double? tagThreshold;
  final int maxTags;

  YamnetMoodModel withTagThreshold(double? threshold) => YamnetMoodModel(
    moodClasses: moodClasses,
    logScoreMeans: logScoreMeans,
    epsilon: epsilon,
    tagClasses: tagClasses,
    tagThreshold: threshold,
    maxTags: maxTags,
  );

  OnDeviceMood interpret(ClassScores scores) {
    final probabilities = _moodProbabilities(scores);
    var primary = moodClasses.first.label;
    for (final MapEntry(:key, :value) in probabilities.entries) {
      if (value > probabilities[primary]!) primary = key;
    }
    return OnDeviceMood(
      primaryMood: primary,
      probabilities: probabilities,
      tags: _tags(scores),
    );
  }

  /// Calibrated log-scores (each label's log mean-score minus its reference
  /// mean), then softmax.
  Map<String, double> _moodProbabilities(ClassScores scores) {
    final centred = {
      for (final c in moodClasses)
        c.label:
            math.log(scores.mean[c.index] + epsilon) - logScoreMeans[c.label]!,
    };
    final top = centred.values.reduce(math.max);
    final exps = {
      for (final MapEntry(:key, :value) in centred.entries)
        key: math.exp(value - top),
    };
    final total = exps.values.fold<double>(0, (sum, x) => sum + x);
    return {
      for (final MapEntry(:key, :value) in exps.entries) key: value / total,
    };
  }

  /// Each tag scores its strongest class's peak; the best [maxTags] that
  /// clear [tagThreshold] win. Ties keep allowlist order, as Python's stable
  /// sort does.
  List<String> _tags(ClassScores scores) {
    final best = <String, double>{};
    for (final c in tagClasses) {
      final score = scores.peak[c.index];
      if (score > (best[c.tag] ?? -1)) best[c.tag] = score;
    }
    final threshold = tagThreshold;
    final ranked =
        best.entries.indexed
            .where((e) => threshold == null || e.$2.value >= threshold)
            .toList()
          ..sort((a, b) {
            final byScore = b.$2.value.compareTo(a.$2.value);
            return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
          });
    return [for (final (_, entry) in ranked.take(maxTags)) entry.key];
  }
}
