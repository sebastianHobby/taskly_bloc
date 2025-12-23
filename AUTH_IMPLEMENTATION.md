# Authentication Implementation

This document describes the authentication feature implementation using Supabase Auth UI.

## Architecture

The authentication feature follows the project's clean architecture pattern:

### Domain Layer
- **Contract**: `lib/domain/contracts/auth_repository_contract.dart`
  - Defines authentication operations: sign in, sign up, sign out, password reset
  - Provides stream of authentication state changes
  - Exposes current session and user

### Data Layer
- **Repository**: `lib/data/repositories/auth_repository.dart`
  - Implements `AuthRepositoryContract` using Supabase client
  - Wraps Supabase authentication methods

### Presentation Layer
- **BLoC**: `lib/features/auth/bloc/auth_bloc.dart`
  - Manages authentication state (`AppAuthState`)
  - Handles authentication events (sign in, sign up, sign out, password reset)
  - Subscribes to repository's auth state stream
  - **Note**: Uses `AppAuthState` to avoid naming conflict with Supabase's `AuthState`

- **Views**: `lib/features/auth/view/`
  - `sign_in_view.dart`: Sign in page using SupaEmailAuth widget
  - `sign_up_view.dart`: Sign up page using SupaEmailAuth widget
  - `forgot_password_view.dart`: Password reset page using SupaResetPassword widget

## Routing & Protection

The router (`lib/routing/router.dart`) implements authentication guards:

### Redirect Logic
- **Unauthenticated users**: Redirected to `/sign-in` when accessing protected routes
- **Authenticated users accessing auth routes**: Redirected to `/inbox` (since they're already signed in)
- **Authenticated users accessing protected routes**: No redirect - access granted ✅
- **Auth routes** (unprotected): `/sign-in`, `/sign-up`, `/forgot-password`
- **Protected routes**: All other application routes

### Implementation Details
- Uses `GoRouter.redirect` callback to check authentication state
- Reads auth state from `AuthRepositoryContract` on each navigation
- Provides separate `AuthBloc` instances for each auth view

## Dependency Injection

The authentication components are registered in `lib/core/dependency_injection/dependency_injection.dart`:

```dart
getIt
  ..registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  )
  ..registerLazySingleton<AuthRepositoryContract>(
    () => AuthRepository(client: getIt<SupabaseClient>()),
  );
```

## Features

### Sign In
- Email and password authentication
- Automatic navigation to home on success
- Error messages displayed via SnackBar
- Link to sign up and forgot password pages

### Sign Up
- Email and password registration
- Email confirmation flow supported
- Success message after account creation
- Automatic navigation to home after sign in
- Link back to sign in page

### Forgot Password
- Password reset email request
- Success confirmation message
- Automatic navigation back to sign in after 2 seconds
- Link back to sign in page

## State Management

### AuthStatus Enum
- `initial`: Initial state before auth check
- `loading`: During authentication operations
- `authenticated`: User is signed in
- `unauthenticated`: User is signed out

### AppAuthState Properties
- `status`: Current authentication status
- `user`: Current Supabase user (null if unauthenticated)
- `error`: Error message from failed operations
- `message`: Success or informational messages

### Convenience Getters
- `isAuthenticated`: Returns true if status is authenticated
- `isUnauthenticated`: Returns true if status is unauthenticated
- `isLoading`: Returns true if status is loading

## UI Components

All auth views use Supabase Auth UI widgets:
- `SupaEmailAuth`: Email/password authentication form
- `SupaResetPassword`: Password reset form

Views are styled consistently with:
- Centered layout with max width constraint (400px)
- Icon and heading at top
- Form in the middle
- Navigation links at bottom
- Material 3 theming support

## Testing Considerations

When testing authentication:
1. Mock the `AuthRepositoryContract` in tests
2. Use `bloc_test` package to test `AuthBloc` events and states
3. Widget tests should provide mock `AuthBloc` instances
4. Integration tests can use Supabase's test client

## Future Enhancements

Potential improvements:
- OAuth providers (Google, GitHub, etc.)
- Biometric authentication
- Multi-factor authentication (MFA)
- Account email verification flow
- Password strength indicator
- Remember me functionality
- Session management and refresh
