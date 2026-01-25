class RouteNames {
  RouteNames._();

  static const String login = '/login';
  static const String signup = '/signup';
  static const String spotify = '/spotify';
  static const String callback = '/callback';
  static const String playlists = '/spotify/playlists';
  static const String playlistTracks = '/playlist/:playlistId/tracks';
  static const String analyzing = '/analysis/analyzing/:playlistId';
  static const String analysisResult = '/analysis/:id';
  static const String songAnalyzing = '/song/analyzing/:trackId';
  static const String songResult = '/song/result';
  static const String notFound = '/404';

  static String analyzingFor(String playlistId) =>
      '/analysis/analyzing/$playlistId';

  static String analysisResultFor(String id) => '/analysis/$id';

  static String playlistTracksFor(String playlistId) =>
      '/playlist/$playlistId/tracks';

  static String songAnalyzingFor(String trackId) => '/song/analyzing/$trackId';
}
