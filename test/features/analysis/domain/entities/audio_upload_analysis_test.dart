import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';

UploadAudioFeatures _features({
  double tempo = 120,
  double beatStrength = 0.5,
  double spectralCentroid = 2000,
  double spectralRolloff = 4000,
  double spectralBandwidth = 1500,
  double harmonicRatio = 0.6,
  double zeroCrossingRate = 0.1,
  double rmsEnergy = 0.3,
  double dynamicRange = 10,
  List<double> mfccMean = const [1, 2],
  double durationSeconds = 200,
  String energyLabel = 'High',
  String brightnessLabel = 'Bright',
  String textureLabel = 'Smooth',
}) => UploadAudioFeatures(
  tempo: tempo,
  beatStrength: beatStrength,
  spectralCentroid: spectralCentroid,
  spectralRolloff: spectralRolloff,
  spectralBandwidth: spectralBandwidth,
  harmonicRatio: harmonicRatio,
  zeroCrossingRate: zeroCrossingRate,
  rmsEnergy: rmsEnergy,
  dynamicRange: dynamicRange,
  mfccMean: mfccMean,
  durationSeconds: durationSeconds,
  energyLabel: energyLabel,
  brightnessLabel: brightnessLabel,
  textureLabel: textureLabel,
);

UploadMoodResult _mood({
  String primaryMood = 'Happy',
  Map<String, double> moodScores = const {'happy': 0.9},
  double confidence = 0.8,
  String reasoning = 'because',
  UploadAudioFeatures? audioFeatures,
  List<String> descriptors = const ['upbeat'],
}) => UploadMoodResult(
  primaryMood: primaryMood,
  moodScores: moodScores,
  confidence: confidence,
  reasoning: reasoning,
  audioFeatures: audioFeatures ?? _features(),
  descriptors: descriptors,
);

final _processedAt = DateTime.utc(2025, 1, 1);

AudioUploadAnalysis _analysis({
  String id = 'id',
  String filename = 'f.mp3',
  int fileSizeBytes = 100,
  double durationSeconds = 200,
  String? title = 'T',
  String? artist = 'A',
  String? album = 'Al',
  UploadMoodResult? mood,
  String analysisMethod = 'direct_audio',
  DateTime? processedAt,
  double processingTimeSeconds = 3,
  String? jamendoTrackUrl = 'https://j',
}) => AudioUploadAnalysis(
  id: id,
  filename: filename,
  fileSizeBytes: fileSizeBytes,
  durationSeconds: durationSeconds,
  title: title,
  artist: artist,
  album: album,
  mood: mood ?? _mood(),
  analysisMethod: analysisMethod,
  processedAt: processedAt ?? _processedAt,
  processingTimeSeconds: processingTimeSeconds,
  jamendoTrackUrl: jamendoTrackUrl,
);

void main() {
  group('UploadAudioFeatures', () {
    test('equality, props order and per-field sensitivity', () {
      expect(_features(), _features());
      expect(_features().props, [
        120.0,
        0.5,
        2000.0,
        4000.0,
        1500.0,
        0.6,
        0.1,
        0.3,
        10.0,
        [1.0, 2.0],
        200.0,
        'High',
        'Bright',
        'Smooth',
      ]);
      for (final v in [
        _features(tempo: 0),
        _features(beatStrength: 0),
        _features(spectralCentroid: 0),
        _features(spectralRolloff: 0),
        _features(spectralBandwidth: 0),
        _features(harmonicRatio: 0),
        _features(zeroCrossingRate: 0),
        _features(rmsEnergy: 0),
        _features(dynamicRange: 0),
        _features(mfccMean: [3]),
        _features(durationSeconds: 0),
        _features(energyLabel: 'x'),
        _features(brightnessLabel: 'x'),
        _features(textureLabel: 'x'),
      ]) {
        expect(v, isNot(_features()));
      }
    });
  });

  group('UploadMoodResult', () {
    test('equality, props order and per-field sensitivity', () {
      expect(_mood(), _mood());
      expect(_mood().props, [
        'Happy',
        {'happy': 0.9},
        0.8,
        'because',
        _features(),
        ['upbeat'],
      ]);
      for (final v in [
        _mood(primaryMood: 'x'),
        _mood(moodScores: {'sad': 0.1}),
        _mood(confidence: 0),
        _mood(reasoning: 'x'),
        _mood(audioFeatures: _features(tempo: 1)),
        _mood(descriptors: ['x']),
      ]) {
        expect(v, isNot(_mood()));
      }
    });
  });

  group('AudioUploadAnalysis', () {
    test('optional fields default to null', () {
      final analysis = AudioUploadAnalysis(
        id: 'id',
        filename: 'f',
        fileSizeBytes: 1,
        durationSeconds: 1,
        mood: _mood(),
        analysisMethod: 'direct_audio',
        processedAt: _processedAt,
        processingTimeSeconds: 1,
      );

      expect(analysis.title, isNull);
      expect(analysis.artist, isNull);
      expect(analysis.album, isNull);
      expect(analysis.jamendoTrackUrl, isNull);
    });

    test('equality and props order', () {
      expect(_analysis(), _analysis());
      expect(_analysis().hashCode, _analysis().hashCode);
      expect(_analysis().props, [
        'id',
        'f.mp3',
        100,
        200.0,
        'T',
        'A',
        'Al',
        _mood(),
        'direct_audio',
        _processedAt,
        3.0,
        'https://j',
      ]);
    });

    test('every field participates in equality', () {
      for (final v in [
        _analysis(id: 'x'),
        _analysis(filename: 'x'),
        _analysis(fileSizeBytes: 0),
        _analysis(durationSeconds: 0),
        _analysis(title: null),
        _analysis(artist: null),
        _analysis(album: null),
        _analysis(mood: _mood(primaryMood: 'Sad')),
        _analysis(analysisMethod: 'catalog'),
        _analysis(processedAt: DateTime.utc(2000)),
        _analysis(processingTimeSeconds: 0),
        _analysis(jamendoTrackUrl: null),
      ]) {
        expect(v, isNot(_analysis()));
      }
    });
  });
}
