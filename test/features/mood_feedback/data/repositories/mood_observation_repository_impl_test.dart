import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/app/theme/mood_theme.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/mood_feedback/data/datasources/mood_observation_remote_datasource.dart';
import 'package:moodtune_app/features/mood_feedback/data/device_context.dart';
import 'package:moodtune_app/features/mood_feedback/data/repositories/mood_observation_repository_impl.dart';

import '../../mood_feedback_fixtures.dart';

class _MockRemote extends Mock implements MoodObservationRemoteDataSource {}

class _MockDeviceContext extends Mock implements DeviceContext {}

DioException _dioError({
  DioExceptionType type = DioExceptionType.badResponse,
  Object? data,
  String? message,
  int statusCode = 500,
}) {
  final options = RequestOptions(path: '/mood-observations');
  return DioException(
    requestOptions: options,
    type: type,
    message: message,
    response: data == null
        ? null
        : Response<Object?>(
            requestOptions: options,
            statusCode: statusCode,
            data: data,
          ),
  );
}

void main() {
  late _MockRemote remote;
  late _MockDeviceContext deviceContext;
  late MoodObservationRepositoryImpl repository;

  setUp(() {
    remote = _MockRemote();
    deviceContext = _MockDeviceContext();
    repository = MoodObservationRepositoryImpl(
      remoteDataSource: remote,
      deviceContext: deviceContext,
    );
    when(() => deviceContext.load()).thenAnswer((_) async => sampleDevice);
    when(() => remote.recordObservation(any())).thenAnswer((_) async {});
    when(
      () => remote.sendFeedback(
        id: any(named: 'id'),
        agrees: any(named: 'agrees'),
        userMood: any(named: 'userMood'),
      ),
    ).thenAnswer((_) async {});
  });

  group('record', () {
    test('sends JSON with device context filled in', () async {
      final result = await repository.record(sampleObservation());

      expect(result, const Right<Failure, void>(null));
      final body =
          verify(() => remote.recordObservation(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(body['id'], observationId);
      expect(body['backend_mood'], 'happy');
      expect(body['displayed_source'], 'on_device');
      expect(body['platform'], 'ios');
      expect(body['os_version'], '18.1');
      expect(body['device_model'], 'iPhone15,2');
      expect(body['app_version'], '1.0.0+7');
    });

    test('keeps device fields the caller already set', () async {
      await repository.record(sampleObservation(appVersion: '2.0.0+1'));

      final body =
          verify(() => remote.recordObservation(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(body['app_version'], '2.0.0+1');
      expect(body['platform'], 'ios');
    });

    test('maps a backend error to ServerFailure with its detail', () async {
      when(
        () => remote.recordObservation(any()),
      ).thenThrow(_dioError(data: {'detail': 'boom'}));

      expect(
        await repository.record(sampleObservation()),
        const Left<Failure, void>(ServerFailure('boom')),
      );
    });

    test('maps connectivity errors to NetworkFailure', () async {
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.sendTimeout,
      ]) {
        when(
          () => remote.recordObservation(any()),
        ).thenThrow(_dioError(type: type, message: 'offline'));

        expect(
          await repository.record(sampleObservation()),
          const Left<Failure, void>(NetworkFailure('offline')),
        );
      }
    });

    test('falls back to generic messages', () async {
      when(
        () => remote.recordObservation(any()),
      ).thenThrow(_dioError(type: DioExceptionType.connectionError));
      expect(
        await repository.record(sampleObservation()),
        const Left<Failure, void>(NetworkFailure('Network error')),
      );

      when(() => remote.recordObservation(any())).thenThrow(_dioError());
      expect(
        await repository.record(sampleObservation()),
        const Left<Failure, void>(ServerFailure('Server error')),
      );
    });

    test('maps other exceptions to ServerFailure', () async {
      when(
        () => remote.recordObservation(any()),
      ).thenThrow(const ServerException('nope'));

      expect(
        await repository.record(sampleObservation()),
        const Left<Failure, void>(ServerFailure('ServerException: nope')),
      );
    });
  });

  group('sendFeedback', () {
    test('agree sends a null user mood', () async {
      final result = await repository.sendFeedback(
        id: observationId,
        agrees: true,
      );

      expect(result, const Right<Failure, void>(null));
      verify(
        () => remote.sendFeedback(
          id: observationId,
          agrees: true,
          userMood: null,
        ),
      ).called(1);
    });

    test('disagree sends the bucket name', () async {
      await repository.sendFeedback(
        id: observationId,
        agrees: false,
        userMood: MoodIdentity.serene,
      );

      verify(
        () => remote.sendFeedback(
          id: observationId,
          agrees: false,
          userMood: 'serene',
        ),
      ).called(1);
    });

    test('maps a 404 to ServerFailure', () async {
      when(
        () => remote.sendFeedback(
          id: any(named: 'id'),
          agrees: any(named: 'agrees'),
          userMood: any(named: 'userMood'),
        ),
      ).thenThrow(
        _dioError(
          statusCode: 404,
          data: {'detail': 'Mood observation not found'},
        ),
      );

      expect(
        await repository.sendFeedback(id: observationId, agrees: true),
        const Left<Failure, void>(ServerFailure('Mood observation not found')),
      );
    });

    test('maps other exceptions to ServerFailure', () async {
      when(
        () => remote.sendFeedback(
          id: any(named: 'id'),
          agrees: any(named: 'agrees'),
          userMood: any(named: 'userMood'),
        ),
      ).thenThrow(Exception('x'));

      expect(
        await repository.sendFeedback(id: observationId, agrees: true),
        const Left<Failure, void>(ServerFailure('Exception: x')),
      );
    });
  });
}
