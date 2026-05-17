class RouteNames {
  RouteNames._();

  // ── Legacy routes (kept for backward compat) ────────────────────────
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

  // ── New routes (redesign) ────────────────────────────────────────────
  /// Landing / guest home — initial location for unauthenticated users.
  static const String landing = '/';

  /// Unified sign-in / sign-up screen (replaces /login + /signup).
  static const String signIn = '/sign-in';

  static const String emailVerify = '/email-verify';
  static const String forgotPassword = '/forgot-password';

  /// Authenticated home (tabs: Home + History).
  static const String homeAuth = '/home';

  static const String history = '/history';
  static const String catalog = '/catalog';

  /// Upload file selection screen.
  static const String uploadMusic = '/upload-music';

  /// Unified analysis loading screen (upload or catalog source).
  static const String analysisLoading = '/analysis/loading';

  /// Unified results screen.
  static const String result = '/analysis/result';

  // ── Helpers ──────────────────────────────────────────────────────────
  static const String guest = '/guest';

  static String analyzingFor(String playlistId) =>
      '/analysis/analyzing/$playlistId';

  static String analysisResultFor(String id) => '/analysis/$id';

  static String playlistTracksFor(String playlistId) =>
      '/playlist/$playlistId/tracks';

  static String songAnalyzingFor(String trackId) => '/song/analyzing/$trackId';
}
