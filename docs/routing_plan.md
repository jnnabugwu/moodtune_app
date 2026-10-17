# Routing System Implementation Plan

This document outlines the complete routing system architecture for a Flutter mobile application using `go_router`, designed with authentication-aware navigation, type-safe route constants, and clean separation of concerns.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Dependencies](#dependencies)
3. [Core Components](#core-components)
4. [Route Configuration](#route-configuration)
5. [Navigation Patterns](#navigation-patterns)
6. [Authentication-Aware Routing](#authentication-aware-routing)
7. [Route Parameters and Data Passing](#route-parameters-and-data-passing)
8. [Error Handling](#error-handling)
9. [Implementation Steps](#implementation-steps)
10. [Best Practices](#best-practices)

---

## Architecture Overview

The routing system uses **go_router** for declarative, type-safe navigation with the following architecture:

```
┌─────────────────────────────────────┐
│      MaterialApp.router              │
│  (Uses AppRouter.router)            │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         AppRouter                   │
│  (Route definitions & redirects)    │
│  refreshListenable: auth stream     │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      StatefulShellRoute             │
│  (Tab shell — Home + History)       │
│  Each branch: independent navigator │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        RouteNames                   │
│  (Type-safe route constants)        │
└─────────────────────────────────────┘
```

### Key Principles

- **Centralized Route Management**: All routes defined in one place
- **Type-Safe Navigation**: Route constants prevent typos and errors
- **Authentication-Aware**: Automatic redirects based on auth state
- **BLoC Integration**: Seamless provider injection for state management
- **Error Handling**: Global error page for route failures

---

## Dependencies

### Required Package

Add to your `pubspec.yaml`:

```yaml
dependencies:
  go_router: ^12.1.3  # Declarative routing for Flutter
```

**Note**: `go_router` is built on top of Flutter's Navigator 2.0 and provides a simpler, more declarative API.

---

## Core Components

### 1. RouteNames

**Purpose**: Centralized route name constants for type-safe navigation.

**Location**: `lib/core/routing/route_names.dart`

**Key Features**:

- Private constructor prevents instantiation
- Static constants for all routes
- Helper methods for parameterized routes
- Organized by feature/domain

**Structure**:

```dart
class RouteNames {
  RouteNames._(); // Private constructor
  
  // Root
  static const String initial = '/';
  
  // Auth routes
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  
  // Feature routes
  static const String waitTimes = '/wait-times';
  static const String waitTimeDetails = '/wait-times/:id';
  
  // Helper methods
  static String waitTimeDetailsRoute(String id) {
    return waitTimeDetails.replaceAll(':id', id);
  }
}
```

**Benefits**:

- Prevents typos in route strings
- Easy refactoring (change once, updates everywhere)
- IDE autocomplete support
- Self-documenting code

### 2. AppRouter

**Purpose**: Main router configuration with route definitions, redirects, and error handling.

**Location**: `lib/core/routing/app_router.dart`

**Key Features**:

- Single `GoRouter` instance
- Route definitions with builders
- Authentication-based redirects
- Error page configuration
- BLoC provider integration

**Structure**:

```dart
class AppRouter {
  // Route constants (can use RouteNames or define here)
  static const String initial = '/';
  static const String login = '/login';
  
  static final GoRouter router = GoRouter(
    initialLocation: initial,
    debugLogDiagnostics: true,
    routes: [...],
    redirect: (context, state) => {...},
    errorBuilder: (context, state) => ErrorPage(...),
  );
}
```

### 3. DialogUtils

**Purpose**: Utility functions for showing dialogs, snackbars, and bottom sheets.

**Location**: `lib/core/routing/dialog_utils.dart`

**Key Features**:

- Confirmation dialogs
- Info dialogs
- Bottom sheets
- Snackbars (success, error, info)
- Consistent styling

**Methods**:

```dart
class DialogUtils {
  DialogUtils._();
  
  static Future<bool> showConfirmDialog(...)
  static Future<void> showInfoDialog(...)
  static Future<T?> showAppBottomSheet<T>(...)
  static void showSnackBar(...)
  static void showError(...)
  static void showSuccess(...)
}
```

---

## Route Configuration

### Basic Route Definition

```dart
GoRoute(
  path: '/login',
  builder: (context, state) => const LoginPage(),
)
```

### Route with Path Parameters

```dart
GoRoute(
  path: '/wait-times/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return WaitTimeDetailsPage(id: id);
  },
)
```

**Parameter Syntax**:

- `:id` - Required path parameter
- `:id?` - Optional path parameter (not commonly used)

**Accessing Parameters**:

```dart
final id = state.pathParameters['id']!;  // Required
final id = state.pathParameters['id'];   // Optional (nullable)
```

### Route with Extra Data

```dart
GoRoute(
  path: '/flight-details',
  builder: (context, state) {
    final flightNumber = state.extra as String? ?? '';
    return FlightDetailsPage(flightNumber: flightNumber);
  },
)
```

**Passing Extra Data**:

```dart
context.push('/flight-details', extra: flightNumber);
context.push('/flight-list', extra: flightNumbers);
```

**Type Safety Note**: `state.extra` is `dynamic`, so cast appropriately:

- `state.extra as String`
- `state.extra as List<String>`
- `state.extra as MyCustomObject`

### Route with BLoC Provider

```dart
GoRoute(
  path: '/wait-times',
  builder: (context, state) => BlocProvider.value(
    value: sl<TsaWaitTimesBloc>(),
    child: const WaitTimesPage(),
  ),
)
```

**Pattern**: Use `BlocProvider.value` with service locator (`sl`) to inject existing BLoC instances.

**Why `BlocProvider.value`?**

- Reuses existing BLoC instances from service locator
- Avoids creating new instances on every navigation
- Maintains state across navigation

### StatefulShellRoute (Tab Navigation)

Use `StatefulShellRoute.indexedStack` for bottom tab bars. Each branch gets an independent navigator, so tabs preserve their own back stack and scroll position when switching.

**When to use:**

- `StatefulShellRoute` — tabs that need to preserve scroll state and back stack (use this)
- `ShellRoute` — tabs with shared, stateless content (rare)

**Implementation:**

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) {
    return ScaffoldWithNavBar(navigationShell: navigationShell);
  },
  branches: [
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomePage(),
        ),
      ],
    ),
    StatefulShellBranch(
      routes: [
        GoRoute(
          path: '/history',
          builder: (context, state) => const HistoryPage(),
        ),
      ],
    ),
  ],
)
```

**ScaffoldWithNavBar shell widget:**

```dart
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          // Re-tapping active tab resets to initial location
          initialLocation: index == navigationShell.currentIndex,
        ),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}
```

**Key rules:**

- Tab switches always use `navigationShell.goBranch()` — never `context.push()`
- `initialLocation: true` on re-tap resets the branch back stack (standard tab UX)
- Each branch maintains its own independent navigator state

---

### Nested Routes (Sub-routes)

```dart
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsPage(),
  routes: [
    GoRoute(
      path: 'notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(
      path: 'privacy',
      builder: (context, state) => const PrivacyPage(),
    ),
  ],
)
```

**Note**: Sub-route paths are relative (no leading `/`). Full paths become:

- `/settings/notifications`
- `/settings/privacy`

### Route Groups

Organize routes by feature:

```dart
routes: [
  // Authentication routes
  GoRoute(path: '/onboarding', ...),
  GoRoute(path: '/login', ...),
  GoRoute(path: '/signup', ...),
  
  // Main app routes
  GoRoute(path: '/main', ...),
  
  // Feature routes
  GoRoute(path: '/wait-times', ...),
  GoRoute(path: '/flight-search', ...),
]
```

---

## Navigation Patterns

### 1. Push Navigation (Stack-based)

**Use Case**: Navigate to a new screen, keeping previous screen in stack.

```dart
// Navigate to new screen
context.push('/wait-times/details');

// Navigate with extra data
context.push('/flight-details', extra: flightNumber);

// Navigate with path parameters
context.push(RouteNames.waitTimeDetailsRoute(id));
```

**Behavior**: User can go back using back button or `context.pop()`.

### 2. Go Navigation (Replace)

**Use Case**: Replace current route (no back navigation).

```dart
// Replace current route
context.go('/main');

// Navigate to root and clear stack
context.go('/');
```

**Behavior**: Previous route is removed from stack. Used for:

- Login/logout flows
- Main navigation entry points
- Authentication state changes

### 3. Pop Navigation

**Use Case**: Return to previous screen.

```dart
// Simple pop
context.pop();

// Pop with result
context.pop(true);  // Returns true to previous screen
context.pop(data);  // Returns data to previous screen
```

**Receiving Results**:

```dart
final result = await context.push('/some-route');
if (result == true) {
  // Handle result
}
```

### 4. Push Replacement

**Use Case**: Replace current route but allow back navigation to route before current.

```dart
context.pushReplacement('/new-route');
```

**Behavior**: Current route replaced, but can go back to route before it.

### 5. Clear Stack Navigation

**Use Case**: Navigate to a new route and clear all previous routes (e.g. after login, clear the auth stack).

`pushAndRemoveUntil` is a Navigator 1.0 API — it does not exist in go_router. Use `context.go()` instead, which replaces the entire stack:

```dart
// After login — go to home and clear auth stack
context.go(RouteNames.home);

// After logout — go to onboarding and clear app stack
context.go(RouteNames.onboarding);
```

`context.go()` is the correct go_router equivalent. The router rebuilds from the new location with no prior history.

---

## Authentication-Aware Routing

### refreshListenable — Reactive Auth

Rather than imperatively calling `AppRouter.router.go()` inside a stream listener, use `refreshListenable` to wire the auth stream directly to the router. When auth state changes, the router automatically re-runs the redirect callback without any manual imperative navigation calls.

**Step 1 — Create a Listenable wrapper around the Supabase auth stream:**

```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
```

**Step 2 — Pass it to GoRouter:**

```dart
GoRouter(
  refreshListenable: GoRouterRefreshStream(
    sl<SupabaseAuthService>().authStateChanges,
  ),
  redirect: (context, state) { ... },  // See below — runs automatically on auth change
)
```

Do **not** use a stream listener to call `AppRouter.router.go()` manually — that becomes redundant and can cause double-navigation bugs.

---

### Redirect Logic

**Purpose**: Guard all protected routes. The redirect callback runs on every navigation event and on every `refreshListenable` notification (i.e. every auth state change).

**Implementation**:

```dart
GoRouter(
  refreshListenable: GoRouterRefreshStream(
    sl<SupabaseAuthService>().authStateChanges,
  ),
  redirect: (context, state) {
    final authService = sl<SupabaseAuthService>();
    final isAuthenticated = authService.isAuthenticated();
    final location = state.matchedLocation;

    // Routes accessible without authentication
    final publicRoutes = [
      RouteNames.onboarding,
      RouteNames.login,
      RouteNames.signup,
    ];
    final isPublicRoute = publicRoutes.contains(location);

    // Unauthenticated user trying to access a protected route → send to onboarding
    if (!isAuthenticated && !isPublicRoute) {
      return RouteNames.onboarding;
    }

    // Authenticated user on a public/auth route → send to home
    if (isAuthenticated && isPublicRoute) {
      return RouteNames.home;
    }

    // No redirect needed
    return null;
  },
)
```

**Redirect rules:**

- Return a `String` (route path) to redirect
- Return `null` to allow navigation
- Guard **all** protected routes, not just `/` — deep links bypass root
- Prevent redirect loops by checking both directions (unauthed on protected, authed on public)

### Protected Routes

For routes that require auth, the global redirect above handles the guard. Route-level redirects are for more granular cases (e.g. role-based access):

```dart
GoRoute(
  path: '/admin',
  builder: (context, state) => const AdminPage(),
  redirect: (context, state) {
    final user = sl<SupabaseAuthService>().currentUser;
    if (user?.role != 'admin') return RouteNames.home;
    return null;
  },
)
```

### Auth State Changes

Auth state changes are now handled automatically via `refreshListenable` — no manual stream listener needed. Remove any imperative calls like:

```dart
// ❌ Remove this pattern — handled by refreshListenable now
supabaseAuthService.authStateChanges.listen((authState) {
  if (authState.event == AuthChangeEvent.signedOut) {
    AppRouter.router.go('/login');
  }
});
```

The router re-runs `redirect` automatically when the auth stream emits — it will route the user correctly without any manual intervention.

---

## Route Parameters and Data Passing

### Path Parameters

**Definition**:

```dart
GoRoute(
  path: '/wait-times/:id',
  builder: (context, state) {
    final id = state.pathParameters['id']!;
    return WaitTimeDetailsPage(id: id);
  },
)
```

**Navigation**:

```dart
// Using RouteNames helper
context.push(RouteNames.waitTimeDetailsRoute(id));

// Direct path replacement
context.push('/wait-times/$id');
```

**Multiple Parameters**:

```dart
GoRoute(
  path: '/users/:userId/posts/:postId',
  builder: (context, state) {
    final userId = state.pathParameters['userId']!;
    final postId = state.pathParameters['postId']!;
    return PostDetailsPage(userId: userId, postId: postId);
  },
)
```

### Query Parameters

**Accessing**:

```dart
GoRoute(
  path: '/search',
  builder: (context, state) {
    final query = state.uri.queryParameters['q'] ?? '';
    final category = state.uri.queryParameters['category'] ?? '';
    return SearchPage(query: query, category: category);
  },
)
```

**Navigation**:

```dart
context.push('/search?q=flutter&category=mobile');
// Or
context.push(
  Uri(path: '/search', queryParameters: {'q': 'flutter', 'category': 'mobile'}).toString(),
);
```

### Extra Data (Complex Objects)

**Definition**:

```dart
GoRoute(
  path: '/flight-list',
  builder: (context, state) {
    final flightNumbers = state.extra as List<String>? ?? [];
    return FlightListPage(flightNumbers: flightNumbers);
  },
)
```

**Navigation**:

```dart
context.push('/flight-list', extra: flightNumbers);
```

**Custom Objects**:

```dart
// Define data class
class FlightSearchParams {
  final List<String> flightNumbers;
  final DateTime date;
  
  FlightSearchParams({required this.flightNumbers, required this.date});
}

// Route
GoRoute(
  path: '/flight-list',
  builder: (context, state) {
    final params = state.extra as FlightSearchParams?;
    return FlightListPage(params: params);
  },
)

// Navigation
context.push('/flight-list', extra: FlightSearchParams(
  flightNumbers: ['AA123', 'UA456'],
  date: DateTime.now(),
));
```

**Best Practice**: For complex data, prefer path/query parameters or a shared state management solution (BLoC, Provider) over `extra`.

---

## Error Handling

### Error Builder

**Global Error Handler**:

```dart
GoRouter(
  errorBuilder: (context, state) => ErrorPage(error: state.error),
)
```

**ErrorPage Implementation**:

```dart
class ErrorPage extends StatelessWidget {
  final Exception? error;
  
  const ErrorPage({super.key, this.error});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${error?.toString() ?? 'Unknown error'}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### Route Not Found (404)

**Handling**:

```dart
GoRouter(
  routes: [
    // ... all routes
  ],
  errorBuilder: (context, state) {
    // Check if route not found
    if (state.error is Exception) {
      return NotFoundPage();
    }
    return ErrorPage(error: state.error);
  },
)
```

**Custom 404 Route**:

```dart
GoRoute(
  path: '/404',
  builder: (context, state) => const NotFoundPage(),
)
```

---

## Implementation Steps

### Phase 1: Setup

1. **Add dependency**

   ```yaml
   dependencies:
     go_router: ^12.1.3
   ```

   Run `flutter pub get`

2. **Create routing directory structure**

   ```
   lib/core/routing/
   ├── app_router.dart
   ├── route_names.dart
   ├── dialog_utils.dart
   └── routing.dart (exports)
   ```

### Phase 2: Route Constants

1. **Create RouteNames class**
   - Define all route constants
   - Add helper methods for parameterized routes
   - Organize by feature

2. **Create DialogUtils class**
   - Implement dialog helpers
   - Implement snackbar helpers
   - Implement bottom sheet helpers

### Phase 3: Router Configuration

1. **Create AppRouter class**
   - Define route constants (or use RouteNames)
   - Create GoRouter instance
   - Add basic routes (start with auth routes)

2. **Configure initial route**
   - Set `initialLocation`
   - Add redirect logic for root route

3. **Add authentication routes**
   - Onboarding
   - Login
   - Signup
   - Email signup
   - Loading

4. **Add main app routes**
   - Main navigation
   - Home/Dashboard
   - Profile
   - Settings

### Phase 4: Feature Routes

1. **Add feature-specific routes**
   - Wait times routes
   - Flight times routes
   - Other feature routes

2. **Add route parameters**
    - Path parameters (e.g., `:id`)
    - Extra data passing
    - Query parameters (if needed)

3. **Integrate BLoC providers**
    - Add `BlocProvider.value` where needed
    - Use service locator for BLoC instances

### Phase 5: Navigation Integration

1. **Update MaterialApp**

    ```dart
    MaterialApp.router(
      routerConfig: AppRouter.router,
      // ... other config
    )
    ```

2. **Replace Navigator calls**
    - Replace `Navigator.push` with `context.push`
    - Replace `Navigator.pop` with `context.pop`
    - Replace `Navigator.pushReplacement` with `context.go`

3. **Add authentication redirects**
    - Implement redirect logic
    - Handle auth state changes
    - Protect routes that require authentication

### Phase 6: Error Handling

1. **Add error builder**
    - Create ErrorPage widget
    - Configure errorBuilder in GoRouter
    - Handle different error types

2. **Add 404 handling**
    - Create NotFoundPage
    - Handle unknown routes

### Phase 7: Advanced Features

1. **Add nested routes** (if needed)
    - Settings sub-routes
    - Profile sub-routes

2. **Add deep linking support** (if needed)
    - Configure app links
    - Handle deep link routes

3. **Add route guards** (if needed)
    - Create AuthGuard widget
    - Protect sensitive routes

---

## Best Practices

### 1. Route Naming

✅ **DO**:

- Use descriptive, consistent paths
- Use kebab-case for multi-word routes (`/wait-times`, `/flight-search`)
- Group related routes together
- Use RouteNames constants

❌ **DON'T**:

- Use hardcoded strings in navigation calls
- Mix naming conventions
- Create deeply nested paths unnecessarily

### 2. Navigation Methods

✅ **Use `context.push`** for:

- Detail pages
- Forms
- Modals
- Any screen user should be able to go back from

✅ **Use `context.go`** for:

- Main navigation (tabs)
- Login/logout flows
- Root-level navigation
- When you want to clear navigation stack

### 3. Data Passing

✅ **Path Parameters** for:

- IDs, slugs, simple identifiers
- Data that should be in URL
- Shareable/deep-linkable data

✅ **Extra Data** for:

- Complex objects
- Temporary navigation data
- Data that shouldn't be in URL

✅ **Query Parameters** for:

- Search queries
- Filters
- Optional parameters

### 4. BLoC Integration

✅ **DO**:

- Use `BlocProvider.value` with service locator
- Reuse existing BLoC instances
- Provide BLoC at route level when needed

❌ **DON'T**:

- Create new BLoC instances in route builders
- Provide BLoC unnecessarily (only when route needs it)

### 5. Error Handling

✅ **DO**:

- Provide global error builder
- Show user-friendly error messages
- Provide navigation options from error page
- Log errors for debugging

### 6. Authentication

✅ **DO**:

- Use `refreshListenable` to wire auth stream to the router — let redirect handle navigation automatically
- Guard **all** protected routes in the redirect callback, not just `/`
- Check both directions in redirect: unauthed on protected routes, and authed on public routes
- Use `context.go()` to clear the stack after login/logout — not `pushAndRemoveUntil`

❌ **DON'T**:

- Manually call `AppRouter.router.go()` inside auth stream listeners — redundant with `refreshListenable`
- Only guard the root route — deep links bypass it
- Use `pushAndRemoveUntil` — it's Navigator 1.0 and doesn't exist in go_router

### 7. Code Organization

✅ **DO**:

- Keep all routes in AppRouter
- Use RouteNames for constants
- Group routes by feature
- Add comments for route groups

### 8. Testing

✅ **Test**:

- Route navigation
- Parameter passing
- Redirect logic
- Error handling
- Authentication guards

---

## Code Structure

```
lib/
├── core/
│   └── routing/
│       ├── app_router.dart          # Main router configuration
│       ├── route_names.dart         # Route constants
│       ├── dialog_utils.dart        # Dialog/snackbar utilities
│       └── routing.dart             # Exports
├── app/
│   └── view/
│       └── app.dart                 # MaterialApp.router setup
└── features/
    ├── auth/
    │   └── presentation/
    │       └── pages/
    │           ├── login_page.dart
    │           ├── signup_page.dart
    │           └── onboarding_page.dart
    └── common/
        └── pages/
            ├── main_navigation_page.dart
            └── error_page.dart
```

---

## Example: Complete Route Setup

### route_names.dart

```dart
class RouteNames {
  RouteNames._();
  
  static const String initial = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String mainNavigation = '/main';
  static const String waitTimes = '/wait-times';
  static const String waitTimeDetails = '/wait-times/:id';
  
  static String waitTimeDetailsRoute(String id) {
    return waitTimeDetails.replaceAll(':id', id);
  }
}
```

### app_router.dart

```dart
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.onboarding,
    debugLogDiagnostics: true,

    // Automatically re-runs redirect whenever auth state changes
    refreshListenable: GoRouterRefreshStream(
      sl<SupabaseAuthService>().authStateChanges,
    ),

    redirect: (context, state) {
      final isAuthenticated = sl<SupabaseAuthService>().isAuthenticated();
      final location = state.matchedLocation;

      const publicRoutes = [
        RouteNames.onboarding,
        RouteNames.login,
        RouteNames.signup,
      ];
      final isPublicRoute = publicRoutes.contains(location);

      // Unauthenticated → block protected routes
      if (!isAuthenticated && !isPublicRoute) return RouteNames.onboarding;

      // Authenticated → skip auth screens
      if (isAuthenticated && isPublicRoute) return RouteNames.home;

      return null;
    },

    errorBuilder: (context, state) => ErrorPage(error: state.error),

    routes: [
      // Auth routes (public)
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (context, state) => const SignupPage(),
      ),

      // Authenticated shell — Home + History tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.history,
                builder: (context, state) => const HistoryPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
```

### app.dart

```dart
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'My App',
      routerConfig: AppRouter.router,
    );
  }
}
```

### Navigation Usage

```dart
// Push to detail page
context.push(RouteNames.waitTimeDetailsRoute(id));

// Go to main navigation
context.go(RouteNames.mainNavigation);

// Pop current route
context.pop();
```

---

## Summary

This routing system provides:

✅ **Type-Safe Navigation**: Route constants prevent errors  
✅ **Authentication-Aware**: Automatic redirects based on auth state  
✅ **BLoC Integration**: Seamless state management integration  
✅ **Error Handling**: Global error page for route failures  
✅ **Flexible Data Passing**: Path params, query params, and extra data  
✅ **Clean Architecture**: Centralized route management  
✅ **Developer Experience**: Easy to use, maintain, and test  

The system is production-ready and follows Flutter/Dart best practices for navigation in mobile applications.
