import 'package:equatable/equatable.dart';

/// Base class for all failures
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object> get props => [message];
}

/// Failure for server/API errors
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Failure for network connectivity issues
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Failure for local storage/cache errors
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure for Spotify OAuth authentication errors
class SpotifyAuthFailure extends Failure {
  const SpotifyAuthFailure(super.message);
}
