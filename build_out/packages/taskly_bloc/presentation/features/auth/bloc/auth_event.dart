part of 'auth_bloc.dart';

// Note: AuthState here refers to Supabase's AuthState from supabase_flutter

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
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

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign up with email and password.
class AuthSignUpRequested extends AuthEvent {
  const AuthSignUpRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// Event to sign out the current user.
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

/// Event to request a password reset email.
class AuthPasswordResetRequested extends AuthEvent {
  const AuthPasswordResetRequested({required this.email});

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Internal event when auth state changes from the repository stream.
class _AuthStateChanged extends AuthEvent {
  const _AuthStateChanged(this.authState);

  final AuthState authState;

  @override
  List<Object?> get props => [authState];
}
