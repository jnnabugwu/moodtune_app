# Flutter Development Rules - MoodTune

Opinionated rules for building and maintaining the MoodTune Flutter application.

These rules guide architecture, state management, testing, and best practices for Flutter development.

---

## Core Principles

- Follow Flutter best practices and Dart standards
- Use very_good_cli for project generation and maintenance
- Implement proper state management with BLoC pattern
- Write comprehensive tests for all business logic
- Use proper dependency injection and service layer architecture
- Use clean architecture

## Clean Architecture

- **Dependency Rule**: Dependencies point inward. Outer layers depend on inner layers, never the reverse.
- **Separation of Concerns**: Each layer has a single responsibility.
- **Testability**: Business logic is independent of frameworks and external concerns.
- **Framework Independence**: Core business logic doesn't depend on Flutter, HTTP clients, or databases.

### Layers (from innermost to outermost)

#### 1. **Domain Layer** (Innermost)

- **Entities**: Core business objects (User, Playlist, MoodAnalysis, AudioFeatures)
- **Use Cases**: Business rules and application logic
- **Repository Interfaces**: Abstract contracts for data access

#### 2. **Data Layer**

- **Repository Implementations**: Concrete implementations of repository interfaces
- **Data Sources**: Remote (API) and Local (database/cache) data sources
- **Data Models**: DTOs for external data representation

#### 3. **Presentation Layer** (Outermost)

- **BLoCs/Cubits**: State management
- **Pages/Views**: UI components
- **Widgets**: Reusable UI components
- **Stateless over Stateful**: Use Stateless widgets over Stateful

### Project Structure with Clean Architecture

```
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   └── view/
│       └── app.dart
├── bootstrap.dart
├── core/
│   ├── error/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   └── network_info.dart
│   └── utils/
│       └── constants.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_data_source.dart
│   │   │   │   └── auth_local_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── login.dart
│   │   │       ├── logout.dart
│   │   │       ├── register.dart
│   │   │       └── get_current_user.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   ├── register_page.dart
│   │       │   └── profile_page.dart
│   │       └── widgets/
│   │           ├── auth_form.dart
│   │           └── password_field.dart
│   ├── spotify/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── spotify_remote_data_source.dart
│   │   │   │   └── spotify_local_data_source.dart
│   │   │   ├── models/
│   │   │   │   ├── playlist_model.dart
│   │   │   │   ├── track_model.dart
│   │   │   │   └── audio_features_model.dart
│   │   │   └── repositories/
│   │   │       └── spotify_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   ├── playlist.dart
│   │   │   │   ├── track.dart
│   │   │   │   └── audio_features.dart
│   │   │   ├── repositories/
│   │   │   │   └── spotify_repository.dart
│   │   │   └── usecases/
│   │   │       ├── connect_spotify.dart
│   │   │       ├── get_playlists.dart
│   │   │       ├── get_playlist_tracks.dart
│   │   │       └── disconnect_spotify.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── spotify_connection_bloc.dart
│   │       │   ├── playlist_bloc.dart
│   │       │   └── track_bloc.dart
│   │       ├── pages/
│   │       │   ├── spotify_connect_page.dart
│   │       │   ├── playlist_list_page.dart
│   │       │   └── playlist_detail_page.dart
│   │       └── widgets/
│   │           ├── playlist_card.dart
│   │           ├── track_item.dart
│   │           └── spotify_connect_button.dart
│   └── analysis/
│       ├── data/
│       │   ├── datasources/
│       │   │   ├── analysis_remote_data_source.dart
│       │   │   └── analysis_local_data_source.dart
│       │   ├── models/
│       │   │   ├── mood_analysis_model.dart
│       │   │   └── mood_result_model.dart
│       │   └── repositories/
│       │       └── analysis_repository_impl.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── mood_analysis.dart
│       │   │   └── mood_result.dart
│       │   ├── repositories/
│       │   │   └── analysis_repository.dart
│       │   └── usecases/
│       │       ├── analyze_playlist.dart
│       │       ├── get_analysis_history.dart
│       │       └── share_analysis.dart
│       └── presentation/
│           ├── bloc/
│           │   ├── analysis_bloc.dart
│           │   ├── analysis_event.dart
│           │   └── analysis_state.dart
│           ├── pages/
│           │   ├── analysis_page.dart
│           │   ├── mood_result_page.dart
│           │   └── history_page.dart
│           └── widgets/
│               ├── mood_chart.dart
│               ├── analysis_card.dart
│               └── share_button.dart
├── l10n/
│   └── app_en.arb
└── main.dart
```

### Generated with very_good_cli

```bash
very_good create moodtune_mobile
```

## Architecture Guidelines

### 1. Clean Architecture Implementation

#### Domain Layer - Entities

```dart
// Pure business objects, no dependencies on external frameworks
class MoodAnalysis extends Equatable {
  final String id;
  final String playlistId;
  final String playlistName;
  final MoodResult moodResult;
  final DateTime createdAt;

  const MoodAnalysis({
    required this.id,
    required this.playlistId,
    required this.playlistName,
    required this.moodResult,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, playlistId, playlistName, moodResult, createdAt];
}

class MoodResult extends Equatable {
  final String primaryMood;
  final double confidence;
  final Map<String, double> moodScores;
  final Map<String, double> audioFeaturesSummary;

  const MoodResult({
    required this.primaryMood,
    required this.confidence,
    required this.moodScores,
    required this.audioFeaturesSummary,
  });

  @override
  List<Object?> get props => [primaryMood, confidence, moodScores, audioFeaturesSummary];
}
```

#### Domain Layer - Repository Interfaces

```dart
// Abstract contracts that define what data operations are available
import 'package:result/result.dart';

abstract class AnalysisRepository {
  ResultFuture<MoodAnalysis> analyzePlaylist(String playlistId);
  ResultFuture<List<MoodAnalysis>> getAnalysisHistory();
  ResultFuture<String> shareAnalysis(String analysisId);
}
```

#### Domain Layer - Use Cases (Business Logic)

```dart
// Single responsibility business operations
import 'package:result/result.dart';

class AnalyzePlaylistUseCase implements UseCaseWithParams<MoodAnalysis, AnalyzePlaylistParams> {
  final AnalysisRepository repository;

  const AnalyzePlaylistUseCase(this.repository);

  @override
  ResultFuture<MoodAnalysis> call(AnalyzePlaylistParams params) async {
    return await repository.analyzePlaylist(params.playlistId);
  }
}

class AnalyzePlaylistParams extends Equatable {
  final String playlistId;

  const AnalyzePlaylistParams({required this.playlistId});

  @override
  List<Object> get props => [playlistId];
}
```

**Why Use Cases?**
- **Single Responsibility**: Each use case does one thing well
- **Testability**: Easy to unit test business logic in isolation
- **Reusability**: Same business logic can be used by different UI components
- **Maintainability**: Changes to business rules are centralized
- **Documentation**: Use cases serve as living documentation of what your app can do

**Why ResultFuture?**
- **Cleaner Syntax**: `ResultFuture<T>` is much cleaner than `Future<Either<Failure, T>>`
- **Better Readability**: `result.when(success: ..., failure: ...)` is more intuitive
- **Type Safety**: Compile-time guarantees about success/failure handling
- **Composability**: Easy to chain operations and handle errors consistently
- **Performance**: No boxing/unboxing overhead compared to Either

**Alternative Approach**: If you prefer, you can start with simpler repository methods and refactor to use cases later as complexity grows.

#### Data Layer - Repository Implementation

```dart
import 'package:result/result.dart';

class AnalysisRepositoryImpl implements AnalysisRepository {
  final AnalysisRemoteDataSource remoteDataSource;
  final AnalysisLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const AnalysisRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  ResultFuture<MoodAnalysis> analyzePlaylist(String playlistId) async {
    if (await networkInfo.isConnected) {
      try {
        final analysisModel = await remoteDataSource.analyzePlaylist(playlistId);
        await localDataSource.cacheAnalysis(analysisModel);
        return Result.success(analysisModel.toDomain());
      } on ServerException catch (e) {
        return Result.failure(ServerFailure(e.message));
      }
    } else {
      return Result.failure(NetworkFailure('No internet connection'));
    }
  }

  @override
  ResultFuture<List<MoodAnalysis>> getAnalysisHistory() async {
    if (await networkInfo.isConnected) {
      try {
        final analyses = await remoteDataSource.getAnalysisHistory();
        await localDataSource.cacheAnalyses(analyses);
        return Result.success(analyses.map((m) => m.toDomain()).toList());
      } on ServerException catch (e) {
        return Result.failure(ServerFailure(e.message));
      }
    } else {
      try {
        final cachedAnalyses = await localDataSource.getCachedAnalyses();
        return Result.success(cachedAnalyses.map((m) => m.toDomain()).toList());
      } on CacheException catch (e) {
        return Result.failure(CacheFailure(e.message));
      }
    }
  }
}
```

### 2. BLoC Pattern for State Management with ResultFuture

- Use `flutter_bloc` for state management
- Keep BLoCs focused and single-responsibility
- Use `equatable` for value equality in states and events
- Implement proper error handling in BLoCs using ResultFuture

```dart
// Example BLoC using ResultFuture
class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final AnalyzePlaylistUseCase analyzePlaylistUseCase;
  final GetAnalysisHistoryUseCase getAnalysisHistoryUseCase;

  AnalysisBloc({
    required this.analyzePlaylistUseCase,
    required this.getAnalysisHistoryUseCase,
  }) : super(AnalysisInitial()) {
    on<AnalyzePlaylistRequested>(_onAnalyzePlaylistRequested);
    on<LoadAnalysisHistory>(_onLoadAnalysisHistory);
  }

  Future<void> _onAnalyzePlaylistRequested(
    AnalyzePlaylistRequested event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(AnalysisLoading());
    
    final result = await analyzePlaylistUseCase(
      AnalyzePlaylistParams(playlistId: event.playlistId),
    );

    result.when(
      success: (analysis) => emit(AnalysisComplete(analysis)),
      failure: (failure) => emit(AnalysisError(failure.message)),
    );
  }

  Future<void> _onLoadAnalysisHistory(
    LoadAnalysisHistory event,
    Emitter<AnalysisState> emit,
  ) async {
    emit(AnalysisHistoryLoading());
    
    final result = await getAnalysisHistoryUseCase(NoParams());

    result.when(
      success: (analyses) => emit(AnalysisHistoryLoaded(analyses)),
      failure: (failure) => emit(AnalysisError(failure.message)),
    );
  }
}
```

```dart
// Example BLoC structure
abstract class AnalysisEvent extends Equatable {
  const AnalysisEvent();
}

class AnalyzePlaylistRequested extends AnalysisEvent {
  final String playlistId;

  const AnalyzePlaylistRequested(this.playlistId);

  @override
  List<Object> get props => [playlistId];
}

abstract class AnalysisState extends Equatable {
  const AnalysisState();
}

class AnalysisInitial extends AnalysisState {
  const AnalysisInitial();

  @override
  List<Object> get props => [];
}

class AnalysisLoading extends AnalysisState {
  const AnalysisLoading();

  @override
  List<Object> get props => [];
}

class AnalysisComplete extends AnalysisState {
  final MoodAnalysis analysis;

  const AnalysisComplete(this.analysis);

  @override
  List<Object> get props => [analysis];
}
```

### 3. Repository Pattern

- Create repositories for data access
- Use dependency injection for repositories
- Implement proper error handling and data transformation
- Use ResultFuture for consistent error handling

```dart
abstract class SpotifyRepository {
  ResultFuture<SpotifyConnection> connectSpotify(String authCode);
  ResultFuture<List<Playlist>> getPlaylists();
  ResultFuture<Playlist> getPlaylistDetails(String playlistId);
  ResultFuture<void> disconnectSpotify();
}

class SpotifyRepositoryImpl implements SpotifyRepository {
  final SpotifyRemoteDataSource _remoteDataSource;
  final SpotifyLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;
  
  const SpotifyRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );
  
  @override
  ResultFuture<List<Playlist>> getPlaylists() async {
    if (await _networkInfo.isConnected) {
      try {
        final playlists = await _remoteDataSource.getPlaylists();
        await _localDataSource.cachePlaylists(playlists);
        return Result.success(playlists.map((p) => p.toDomain()).toList());
      } on ServerException catch (e) {
        return Result.failure(ServerFailure(e.message));
      }
    } else {
      try {
        final cached = await _localDataSource.getCachedPlaylists();
        return Result.success(cached.map((p) => p.toDomain()).toList());
      } on CacheException catch (e) {
        return Result.failure(CacheFailure(e.message));
      }
    }
  }
}
```

### 4. Service Layer

- Create services for external API calls
- Use proper HTTP client with interceptors
- Implement retry logic and error handling
- Use secure token storage for authentication

```dart
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  
  ApiClient(this._tokenStorage) : _dio = Dio() {
    _dio.options.baseUrl = 'http://localhost:8000/api/v1';
    _dio.interceptors.add(AuthInterceptor(_tokenStorage));
    _dio.interceptors.add(LoggingInterceptor());
    _dio.interceptors.add(RetryInterceptor());
  }
  
  Future<Map<String, dynamic>> get(String path) async {
    final response = await _dio.get(path);
    return response.data;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    final response = await _dio.post(path, data: data);
    return response.data;
  }
}
```

## API Integration

### 1. HTTP Client Setup

- Use `dio` for HTTP requests
- Implement proper interceptors for authentication
- Handle different response types and errors

```dart
class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;
  
  AuthInterceptor(this._tokenStorage);
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
  
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Attempt token refresh
      final refreshed = await _tokenStorage.refreshToken();
      if (refreshed) {
        // Retry the request
        final options = err.requestOptions;
        final token = await _tokenStorage.getAccessToken();
        options.headers['Authorization'] = 'Bearer $token';
        try {
          final response = await Dio().fetch(options);
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      } else {
        // Logout user
        await _tokenStorage.clearTokens();
      }
    }
    handler.next(err);
  }
}
```

### 2. Model Classes

- Use `json_annotation` for JSON serialization
- Implement proper fromJson/toJson methods
- Use `freezed` for immutable data classes
- Map FastAPI Pydantic models to Flutter entities

```dart
@freezed
class PlaylistModel with _$PlaylistModel {
  const factory PlaylistModel({
    required String id,
    required String name,
    String? description,
    required int tracksTotal,
    String? imageUrl,
  }) = _PlaylistModel;

  factory PlaylistModel.fromJson(Map<String, dynamic> json) =>
      _$PlaylistModelFromJson(json);
}

extension PlaylistModelX on PlaylistModel {
  Playlist toDomain() {
    return Playlist(
      id: id,
      name: name,
      description: description,
      tracksTotal: tracksTotal,
      imageUrl: imageUrl,
    );
  }
}
```

## Testing Requirements

### 1. Unit Tests

- Test all BLoCs with `bloc_test`
- Mock dependencies using `mocktail`
- Aim for >80% code coverage

```dart
group('AnalysisBloc', () {
  late AnalysisBloc analysisBloc;
  late MockAnalyzePlaylistUseCase mockAnalyzePlaylistUseCase;

  setUp(() {
    mockAnalyzePlaylistUseCase = MockAnalyzePlaylistUseCase();
    analysisBloc = AnalysisBloc(
      analyzePlaylistUseCase: mockAnalyzePlaylistUseCase,
    );
  });

  tearDown(() {
    analysisBloc.close();
  });

  test('initial state is AnalysisInitial', () {
    expect(analysisBloc.state, const AnalysisInitial());
  });

  blocTest<AnalysisBloc, AnalysisState>(
    'emits [AnalysisLoading, AnalysisComplete] when analysis succeeds',
    build: () {
      when(() => mockAnalyzePlaylistUseCase(any()))
          .thenAnswer((_) async => Result.success(tMoodAnalysis));
      return analysisBloc;
    },
    act: (bloc) => bloc.add(const AnalyzePlaylistRequested('playlist123')),
    expect: () => [
      const AnalysisLoading(),
      AnalysisComplete(tMoodAnalysis),
    ],
  );
});
```

### 2. Widget Tests

- Test all UI components
- Use `golden_toolkit` for visual regression testing
- Test user interactions and state changes

```dart
testWidgets('MoodResultPage displays mood correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider(
        create: (_) => mockAnalysisBloc,
        child: const MoodResultPage(),
      ),
    ),
  );
  
  expect(find.text('Happy'), findsOneWidget);
  expect(find.byType(MoodChart), findsOneWidget);
});
```

### 3. Integration Tests

- Test complete user flows
- Use `integration_test` package
- Test API integration and navigation

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('analyze playlist flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login
    await tester.enterText(find.byKey(const Key('email')), 'test@example.com');
    await tester.enterText(find.byKey(const Key('password')), 'password');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // Navigate to playlists
    await tester.tap(find.byKey(const Key('playlists_tab')));
    await tester.pumpAndSettle();

    // Select playlist
    await tester.tap(find.byType(PlaylistCard).first);
    await tester.pumpAndSettle();

    // Analyze
    await tester.tap(find.byKey(const Key('analyze_button')));
    await tester.pumpAndSettle();

    // Verify mood result is displayed
    expect(find.byType(MoodChart), findsOneWidget);
  });
}
```

## Code Standards

### 1. Naming Conventions

- Use `snake_case` for files and directories
- Use `PascalCase` for classes and enums
- Use `camelCase` for variables and methods
- Use descriptive names that explain purpose

### 2. File Organization

- Group related files in feature directories
- Separate UI, business logic, and data layers
- Use consistent file naming patterns

### 3. Documentation

- Add documentation comments for public APIs
- Use `///` for documentation comments
- Document complex business logic

```dart
/// A repository that handles playlist mood analysis operations.
/// 
/// This repository provides methods to analyze playlists, retrieve
/// analysis history, and share analysis results with other users.
abstract class AnalysisRepository {
  /// Analyzes a Spotify playlist and returns mood analysis results.
  /// 
  /// Returns a [MoodAnalysis] object containing the mood breakdown,
  /// confidence scores, and audio feature summaries.
  /// 
  /// Throws [ServerException] if the API request fails.
  /// Throws [NetworkException] if there's no internet connection.
  ResultFuture<MoodAnalysis> analyzePlaylist(String playlistId);
}
```

## Core Utilities for Clean Architecture

### Error Handling

```dart
// core/error/failures.dart
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(String message) : super(message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(String message) : super(message);
}

class CacheFailure extends Failure {
  const CacheFailure(String message) : super(message);
}

class SpotifyAuthFailure extends Failure {
  const SpotifyAuthFailure(String message) : super(message);
}

// core/error/exceptions.dart
class ServerException implements Exception {
  final String message;
  const ServerException(this.message);
}

class CacheException implements Exception {
  final String message;
  const CacheException(this.message);
}

class SpotifyAuthException implements Exception {
  final String message;
  const SpotifyAuthException(this.message);
}
```

### Use Case Base Classes with ResultFuture

```dart
// core/usecases/usecase.dart
import 'package:result/result.dart';

abstract class UseCaseWithParams<Type, Params> {
  ResultFuture<Type> call(Params params);
}

abstract class UseCaseWithoutParams<Type> {
  ResultFuture<Type> call(NoParams params);
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
```

### Network Info

```dart
// core/network/network_info.dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final InternetConnectionChecker connectionChecker;

  const NetworkInfoImpl(this.connectionChecker);

  @override
  Future<bool> get isConnected => connectionChecker.hasConnection;
}
```

## Dependencies

### Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_bloc: ^8.1.3
  equatable: ^2.0.5
  json_annotation: ^4.8.1
  dio: ^5.3.2
  get_it: ^7.6.4
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  internet_connection_checker: ^1.0.0
  go_router: ^12.1.3
  result: ^1.0.0
  freezed_annotation: ^2.4.1
  fl_chart: ^0.66.0  # For mood visualization charts
  cached_network_image: ^3.3.1
  url_launcher: ^6.2.2  # For Spotify OAuth

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.4
  mocktail: ^1.0.2
  json_serializable: ^6.7.1
  build_runner: ^2.4.7
  freezed: ^2.4.6
  very_good_analysis: ^5.1.0
  integration_test:
    sdk: flutter
```

## Dependency Injection

### GetIt Setup for Clean Architecture

```dart
// core/injection/injection_container.dart
final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Analysis
  // Bloc
  sl.registerFactory(() => AnalysisBloc(
    analyzePlaylistUseCase: sl(),
    getAnalysisHistoryUseCase: sl(),
    shareAnalysisUseCase: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => AnalyzePlaylistUseCase(sl()));
  sl.registerLazySingleton(() => GetAnalysisHistoryUseCase(sl()));
  sl.registerLazySingleton(() => ShareAnalysisUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AnalysisRepository>(
    () => AnalysisRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AnalysisRemoteDataSource>(
    () => AnalysisRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AnalysisLocalDataSource>(
    () => AnalysisLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Spotify
  // Bloc
  sl.registerFactory(() => SpotifyConnectionBloc(
    connectSpotifyUseCase: sl(),
    disconnectSpotifyUseCase: sl(),
  ));
  sl.registerFactory(() => PlaylistBloc(
    getPlaylistsUseCase: sl(),
    getPlaylistDetailsUseCase: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => ConnectSpotifyUseCase(sl()));
  sl.registerLazySingleton(() => DisconnectSpotifyUseCase(sl()));
  sl.registerLazySingleton(() => GetPlaylistsUseCase(sl()));
  sl.registerLazySingleton(() => GetPlaylistDetailsUseCase(sl()));

  // Repository
  sl.registerLazySingleton<SpotifyRepository>(
    () => SpotifyRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<SpotifyRemoteDataSource>(
    () => SpotifyRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<SpotifyLocalDataSource>(
    () => SpotifyLocalDataSourceImpl(sharedPreferences: sl()),
  );

  //! Features - Auth
  // Bloc
  sl.registerFactory(() => AuthBloc(
    loginUseCase: sl(),
    registerUseCase: sl(),
    logoutUseCase: sl(),
    getCurrentUserUseCase: sl(),
  ));

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      sharedPreferences: sl(),
      secureStorage: sl(),
    ),
  );

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => TokenStorage(sl()));

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => InternetConnectionChecker());
  sl.registerLazySingleton(() => ApiClient(sl()));
}
```

## Authentication Flow

### 1. Token Management

- Store tokens securely using `flutter_secure_storage`
- Implement token refresh logic with automatic retry
- Handle authentication state changes and token expiration
- Use in-memory caching for performance

```dart
class TokenStorage {
  final FlutterSecureStorage _secureStorage;
  String? _accessToken;
  String? _refreshToken;

  TokenStorage(this._secureStorage);

  Future<String?> getAccessToken() async {
    _accessToken ??= await _secureStorage.read(key: 'access_token');
    return _accessToken;
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
  }

  Future<bool> refreshToken() async {
    final refresh = _refreshToken ?? 
        await _secureStorage.read(key: 'refresh_token');
    
    if (refresh == null) return false;

    try {
      // Call refresh endpoint
      final response = await Dio().post(
        'http://localhost:8000/api/v1/auth/refresh',
        data: {'refresh_token': refresh},
      );
      
      await saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
  }
}
```

### 2. Login/Logout

- Use BLoC for authentication state management
- Implement proper error handling with ResultFuture
- Navigate based on authentication state
- Clear tokens securely on logout

## Navigation

### 1. Routing

- Use `go_router` for navigation
- Implement proper route guards
- Handle deep linking for Spotify OAuth callback

```dart
final router = GoRouter(
  refreshListenable: authStateNotifier,
  redirect: (context, state) {
    final isAuthenticated = authStateNotifier.isAuthenticated;
    final isLoggingIn = state.location == '/login' || 
                        state.location == '/register';

    if (!isAuthenticated && !isLoggingIn) {
      return '/login';
    }

    if (isAuthenticated && isLoggingIn) {
      return '/';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/playlists',
      builder: (context, state) => const PlaylistListPage(),
    ),
    GoRoute(
      path: '/playlist/:id',
      builder: (context, state) => PlaylistDetailPage(
        playlistId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/analysis/:id',
      builder: (context, state) => MoodResultPage(
        analysisId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryPage(),
    ),
    GoRoute(
      path: '/spotify/callback',
      builder: (context, state) => SpotifyCallbackPage(
        code: state.queryParameters['code'],
      ),
    ),
  ],
);
```

### 2. Navigation State

- Manage navigation state in BLoC
- Handle back navigation properly
- Implement proper route transitions

## Performance

### 1. Widget Optimization

- Use `const` constructors where possible
- Implement proper `ListView.builder` for playlist/track lists
- Use `RepaintBoundary` for complex mood charts

```dart
class PlaylistList extends StatelessWidget {
  final List<Playlist> playlists;

  const PlaylistList({required this.playlists, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        return const PlaylistCard(playlist: playlists[index]);
      },
    );
  }
}
```

### 2. Memory Management

- Dispose of controllers and streams properly
- Use weak references where appropriate
- Monitor memory usage in development
- Cache network images properly

## Localization

### 1. Internationalization

- Use `flutter_localizations` and `intl`
- Store strings in ARB files
- Implement proper pluralization

### 2. RTL Support

- Test with RTL languages
- Use proper alignment and directionality
- Handle text direction changes

## Common Commands

### Development

```bash
# Generate code
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch

# Run tests
flutter test

# Run integration tests
flutter test integration_test/

# Analyze code
flutter analyze

# Format code
dart format .
```

### very_good_cli Commands

```bash
# Create new project
very_good create moodtune_mobile

# Create new feature
very_good create feature analysis

# Create new BLoC
very_good create bloc mood_analysis

# Create new page
very_good create page mood_result

# Run tests
very_good test

# Check code coverage
very_good test --coverage
```

## Review Checklist

- [ ] BLoCs have proper state and event classes
- [ ] All dependencies are properly injected
- [ ] Error handling is implemented with ResultFuture
- [ ] Tests are written for all business logic
- [ ] UI components are tested
- [ ] Code follows naming conventions
- [ ] Documentation is added for public APIs
- [ ] Performance considerations are implemented
- [ ] Localization is properly set up
- [ ] Navigation is handled correctly
- [ ] Token management is secure
- [ ] API integration matches FastAPI endpoints

---

## Integration with FastAPI Backend

### API Endpoints

```dart
class ApiEndpoints {
  static const String baseUrl = 'http://localhost:8000';
  static const String apiVersion = '/api/v1';
  
  // Auth
  static const String register = '$apiVersion/auth/register';
  static const String login = '$apiVersion/auth/login';
  static const String refresh = '$apiVersion/auth/refresh';
  
  // Spotify
  static const String spotifyConnect = '$apiVersion/spotify/connect';
  static const String spotifyCallback = '$apiVersion/spotify/callback';
  static const String spotifyPlaylists = '$apiVersion/spotify/playlists';
  static String spotifyPlaylist(String id) => '$apiVersion/spotify/playlists/$id';
  
  // Analysis
  static const String analyzePlaylist = '$apiVersion/analysis/analyze';
  static const String analysisHistory = '$apiVersion/analysis/history';
  static String shareAnalysis(String id) => '$apiVersion/analysis/$id/share';
}
```

### Environment Configuration

```dart
abstract class Environment {
  static const String dev = 'dev';
  static const String staging = 'staging';
  static const String prod = 'prod';
  
  static String get current => const String.fromEnvironment('ENV', defaultValue: dev);
  
  static String get apiUrl {
    switch (current) {
      case dev:
        return 'http://localhost:8000';
      case staging:
        return 'https://staging-api.moodtune.com';
      case prod:
        return 'https://api.moodtune.com';
      default:
        return 'http://localhost:8000';
    }
  }
}
```

This guide ensures consistent, maintainable, and testable Flutter code that integrates seamlessly with your FastAPI backend.
