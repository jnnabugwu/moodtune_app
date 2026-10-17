# Authentication System Implementation Plan

This document outlines the complete authentication system architecture based on Supabase, designed for a Flutter mobile application using Clean Architecture principles.

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Dependencies](#dependencies)
3. [Core Components](#core-components)
4. [Authentication Service](#authentication-service)
5. [Repository Pattern](#repository-pattern)
6. [Use Cases](#use-cases)
7. [Domain Entities](#domain-entities)
8. [Implementation Steps](#implementation-steps)
9. [Important Considerations](#important-considerations)

---

## Architecture Overview

The authentication system follows **Clean Architecture** with three main layers:

```
┌─────────────────────────────────────┐
│      Presentation Layer             │
│  (BLoC, UI Components)              │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│       Domain Layer                  │
│  (Entities, Use Cases, Repository) │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        Data Layer                   │
│  (Services, Data Sources, Models)   │
└─────────────────────────────────────┘
```

### Layer Responsibilities

- **Domain Layer**: Business logic, entities, use cases, repository interfaces
- **Data Layer**: External API calls, data sources, service implementations
- **Presentation Layer**: State management (BLoC), UI components

---

## Dependencies

### Required Packages

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  # Authentication
  supabase_flutter: ^2.5.6
  google_sign_in: ^6.2.1
  sign_in_with_apple: ^6.1.2
  
  # Network & HTTP
  dio: ^5.3.2
  internet_connection_checker: ^1.0.0
  
  # Secure Storage
  flutter_secure_storage: ^9.0.0
  
  # State Management
  bloc: ^9.0.0
  flutter_bloc: ^9.1.1
  
  # Clean Architecture
  dartz: ^0.10.1  # For Either<Failure, Success> pattern
  equatable: ^2.0.5
  
  # Dependency Injection
  get_it: ^7.6.4
  
  # JSON Serialization
  json_annotation: ^4.8.1

dev_dependencies:
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
  mocktail: ^1.0.4
```

---

## Core Components

### 1. TokenStorage

**Purpose**: Securely store authentication tokens with automatic size optimization.

**Location**: `lib/core/network/token_storage.dart`

**Key Features**:
- Uses `FlutterSecureStorage` for secure keychain storage
- Handles large tokens through chunking (if > 3500 chars)
- In-memory caching for performance
- Automatic compression support (placeholder for future implementation)

**Key Methods**:
```dart
class TokenStorage {
  Future<void> storeToken(String token)
  Future<String?> getToken()
  Future<void> clearToken()
}
```

**Implementation Notes**:
- Tokens < 3500 chars: stored directly
- Tokens 3500-7000 chars: compression attempted, falls back to chunking
- Tokens > 7000 chars: chunked storage (3000 char chunks)
- Maintains `token_storage_type` metadata for retrieval

### 2. ApiClient

**Purpose**: HTTP client wrapper using Dio with interceptors.

**Location**: `lib/core/network/api_client.dart`

**Key Features**:
- Base URL configuration from environment
- Automatic token injection via `AuthInterceptor`
- Error handling, logging, and retry logic
- Standard HTTP methods (GET, POST, PUT, DELETE, PATCH)

**Interceptors** (in order):
1. `AuthInterceptor` - Adds Bearer token to requests
2. `LoggingInterceptor` - Logs requests/responses
3. `RetryInterceptor` - Retries failed requests
4. `ErrorInterceptor` - Handles errors globally

### 3. AuthInterceptor

**Purpose**: Automatically adds authentication tokens to API requests and handles token refresh.

**Location**: `lib/core/network/interceptors/auth_interceptor.dart`

**Key Features**:
- Adds `Authorization: Bearer <token>` header to all requests
- Handles 401 Unauthorized responses
- Automatic token refresh via Supabase
- Retries failed requests after token refresh
- Clears token on refresh failure

**Flow**:
1. `onRequest`: Retrieves token from `TokenStorage` and adds to headers
2. `onError`: On 401, attempts Supabase session refresh, updates token, retries request

---

## Authentication Service

### SupabaseAuthService

**Purpose**: Core authentication service handling all auth operations with Supabase.

**Location**: `lib/features/auth/data/datasources/supabase_auth_service.dart`

**Dependencies**:
- `ApiClient` - For backend API calls (e.g., account deletion)
- `TokenStorage` - For storing access tokens
- `SupabaseClient` - From `supabase_flutter` package

### Authentication Methods

#### 1. Email/Password Authentication

```dart
// Sign Up
Future<User> signUpWithEmail({
  required String email,
  required String password,
  required String fullName,
})

// Sign In
Future<User> signInWithEmail({
  required String email,
  required String password,
})
```

**Flow**:
1. Call Supabase auth method
2. Extract session access token
3. Store token in `TokenStorage`
4. Map Supabase user to app `User` entity
5. Return user

#### 2. Google Sign-In

```dart
Future<User> signInWithGoogle()
```

**Flow**:
1. Initialize `GoogleSignIn` with client IDs:
   - `serverClientId`: Web Client ID (for backend)
   - `clientId`: iOS Client ID (for mobile)
   - Scopes: `['email', 'profile']`
2. Trigger Google Sign-In flow
3. Extract `accessToken` and `idToken`
4. Sign into Supabase using `signInWithIdToken` with `OAuthProvider.google`
5. Store access token
6. Return mapped user
7. On error: Sign out from Google and rethrow

**Configuration Required**:
- Google Cloud Console setup
- OAuth 2.0 Client IDs for iOS and Web
- Supabase Google OAuth provider configuration

#### 3. Apple Sign-In

```dart
Future<User> signInWithApple()
```

**Flow**:
1. Request Apple ID credential with scopes:
   - `AppleIDAuthorizationScopes.email`
   - `AppleIDAuthorizationScopes.fullName`
2. Extract `identityToken`
3. Sign into Supabase using `signInWithIdToken` with `OAuthProvider.apple`
4. Store access token
5. **First sign-in only**: Update user profile with name (Apple only provides name on first sign-in)
   - Upsert to `user_profiles` table with `full_name`
6. Return mapped user

**Error Handling**:
- `SignInWithAppleAuthorizationException` with `AuthorizationErrorCode.canceled` → User cancelled
- Other errors → Re-throw with descriptive message

**Configuration Required**:
- Apple Developer account setup
- Sign in with Apple capability enabled
- Supabase Apple OAuth provider configuration

#### 4. Sign Out

```dart
Future<void> signOut()
```

**Flow**:
1. Sign out from Supabase (`_client.auth.signOut()`)
2. Sign out from Google (`signOutFromGoogle()`)
3. Clear stored token (`_tokenStorage.clearToken()`)

#### 5. Get Current User

```dart
Future<User?> getCurrentUser()
```

**Flow**:
1. Get current user from Supabase
2. Sync token from Supabase session to `TokenStorage`
3. Map and return user, or `null` if not authenticated

#### 6. Check Authentication Status

```dart
bool isAuthenticated()
```

Returns `true` if `_client.auth.currentUser != null`.

#### 7. Delete User Account

```dart
Future<void> deleteAndLogoutUser()
```

**Flow**:
1. Call backend API `DELETE /api/v1/users/me` (via `ApiClient`)
2. On success: Sign out from Supabase and Google
3. Clear stored token
4. On error: Throw exception

**Note**: Backend handles actual account deletion. This method coordinates the deletion and cleanup.

### User Mapping

**Method**: `_mapSupabaseUserToAppUser(User supabaseUser)`

**Mapping Logic**:
- `userId` ← `supabaseUser.id`
- `email` ← `supabaseUser.email` (fallback to empty string)
- `fullName` ← `supabaseUser.userMetadata['full_name']` (fallback to email if null/empty)
- `avatarUrl` ← `supabaseUser.userMetadata['avatar_url']`
- `emailVerified` ← `supabaseUser.emailConfirmedAt != null`

**Important**: Uses email as fallback for `fullName` if not provided.

### Auth State Changes

```dart
Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange
```

Provides a stream of authentication state changes for reactive UI updates.

---

## Repository Pattern

### AuthRepository Interface

**Location**: `lib/features/auth/domain/repositories/auth_repository.dart`

**Methods**:
```dart
abstract class AuthRepository {
  ResultFuture<User> login(String email, String password);
  ResultFuture<User> signInWithGoogle();
  ResultFuture<User> signInWithApple();
  ResultFuture<User> register(String email, String password, String fullName);
  ResultFuture<User> getCurrentUser();
  ResultFuture<void> logout();
  ResultFuture<bool> isAuthenticated();
  ResultFuture<void> deleteAndLogoutUser();
}
```

**Return Type**: `ResultFuture<T>` = `Future<Either<Failure, T>>`

### SupabaseAuthRepositoryImpl

**Location**: `lib/features/auth/data/repositories/supabase_auth_repository_impl.dart`

**Responsibilities**:
- Network connectivity checks before remote operations
- Error handling and conversion to `Failure` types
- Wrapping service calls in `Either<Failure, Success>` pattern

**Error Handling Pattern**:
```dart
try {
  final user = await supabaseAuthService.signInWithEmail(...);
  return Right(user);
} catch (e) {
  return Left(AuthFailure(message: e.toString()));
}
```

**Network Check Pattern**:
```dart
if (!await networkInfo.isConnected) {
  return const Left(NetworkFailure(message: 'No internet connection'));
}
```

---

## Use Cases

**Location**: `lib/features/auth/domain/usecases/`

Each use case:
- Takes a repository dependency
- Implements a single business operation
- Returns `ResultFuture<T>`

### Example Use Cases

1. **LoginUseCase**
   - Parameters: `LoginParams(email, password)`
   - Calls: `_authRepository.login(email, password)`

2. **LogoutUseCase**
   - No parameters
   - Calls: `_authRepository.logout()`

3. **IsAuthenticatedUseCase**
   - No parameters
   - Calls: `_authRepository.isAuthenticated()`

4. **GoogleSignInUseCase**
   - No parameters
   - Calls: `_authRepository.signInWithGoogle()`

5. **AppleSignInUseCase**
   - No parameters
   - Calls: `_authRepository.signInWithApple()`

6. **DeleteUserUseCase**
   - No parameters
   - Calls: `_authRepository.deleteAndLogoutUser()`

---

## Domain Entities

### User Entity

**Location**: `lib/features/auth/domain/entities/user.dart`

```dart
class User extends Equatable {
  final String userId;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final bool emailVerified;
}
```

**Features**:
- Immutable (using `Equatable`)
- JSON serialization support (`fromJson`, `toJson`)
- `copyWith` method for updates

### UserModel

**Location**: `lib/features/auth/data/models/user_model.dart`

**Purpose**: Data layer model with JSON annotations.

**Mapping**:
- `user_id` ↔ `userId`
- `full_name` ↔ `fullName`
- `avatar_url` ↔ `avatarUrl`

**Methods**:
- `fromEntity(User)` - Convert domain entity to model
- `toEntity()` - Convert model to domain entity
- `fromJson` / `toJson` - JSON serialization

---

## Implementation Steps

### Phase 1: Core Infrastructure

1. **Set up dependencies**
   - Add packages to `pubspec.yaml`
   - Run `flutter pub get`

2. **Initialize Supabase**
   - Create Supabase project
   - Get API keys and URL
   - Initialize in app bootstrap:
     ```dart
     await Supabase.initialize(
       url: 'YOUR_SUPABASE_URL',
       anonKey: 'YOUR_SUPABASE_ANON_KEY',
     );
     ```

3. **Create TokenStorage**
   - Implement `TokenStorage` class
   - Use `FlutterSecureStorage` as backing store
   - Implement chunking logic for large tokens

4. **Create ApiClient**
   - Set up Dio instance
   - Configure base URL from environment
   - Create interceptor classes

5. **Create AuthInterceptor**
   - Implement token injection
   - Implement 401 handling with token refresh

### Phase 2: Authentication Service

6. **Create SupabaseAuthService**
   - Implement email/password methods
   - Implement Google Sign-In
   - Implement Apple Sign-In
   - Implement sign out
   - Implement user retrieval methods
   - Implement user mapping

7. **Configure OAuth Providers**
   - **Google**: Set up in Google Cloud Console
     - Create OAuth 2.0 Client IDs (iOS and Web)
     - Configure redirect URIs
     - Enable Google Sign-In in Supabase dashboard
   - **Apple**: Set up in Apple Developer
     - Enable Sign in with Apple capability
     - Configure service ID
     - Enable Apple Sign-In in Supabase dashboard

### Phase 3: Repository Layer

8. **Create AuthRepository interface**
   - Define all authentication methods
   - Use `ResultFuture<T>` return types

9. **Implement SupabaseAuthRepositoryImpl**
   - Inject `SupabaseAuthService` and `NetworkInfo`
   - Implement all repository methods
   - Add network connectivity checks
   - Convert exceptions to `Failure` types

### Phase 4: Domain Layer

10. **Create User entity**
    - Define properties
    - Add JSON serialization
    - Add `copyWith` method

11. **Create use cases**
    - LoginUseCase
    - LogoutUseCase
    - RegisterUseCase
    - GetCurrentUserUseCase
    - IsAuthenticatedUseCase
    - GoogleSignInUseCase
    - AppleSignInUseCase
    - DeleteUserUseCase

### Phase 5: Dependency Injection

12. **Set up GetIt**
    - Register core dependencies:
      - `FlutterSecureStorage`
      - `TokenStorage`
      - `ApiClient`
      - `NetworkInfo`
    - Register auth dependencies:
      - `SupabaseAuthService`
      - `AuthRepository` (implementation)
      - All use cases

### Phase 6: Presentation Layer (Optional)

13. **Create AuthBloc** (if using BLoC)
    - Events: Login, Logout, CheckAuth, etc.
    - States: Authenticated, Unauthenticated, Loading, Error
    - Inject use cases

14. **Create UI components**
    - Login screen
    - Sign up screen
    - OAuth sign-in buttons

---

## Important Considerations

### 1. Token Management

- **Storage**: Always use secure storage (keychain/keystore)
- **Sync**: Keep Supabase session token and `TokenStorage` in sync
- **Refresh**: Handle token refresh automatically via `AuthInterceptor`
- **Size**: Implement chunking for large tokens (>3500 chars)

### 2. Error Handling

- **Network Errors**: Check connectivity before remote operations
- **Auth Errors**: Convert to `AuthFailure` with descriptive messages
- **OAuth Cancellation**: Handle user cancellation gracefully (don't show error)
- **Token Expiry**: Automatic refresh on 401 responses

### 3. OAuth Configuration

#### Google Sign-In
- **iOS**: Requires `clientId` (iOS Client ID)
- **Web/Backend**: Requires `serverClientId` (Web Client ID)
- **Redirect URIs**: Must match Supabase configuration
- **Scopes**: `['email', 'profile']` minimum

#### Apple Sign-In
- **First Sign-In**: Name only provided on first authentication
- **Subsequent Sign-Ins**: Only email/identity token provided
- **Error Codes**: Handle `AuthorizationErrorCode.canceled` specially
- **Profile Update**: Upsert name to `user_profiles` table on first sign-in

### 4. User Profile Management

- **Name Fallback**: Use email if `fullName` is not available
- **Profile Updates**: Handle via Supabase `user_profiles` table
- **Metadata**: Store additional user data in `userMetadata` or separate table

### 5. Account Deletion

- **Backend Coordination**: Deletion handled by backend API
- **Cleanup**: Sign out from all providers and clear tokens
- **Error Handling**: Ensure cleanup happens even if API call fails

### 6. Security Best Practices

- **Never log tokens**: Avoid logging sensitive authentication data
- **Secure storage**: Always use `FlutterSecureStorage` for tokens
- **HTTPS only**: Ensure all API calls use HTTPS
- **Token validation**: Validate tokens on backend

### 7. Testing Considerations

- **Mock dependencies**: Use `mocktail` for testing
- **Test token storage**: Test chunking, compression, and retrieval
- **Test error scenarios**: Network failures, auth failures, token expiry
- **Test OAuth flows**: Mock OAuth providers for unit tests

### 8. Platform-Specific Setup

#### iOS
- Configure `Info.plist` for OAuth URL schemes
- Enable Sign in with Apple capability
- Configure Google Sign-In in Xcode

#### Android
- Configure `AndroidManifest.xml` for OAuth
- Set up SHA-1 fingerprint for Google Sign-In
- Configure OAuth client IDs

### 9. Environment Configuration

- **API URLs**: Use environment-based configuration
- **Supabase Keys**: Store in secure configuration (not in code)
- **OAuth IDs**: Consider environment-specific OAuth client IDs

### 10. State Management

- **Auth State Stream**: Use `authStateChanges` for reactive updates
- **BLoC Pattern**: Consider using BLoC for complex state management
- **Persistence**: Consider persisting auth state for app restarts

---

## Code Structure

```
lib/
├── core/
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── token_storage.dart
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── error_interceptor.dart
│   │   │   ├── logging_interceptor.dart
│   │   │   └── retry_interceptor.dart
│   │   └── api_endpoints.dart
│   ├── errors/
│   │   └── failures.dart
│   └── injection/
│       └── injection_container.dart
└── features/
    └── auth/
        ├── data/
        │   ├── datasources/
        │   │   └── supabase_auth_service.dart
        │   ├── models/
        │   │   └── user_model.dart
        │   └── repositories/
        │       └── supabase_auth_repository_impl.dart
        ├── domain/
        │   ├── entities/
        │   │   └── user.dart
        │   ├── repositories/
        │   │   └── auth_repository.dart
        │   └── usecases/
        │       ├── login.dart
        │       ├── logout.dart
        │       ├── register.dart
        │       ├── get_current_user.dart
        │       ├── is_authenticated.dart
        │       ├── google_sign_in.dart
        │       ├── apple_sign_in.dart
        │       └── delete_user.dart
        └── presentation/
            └── bloc/
                └── auth_bloc.dart (optional)
```

---

## Summary

This authentication system provides:

✅ **Multiple Auth Methods**: Email/password, Google, Apple  
✅ **Secure Token Storage**: Encrypted storage with size optimization  
✅ **Automatic Token Refresh**: Handles token expiry transparently  
✅ **Clean Architecture**: Separation of concerns, testable  
✅ **Error Handling**: Comprehensive error handling with typed failures  
✅ **OAuth Integration**: Full Google and Apple Sign-In support  
✅ **Account Management**: User registration, deletion, profile updates  

The system is production-ready and follows Flutter/Dart best practices for authentication in mobile applications.

