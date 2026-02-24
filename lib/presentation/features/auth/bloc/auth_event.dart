part of 'auth_bloc.dart';

/// Events for authentication state management
sealed class AuthEvent {
  const AuthEvent();
}

/// Event to start listening to auth state changes.
class AuthSubscriptionRequested extends AuthEvent {
  const AuthSubscriptionRequested();
}

/// Event to sign in with email and password.
class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

/// Event to sign up with email and password.
class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

/// Event to sign out the current user.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to request a password reset email.
class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;
}

/// Event fired when an auth callback indicates recovery flow.
class AuthPasswordRecoveryDetected extends AuthEvent {
  const AuthPasswordRecoveryDetected();
}

/// Event to set a new password from recovery flow.
class AuthPasswordUpdateRequested extends AuthEvent {
  const AuthPasswordUpdateRequested({required this.newPassword});

  final String newPassword;
}
