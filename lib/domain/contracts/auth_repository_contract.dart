import 'package:supabase_flutter/supabase_flutter.dart';

/// Contract for authentication operations.
abstract class AuthRepositoryContract {
  /// Stream of authentication state changes.
  Stream<AuthState> watchAuthState();

  /// Get the current session, if any.
  Session? get currentSession;

  /// Get the current user, if any.
  User? get currentUser;

  /// Sign in with email and password.
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Send password reset email.
  Future<void> resetPasswordForEmail(String email);

  /// Update user password (when already authenticated).
  Future<UserResponse> updatePassword(String newPassword);
}
