/// Domain-facing authentication event kinds.
enum AuthEventKind {
  initialSession,
  signedIn,
  signedOut,
  tokenRefreshed,
  userUpdated,
  passwordRecovery,
  unknown,
}

/// Minimal user model for auth flows.
class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.metadata,
  });

  final String id;
  final String? email;
  final Map<String, Object?>? metadata;
}

/// Minimal session model for auth flows.
class AuthSession {
  const AuthSession({
    required this.user,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final AuthUser user;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
}

/// Auth state change emitted by the auth repository.
class AuthStateChange {
  const AuthStateChange({
    required this.event,
    this.session,
  });

  final AuthEventKind event;
  final AuthSession? session;
}

/// Auth response for sign-in/up flows.
class AuthResponse {
  const AuthResponse({
    this.session,
    this.user,
  });

  final AuthSession? session;
  final AuthUser? user;
}

/// Response for user update operations.
class UserUpdateResponse {
  const UserUpdateResponse({this.user});

  final AuthUser? user;
}
