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

/// Exception for on-device audio decoding (see `AudioWindowDecoder`).
///
/// [code] mirrors the native error: `unreadable` (missing file or a format
/// this OS can't open), `empty`, `decode_failed`, `bad_args`, `bad_reply`,
/// or `unavailable` when the platform has no native decoder.
class AudioDecodeException implements Exception {
  const AudioDecodeException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'AudioDecodeException($code): $message';
}
