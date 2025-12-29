import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:moodtune_app/core/error/error.dart';
import 'package:moodtune_app/features/spotify/data/models/models.dart';
import 'package:moodtune_app/features/spotify/domain/entities/entities.dart';
import 'package:moodtune_app/features/spotify/domain/repositories/spotify_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

typedef TokenProvider = Future<String?> Function();

/// Spotify repository that talks to the backend REST API.
class SpotifyRepositoryImpl implements SpotifyRepository {
  SpotifyRepositoryImpl({
    Dio? dio,
    String baseUrl = defaultBaseUrl,
    TokenProvider? tokenProvider,
  })  : _tokenProvider = tokenProvider ?? _noToken,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
              ),
            );

  static const defaultBaseUrl = 'http://127.0.0.1:8000/api/v1';
  final Dio _dio;
  final TokenProvider _tokenProvider;

  String? _state;

  static Future<String?> _noToken() async => null;

  Future<Options> _options() async {
    final token = await _tokenProvider();
    return Options(
      headers: token != null
          ? {
              'Authorization': 'Bearer $token',
            }
          : null,
    );
  }

  @override
  ResultFuture<String> getAuthorizeUrl() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/spotify/authorize',
        options: await _options(),
      );
      final data = response.data ?? <String, dynamic>{};
      final url = data['authorize_url'] as String?;
      _state = data['state'] as String?;

      if (url == null || url.isEmpty) {
        return const Left(ServerFailure('Missing authorize_url from server'));
      }

      return Right(url);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<SpotifyConnection> connectSpotify(String authCode) async {
    try {
      await _dio.get<void>(
        '/spotify/callback',
        queryParameters: {
          'code': authCode,
          if (_state != null) 'state': _state,
        },
        options: await _options(),
      );

      return Right(
        SpotifyConnection(
          isConnected: true,
          connectedAt: DateTime.now(),
        ),
      );
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<bool> checkConnection() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/spotify/status',
        options: await _options(),
      );
      final data = response.data ?? <String, dynamic>{};
      final connected = data['connected'] as bool? ?? false;
      return Right(connected);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<void> disconnect() async {
    try {
      await _dio.post<void>(
        '/spotify/disconnect',
        options: await _options(),
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  ResultFuture<SpotifyProfile> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/spotify/profile',
        options: await _options(),
      );
      final data = response.data ?? <String, dynamic>{};
      final profileJson = (data['profile'] as Map<String, dynamic>?) ?? data;
      final profileModel = SpotifyProfileModel.fromJson(profileJson);
      return Right(profileModel.toDomain());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Failure _mapDioError(DioException e) {
    final message = e.response?.data is Map
        ? (e.response?.data['detail'] as String?) ??
            (e.response?.data['message'] as String?) ??
            e.message
        : e.message;
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return NetworkFailure(message ?? 'Network error');
    }
    return ServerFailure(message ?? 'Server error');
  }
}

