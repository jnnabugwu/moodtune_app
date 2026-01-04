import 'package:dartz/dartz.dart';
import 'package:moodtune_app/core/error/error.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;
