import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';
import 'package:moodtune_app/features/narration/domain/narration.dart';

const templateReasoning =
    'Derived from tempo, brightness, and energy patterns.';

class FakeNarrationEngine implements NarrationEngine {
  FakeNarrationEngine({
    this.available = true,
    this.output = '',
    this.error,
    this.delay,
    this.availabilityDelay,
  });

  final bool available;
  final String output;
  final Exception? error;
  final Duration? delay;
  final Duration? availabilityDelay;
  int narrateCalls = 0;
  Duration? lastTimeout;

  @override
  Future<bool> isAvailable() async {
    if (availabilityDelay != null) {
      await Future<void>.delayed(availabilityDelay!);
    }
    return available;
  }

  @override
  Future<String> narrate(
    NarrationInput input, {
    required Duration timeout,
  }) async {
    narrateCalls++;
    lastTimeout = timeout;
    if (delay != null) await Future<void>.delayed(delay!);
    if (error != null) throw error!;
    return output;
  }
}

AudioUploadAnalysis buildAnalysis({
  String id = 'a1',
  String primaryMood = 'energetic',
  String reasoning = templateReasoning,
  double tempo = 128,
  List<String> descriptors = const ['upbeat', 'danceable'],
}) => AudioUploadAnalysis(
  id: id,
  filename: 'song.mp3',
  fileSizeBytes: 1,
  durationSeconds: 30,
  mood: UploadMoodResult(
    primaryMood: primaryMood,
    moodScores: const {'energetic': 0.8},
    confidence: 0.72,
    reasoning: reasoning,
    audioFeatures: UploadAudioFeatures(
      tempo: tempo,
      beatStrength: 0.7,
      spectralCentroid: 2500,
      spectralRolloff: 4000,
      spectralBandwidth: 1800,
      harmonicRatio: 0.5,
      zeroCrossingRate: 0.1,
      rmsEnergy: 0.3,
      dynamicRange: 0.4,
      mfccMean: const [],
      durationSeconds: 30,
      energyLabel: 'High (0.84)',
      brightnessLabel: 'Bright',
      textureLabel: 'Dense',
    ),
    descriptors: descriptors,
  ),
  analysisMethod: 'librosa',
  processedAt: DateTime(2026, 10, 12),
  processingTimeSeconds: 1.2,
);
