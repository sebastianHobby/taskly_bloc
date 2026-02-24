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
    this.pendingEmailConfirmation,
  });

  static const Object _unset = Object();

  final AuthStatus status;
  final AuthUser? user;
  final String? error;
  final String? message;
  final String? pendingEmailConfirmation;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
  bool get isLoading => status == AuthStatus.loading;

  AppAuthState copyWith({
    AuthStatus? status,
    Object? user = _unset,
    Object? error = _unset,
    Object? message = _unset,
    Object? pendingEmailConfirmation = _unset,
  }) {
    return AppAuthState(
      status: status ?? this.status,
      user: identical(user, _unset) ? this.user : user as AuthUser?,
      error: identical(error, _unset) ? this.error : error as String?,
      message: identical(message, _unset) ? this.message : message as String?,
      pendingEmailConfirmation: identical(pendingEmailConfirmation, _unset)
          ? this.pendingEmailConfirmation
          : pendingEmailConfirmation as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    user,
    error,
    message,
    pendingEmailConfirmation,
  ];
}
