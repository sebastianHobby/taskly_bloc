part of 'auth_bloc.dart';

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
