/// Base class for server/API exceptions
class ServerException implements Exception {
  const ServerException(this.message);

  final String message;

  @override
  String toString() => 'ServerException: $message';
}

/// Exception for local storage/cache errors
class CacheException implements Exception {
  const CacheException(this.message);

  final String message;

  @override
  String toString() => 'CacheException: $message';
}

/// Exception for Spotify OAuth authentication errors
class SpotifyAuthException implements Exception {
  const SpotifyAuthException(this.message);

  final String message;

  @override
  String toString() => 'SpotifyAuthException: $message';
}
