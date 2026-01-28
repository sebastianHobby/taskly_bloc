import 'package:taskly_domain/auth.dart';
import 'package:taskly_domain/telemetry.dart';

/// Contract for authentication operations.
abstract class AuthRepositoryContract {
  /// Stream of authentication state changes.
  ///
  /// Stream contract:
  /// - broadcast: yes (multiple listeners may attach)
  /// - replay: last (late subscribers should immediately receive current state)
  /// - cold/hot: hot
  Stream<AuthStateChange> watchAuthState();

  /// Get the current session, if any.
  AuthSession? get currentSession;

  /// Get the current user, if any.
  AuthUser? get currentUser;

  /// Sign in with email and password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    OperationContext? context,
  });

  /// Sign up with email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    OperationContext? context,
  });

  /// Sign out the current user.
  Future<void> signOut({OperationContext? context});

  /// Send password reset email.
  Future<void> resetPasswordForEmail(
    String email, {
    OperationContext? context,
  });

  /// Update user password (when already authenticated).
  Future<UserUpdateResponse> updatePassword(
    String newPassword, {
    OperationContext? context,
  });

  /// Update user profile metadata (when already authenticated).
  Future<UserUpdateResponse> updateUserProfile({
    String? displayName,
    OperationContext? context,
  });
}
