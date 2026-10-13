import 'package:flutter_test/flutter_test.dart';
import 'package:moodtune_app/features/analysis/data/models/audio_upload_analysis_model.dart';
import 'package:moodtune_app/features/analysis/domain/entities/audio_upload_analysis.dart';

import '../analysis_data_fixtures.dart';

void main() {
  group('UploadAudioFeaturesModel', () {
    test('fromJson parses every field and coerces numbers', () {
      final model = UploadAudioFeaturesModel.fromJson(uploadFeaturesJson());

      expect(model.tempo, 128.0);
      expect(model.beatStrength, 0.9);
      expect(model.spectralCentroid, 2500.5);
      expect(model.spectralRolloff, 4000.0);
      expect(model.spectralBandwidth, 1800.25);
      expect(model.harmonicRatio, 0.6);
      expect(model.zeroCrossingRate, 0.08);
      expect(model.rmsEnergy, 0.3);
      expect(model.dynamicRange, 12.0);
      expect(model.mfccMean, [1.0, 2.5, -3.0]);
      expect(model.mfccMean, everyElement(isA<double>()));
      expect(model.durationSeconds, 210.5);
      expect(model.energyLabel, 'High (0.84)');
      expect(model.brightnessLabel, 'Bright');
      expect(model.textureLabel, 'Smooth');
    });

    test('fromJson defaults missing fields', () {
      final model = UploadAudioFeaturesModel.fromJson(<String, dynamic>{});

      expect(model.tempo, 0);
      expect(model.beatStrength, 0);
      expect(model.spectralCentroid, 0);
      expect(model.spectralRolloff, 0);
      expect(model.spectralBandwidth, 0);
      expect(model.harmonicRatio, 0);
      expect(model.zeroCrossingRate, 0);
      expect(model.rmsEnergy, 0);
      expect(model.dynamicRange, 0);
      expect(model.mfccMean, isEmpty);
      expect(model.durationSeconds, 0);
      expect(model.energyLabel, '');
      expect(model.brightnessLabel, '');
      expect(model.textureLabel, '');
    });

    test('toDomain maps every field', () {
      expect(
        UploadAudioFeaturesModel.fromJson(uploadFeaturesJson()).toDomain(),
        const UploadAudioFeatures(
          tempo: 128,
          beatStrength: 0.9,
          spectralCentroid: 2500.5,
          spectralRolloff: 4000,
          spectralBandwidth: 1800.25,
          harmonicRatio: 0.6,
          zeroCrossingRate: 0.08,
          rmsEnergy: 0.3,
          dynamicRange: 12,
          mfccMean: [1, 2.5, -3],
          durationSeconds: 210.5,
          energyLabel: 'High (0.84)',
          brightnessLabel: 'Bright',
          textureLabel: 'Smooth',
        ),
      );
    });
  });

  group('UploadMoodResultModel', () {
    test('fromJson parses scores, descriptors and nested features', () {
      final json = audioUploadJson()['mood'] as Map<String, dynamic>;
      final model = UploadMoodResultModel.fromJson(json);

      expect(model.primaryMood, 'Energetic');
      expect(model.moodScores, {'energetic': 0.8, 'happy': 1.0});
      expect(model.moodScores.values, everyElement(isA<double>()));
      expect(model.confidence, 0.75);
      expect(model.reasoning, 'Fast tempo');
      expect(model.descriptors, ['upbeat', 'danceable']);
      expect(model.audioFeatures.tempo, 128);
    });

    test('fromJson tolerates an empty payload', () {
      final model = UploadMoodResultModel.fromJson(<String, dynamic>{});

      expect(model.primaryMood, '');
      expect(model.moodScores, isEmpty);
      expect(model.confidence, 0);
      expect(model.reasoning, '');
      expect(model.descriptors, isEmpty);
      expect(model.audioFeatures.mfccMean, isEmpty);
    });

    test('fromJson throws on a non-numeric mood score', () {
      expect(
        () => UploadMoodResultModel.fromJson(<String, dynamic>{
          'mood_scores': <String, dynamic>{'happy': 'high'},
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('toDomain maps every field and nested features', () {
      final json = audioUploadJson()['mood'] as Map<String, dynamic>;
      final entity = UploadMoodResultModel.fromJson(json).toDomain();

      expect(entity.primaryMood, 'Energetic');
      expect(entity.moodScores, {'energetic': 0.8, 'happy': 1.0});
      expect(entity.confidence, 0.75);
      expect(entity.reasoning, 'Fast tempo');
      expect(entity.descriptors, ['upbeat', 'danceable']);
      expect(
        entity.audioFeatures,
        UploadAudioFeaturesModel.fromJson(uploadFeaturesJson()).toDomain(),
      );
    });
  });

  group('AudioUploadAnalysisModel', () {
    test('fromJson parses every field', () {
      final model = AudioUploadAnalysisModel.fromJson(audioUploadJson());

      expect(model.id, 'up-1');
      expect(model.filename, 'song.mp3');
      expect(model.fileSizeBytes, 123456);
      expect(model.durationSeconds, 210.5);
      expect(model.title, 'Title');
      expect(model.artist, 'Artist');
      expect(model.album, 'Album');
      expect(model.mood.primaryMood, 'Energetic');
      expect(model.analysisMethod, 'catalog');
      expect(model.processedAt, DateTime.utc(2025, 5, 6, 7, 8, 9));
      expect(model.processingTimeSeconds, 4.2);
      expect(model.jamendoTrackUrl, 'https://jamendo.com/track/1');
    });

    test('fromJson truncates a fractional file_size_bytes to int', () {
      final model = AudioUploadAnalysisModel.fromJson(
        audioUploadJson()..['file_size_bytes'] = 99.9,
      );

      expect(model.fileSizeBytes, 99);
    });

    test('fromJson applies defaults for an empty payload', () {
      final model = AudioUploadAnalysisModel.fromJson(<String, dynamic>{});

      expect(model.id, '');
      expect(model.filename, '');
      expect(model.fileSizeBytes, 0);
      expect(model.durationSeconds, 0);
      expect(model.title, isNull);
      expect(model.artist, isNull);
      expect(model.album, isNull);
      expect(model.jamendoTrackUrl, isNull);
      expect(model.mood.primaryMood, '');
      expect(model.analysisMethod, 'direct_audio');
      expect(model.processedAt, DateTime.fromMillisecondsSinceEpoch(0));
      expect(model.processingTimeSeconds, 0);
    });

    test('fromJson falls back to epoch for an unparseable processed_at', () {
      final model = AudioUploadAnalysisModel.fromJson(
        audioUploadJson()..['processed_at'] = 'yesterday',
      );

      expect(model.processedAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('toDomain maps every field', () {
      final entity = AudioUploadAnalysisModel.fromJson(
        audioUploadJson(),
      ).toDomain();

      expect(entity.id, 'up-1');
      expect(entity.filename, 'song.mp3');
      expect(entity.fileSizeBytes, 123456);
      expect(entity.durationSeconds, 210.5);
      expect(entity.title, 'Title');
      expect(entity.artist, 'Artist');
      expect(entity.album, 'Album');
      expect(entity.analysisMethod, 'catalog');
      expect(entity.processedAt, DateTime.utc(2025, 5, 6, 7, 8, 9));
      expect(entity.processingTimeSeconds, 4.2);
      expect(entity.jamendoTrackUrl, 'https://jamendo.com/track/1');
      expect(entity.mood.descriptors, ['upbeat', 'danceable']);
      expect(entity.mood.audioFeatures.energyLabel, 'High (0.84)');
    });
  });
}
