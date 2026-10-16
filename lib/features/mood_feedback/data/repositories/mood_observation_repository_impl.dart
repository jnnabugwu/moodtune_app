import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/mood_feedback/data/datasources/mood_observation_remote_datasource.dart';
import 'package:moodtune_app/features/mood_feedback/data/device_context.dart';
import 'package:moodtune_app/features/mood_feedback/data/models/mood_observation_model.dart';
import 'package:moodtune_app/features/mood_feedback/data/repositories/dio_failure.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/mood_observation.dart';
import 'package:moodtune_app/features/mood_feedback/domain/repositories/mood_observation_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

class MoodObservationRepositoryImpl implements MoodObservationRepository {
  MoodObservationRepositoryImpl({
    MoodObservationRemoteDataSource? remoteDataSource,
    DeviceContext? deviceContext,
  }) : _remote = remoteDataSource ?? MoodObservationRemoteDataSource(),
       _deviceContext = deviceContext ?? DeviceContext();

  final MoodObservationRemoteDataSource _remote;
  final DeviceContext _deviceContext;

  /// Fills platform/OS/model/app version from [DeviceContext] for any of
  /// those fields the caller left null, then upserts.
  @override
  ResultFuture<void> record(MoodObservation observation) async {
    try {
      final details = await _deviceContext.load();
      await _remote.recordObservation(
        observation.withDeviceDetails(details).toJson(),
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> sendFeedback({
    required String id,
    required bool agrees,
    MoodIdentity? userMood,
  }) async {
    try {
      await _remote.sendFeedback(
        id: id,
        agrees: agrees,
        userMood: userMood?.name,
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapDioFailure(e));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
