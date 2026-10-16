import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/mood_feedback/data/datasources/app_config_remote_datasource.dart';
import 'package:moodtune_app/features/mood_feedback/data/repositories/app_config_repository_impl.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/app_config.dart';

class _MockRemote extends Mock implements AppConfigRemoteDataSource {}

void main() {
  late _MockRemote remote;
  late DateTime now;
  late AppConfigRepositoryImpl repository;

  setUpAll(talker.disable);
  tearDownAll(talker.enable);

  DioException offline() => DioException(
    requestOptions: RequestOptions(path: '/config'),
    type: DioExceptionType.connectionError,
  );

  setUp(() {
    remote = _MockRemote();
    now = DateTime(2026, 10, 16, 12);
    repository = AppConfigRepositoryImpl(
      remoteDataSource: remote,
      clock: () => now,
    );
  });

  test('defaultCacheTtl is 10 minutes', () {
    expect(
      AppConfigRepositoryImpl.defaultCacheTtl,
      const Duration(minutes: 10),
    );
  });

  test('returns the fetched config', () async {
    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {'on_device_mood': false});

    expect(await repository.load(), const AppConfig(onDeviceMood: false));
  });

  test('serves the cached config for 10 minutes, then refetches', () async {
    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {'on_device_mood': false});

    await repository.load();
    now = now.add(const Duration(minutes: 9, seconds: 59));
    expect(await repository.load(), const AppConfig(onDeviceMood: false));
    verify(() => remote.fetchConfig()).called(1);

    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {'on_device_mood': true});
    now = now.add(const Duration(seconds: 1));
    expect(await repository.load(), AppConfig.fallback);
    verify(() => remote.fetchConfig()).called(1);
  });

  test('refetches when the clock moved back', () async {
    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {'on_device_mood': false});

    await repository.load();
    now = now.subtract(const Duration(hours: 1));
    await repository.load();

    verify(() => remote.fetchConfig()).called(2);
  });

  test('falls back to on-device enabled when the fetch fails', () async {
    when(() => remote.fetchConfig()).thenThrow(offline());

    expect(await repository.load(), AppConfig.fallback);
  });

  test('falls back on malformed JSON', () async {
    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {'on_device_mood': 'nope'});

    expect(await repository.load(), AppConfig.fallback);
  });

  test('falls back even when the datasource throws an Error', () async {
    when(() => remote.fetchConfig()).thenThrow(StateError('bad'));

    expect(await repository.load(), AppConfig.fallback);
  });

  test('does not cache failures', () async {
    when(() => remote.fetchConfig()).thenThrow(offline());
    await repository.load();

    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {'on_device_mood': false});
    expect(await repository.load(), const AppConfig(onDeviceMood: false));
  });

  test('keeps the last known config when a refresh fails', () async {
    when(
      () => remote.fetchConfig(),
    ).thenAnswer((_) async => {'on_device_mood': false});
    await repository.load();

    now = now.add(const Duration(minutes: 11));
    when(() => remote.fetchConfig()).thenThrow(offline());

    expect(await repository.load(), const AppConfig(onDeviceMood: false));
  });

  test('concurrent loads share one request', () async {
    final completer = Completer<Map<String, dynamic>>();
    when(() => remote.fetchConfig()).thenAnswer((_) => completer.future);

    final first = repository.load();
    final second = repository.load();
    completer.complete({'on_device_mood': false});

    expect(await first, const AppConfig(onDeviceMood: false));
    expect(await second, const AppConfig(onDeviceMood: false));
    verify(() => remote.fetchConfig()).called(1);
  });

  test('can be built with default collaborators', () {
    expect(AppConfigRepositoryImpl.new, returnsNormally);
  });
}
