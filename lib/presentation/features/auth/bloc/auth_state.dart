part of 'auth_bloc.dart';

/// Authentication status for the application.
///
/// The flow is:
/// 1. [initial] - App just started, checking for existing session
/// 2. [loading] - Auth operation in progress (sign in/up/out)
/// 3. [authenticated] - User is authenticated and ready
/// 4. [unauthenticated] - No valid session
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AppAuthState extends Equatable {
  const AppAuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.error,
    this.message,
  });

  final AuthStatus status;
  final User? user;
  final String? error;
  final String? message;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;

  AppAuthState copyWith({
    AuthStatus? status,
    User? user,
    String? error,
    String? message,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      error: error,
      message: message,
    );
  }

  @override
  List<Object?> get props => [status, user, error, message];
}
