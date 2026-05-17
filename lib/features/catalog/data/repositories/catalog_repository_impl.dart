import 'package:dartz/dartz.dart';
import 'package:moodtune_app/core/error/exceptions.dart';
import 'package:moodtune_app/core/error/failures.dart';
import 'package:moodtune_app/features/catalog/data/datasources/jamendo_remote_datasource.dart';
import 'package:moodtune_app/features/catalog/domain/entities/jamendo_track.dart';
import 'package:moodtune_app/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:moodtune_app/utils/typedef.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl({required this.dataSource});

  final JamendoRemoteDataSource dataSource;

  @override
  ResultFuture<List<JamendoTrack>> searchTracks({
    String? query,
    String? moodTag,
  }) async {
    try {
      final models = await dataSource.searchTracks(
        query: query,
        moodTag: moodTag,
      );
      // Filter to tracks that permit download (required for backend analysis)
      final tracks = models
          .where((m) => m.audiodownloadAllowed)
          .map((m) => m.toDomain())
          .toList();
      return Right(tracks);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
