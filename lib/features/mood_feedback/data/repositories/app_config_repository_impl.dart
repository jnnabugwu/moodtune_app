import 'package:moodtune_app/core/logging/talker.dart';
import 'package:moodtune_app/features/mood_feedback/data/datasources/app_config_remote_datasource.dart';
import 'package:moodtune_app/features/mood_feedback/data/models/app_config_model.dart';
import 'package:moodtune_app/features/mood_feedback/domain/entities/app_config.dart';
import 'package:moodtune_app/features/mood_feedback/domain/repositories/app_config_repository.dart';

/// Fetches `GET /config`, caching a successful result in memory for
/// `cacheTtl`. [load] never throws.
///
/// On failure it returns the last successfully fetched config if there is
/// one (so a flaky network can't undo a kill switch the app already saw),
/// otherwise [AppConfig.fallback]. Failures are not cached, so the next
/// call retries.
class AppConfigRepositoryImpl implements AppConfigRepository {
  AppConfigRepositoryImpl({
    AppConfigRemoteDataSource? remoteDataSource,
    Duration cacheTtl = defaultCacheTtl,
    DateTime Function()? clock,
  }) : _remote = remoteDataSource ?? AppConfigRemoteDataSource(),
       _cacheTtl = cacheTtl,
       _clock = clock ?? DateTime.now;

  static const defaultCacheTtl = Duration(minutes: 10);

  final AppConfigRemoteDataSource _remote;
  final Duration _cacheTtl;
  final DateTime Function() _clock;

  AppConfig? _cached;
  DateTime? _fetchedAt;
  Future<AppConfig>? _inFlight;

  @override
  Future<AppConfig> load() {
    final cached = _cached;
    final fetchedAt = _fetchedAt;
    if (cached != null &&
        fetchedAt != null &&
        _clock().difference(fetchedAt) < _cacheTtl) {
      return Future.value(cached);
    }
    // Share one request between concurrent callers.
    return _inFlight ??= _fetch().whenComplete(() => _inFlight = null);
  }

  Future<AppConfig> _fetch() async {
    try {
      final json = await _remote.fetchConfig();
      final config = AppConfigModel.fromJson(json).toDomain();
      _cached = config;
      _fetchedAt = _clock();
      return config;
    } on Object catch (e, s) {
      // Any failure (network, bad JSON, even an Error) must fall back.
      talker.warning('App config unavailable, using fallback: $e', e, s);
      return _cached ?? AppConfig.fallback;
    }
  }
}
