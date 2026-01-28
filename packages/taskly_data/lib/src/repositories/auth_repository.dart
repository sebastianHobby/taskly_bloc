import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:rxdart/rxdart.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/auth.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';

import 'package:taskly_data/src/errors/app_failure_mapper.dart';

/// Implementation of authentication repository using Supabase.
class AuthRepository implements AuthRepositoryContract {
  AuthRepository({required supabase.SupabaseClient client}) : _client = client;

  final supabase.SupabaseClient _client;

  late final Stream<AuthStateChange> _authStateStream = _client
      .auth
      .onAuthStateChange
      .map(_mapAuthState)
      // Shared + replay-last so multiple UI listeners can attach safely.
      .shareReplay(maxSize: 1);

  @override
  Stream<AuthStateChange> watchAuthState() {
    AppLog.routine('data.auth', 'watchAuthState: subscribing to auth changes');
    return _authStateStream;
  }

  @override
  AuthSession? get currentSession =>
      _mapSession(_client.auth.currentSession);

  @override
  AuthUser? get currentUser => _mapUser(_client.auth.currentUser);

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
    OperationContext? context,
  }) async {
    AppLog.info(
      'data.auth',
      'signInWithPassword: email=${AppLog.maskEmail(email)}',
    );
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLog.info('data.auth', 'signInWithPassword: success');
      return _mapAuthResponse(response);
    } catch (e, st) {
      final failure = AppFailureMapper.fromException(e);
      AppLog.handleStructured(
        'data.auth',
        'signInWithPassword failed',
        failure,
        st,
        context?.toLogFields() ?? const <String, Object?>{},
      );
      throw failure;
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    OperationContext? context,
  }) async {
    AppLog.info('data.auth', 'signUp: email=${AppLog.maskEmail(email)}');
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      AppLog.info('data.auth', 'signUp: success');
      return _mapAuthResponse(response);
    } catch (e, st) {
      final failure = AppFailureMapper.fromException(e);
      AppLog.handleStructured(
        'data.auth',
        'signUp failed',
        failure,
        st,
        context?.toLogFields() ?? const <String, Object?>{},
      );
      throw failure;
    }
  }

  @override
  Future<void> signOut({OperationContext? context}) async {
    AppLog.info('data.auth', 'signOut');
    try {
      await _client.auth.signOut();
      AppLog.info('data.auth', 'signOut: success');
    } catch (e, st) {
      final failure = AppFailureMapper.fromException(e);
      AppLog.handleStructured(
        'data.auth',
        'signOut failed',
        failure,
        st,
        context?.toLogFields() ?? const <String, Object?>{},
      );
      throw failure;
    }
  }

  @override
  Future<void> resetPasswordForEmail(
    String email, {
    OperationContext? context,
  }) async {
    AppLog.info(
      'data.auth',
      'resetPasswordForEmail: email=${AppLog.maskEmail(email)}',
    );
    try {
      await _client.auth.resetPasswordForEmail(email);
      AppLog.info('data.auth', 'resetPasswordForEmail: success');
    } catch (e, st) {
      final failure = AppFailureMapper.fromException(e);
      AppLog.handleStructured(
        'data.auth',
        'resetPasswordForEmail failed',
        failure,
        st,
        context?.toLogFields() ?? const <String, Object?>{},
      );
      throw failure;
    }
  }

  @override
  Future<UserUpdateResponse> updatePassword(
    String newPassword, {
    OperationContext? context,
  }) async {
    AppLog.info('data.auth', 'updatePassword');
    try {
      final response = await _client.auth.updateUser(
        supabase.UserAttributes(password: newPassword),
      );
      AppLog.info('data.auth', 'updatePassword: success');
      return _mapUserResponse(response);
    } catch (e, st) {
      final failure = AppFailureMapper.fromException(e);
      AppLog.handleStructured(
        'data.auth',
        'updatePassword failed',
        failure,
        st,
        context?.toLogFields() ?? const <String, Object?>{},
      );
      throw failure;
    }
  }

  @override
  Future<UserUpdateResponse> updateUserProfile({
    String? displayName,
    OperationContext? context,
  }) async {
    AppLog.info('data.auth', 'updateUserProfile');
    try {
      final response = await _client.auth.updateUser(
        supabase.UserAttributes(
          data: <String, Object?>{
            ...?displayName == null
                ? null
                : <String, Object?>{'display_name': displayName},
          },
        ),
      );
      AppLog.info('data.auth', 'updateUserProfile: success');
      return _mapUserResponse(response);
    } catch (e, st) {
      final failure = AppFailureMapper.fromException(e);
      AppLog.handleStructured(
        'data.auth',
        'updateUserProfile failed',
        failure,
        st,
        context?.toLogFields() ?? const <String, Object?>{},
      );
      throw failure;
    }
  }

  static AuthStateChange _mapAuthState(supabase.AuthState state) {
    return AuthStateChange(
      event: _mapAuthEvent(state.event),
      session: _mapSession(state.session),
    );
  }

  static AuthEventKind _mapAuthEvent(supabase.AuthChangeEvent event) {
    return switch (event) {
      supabase.AuthChangeEvent.initialSession => AuthEventKind.initialSession,
      supabase.AuthChangeEvent.signedIn => AuthEventKind.signedIn,
      supabase.AuthChangeEvent.signedOut => AuthEventKind.signedOut,
      supabase.AuthChangeEvent.tokenRefreshed => AuthEventKind.tokenRefreshed,
      supabase.AuthChangeEvent.userUpdated => AuthEventKind.userUpdated,
      supabase.AuthChangeEvent.passwordRecovery => AuthEventKind.passwordRecovery,
      _ => AuthEventKind.unknown,
    };
  }

  static AuthSession? _mapSession(supabase.Session? session) {
    if (session == null) return null;
    return AuthSession(
      user: _mapUser(session.user) ?? AuthUser(id: session.user.id),
      accessToken: session.accessToken,
      refreshToken: session.refreshToken,
      expiresAt: session.expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              session.expiresAt! * 1000,
              isUtc: true,
            ),
    );
  }

  static AuthUser? _mapUser(supabase.User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.id,
      email: user.email,
      metadata: user.userMetadata,
    );
  }

  static AuthResponse _mapAuthResponse(supabase.AuthResponse response) {
    return AuthResponse(
      session: _mapSession(response.session),
      user: _mapUser(response.user),
    );
  }

  static UserUpdateResponse _mapUserResponse(
    supabase.UserResponse response,
  ) {
    return UserUpdateResponse(
      user: _mapUser(response.user),
    );
  }
}
