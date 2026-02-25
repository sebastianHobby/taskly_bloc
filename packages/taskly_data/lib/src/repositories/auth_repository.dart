import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:rxdart/rxdart.dart';
import 'package:taskly_core/env.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/auth.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';

import 'package:taskly_data/src/errors/app_failure_mapper.dart';

enum AuthRedirectFlow {
  signUp,
  passwordRecovery,
}

/// Implementation of authentication repository using Supabase.
class AuthRepository implements AuthRepositoryContract {
  AuthRepository({
    required supabase.SupabaseClient client,
    String? Function(AuthRedirectFlow flow)? redirectUrlResolver,
  }) : _client = client,
       _redirectUrlResolver = redirectUrlResolver;

  final supabase.SupabaseClient _client;
  final String? Function(AuthRedirectFlow flow)? _redirectUrlResolver;

  late final Stream<AuthStateChange> _authStateStream = _client
      .auth
      .onAuthStateChange
      .map(_mapAuthState)
      .doOnData(_logAuthStateForProduction)
      // Shared + replay-last so multiple UI listeners can attach safely.
      .shareReplay(maxSize: 1);

  @override
  Stream<AuthStateChange> watchAuthState() {
    AppLog.routine('data.auth', 'watchAuthState: subscribing to auth changes');
    return _authStateStream;
  }

  @override
  AuthSession? get currentSession => _mapSession(_client.auth.currentSession);

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
        emailRedirectTo: _resolveAuthRedirectUrl(
          flow: AuthRedirectFlow.signUp,
        ),
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
      await _client.auth.signOut(scope: supabase.SignOutScope.local);
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
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: _resolveAuthRedirectUrl(
          flow: AuthRedirectFlow.passwordRecovery,
        ),
      );
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
      supabase.AuthChangeEvent.passwordRecovery =>
        AuthEventKind.passwordRecovery,
      _ => AuthEventKind.unknown,
    };
  }

  static AuthSession? _mapSession(supabase.Session? session) {
    if (session == null) return null;
    return AuthSession(
      user: _mapUser(session.user) ?? AuthUser(id: session.user.id),
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

  static UserUpdateResponse _mapUserResponse(supabase.UserResponse response) {
    return UserUpdateResponse(user: _mapUser(response.user));
  }

  void _logAuthStateForProduction(AuthStateChange state) {
    if (!kReleaseMode) return;
    if (state.event != AuthEventKind.tokenRefreshed) return;

    final expiresAt = state.session?.expiresAt?.toUtc().toIso8601String();
    AppLog.info(
      'data.auth',
      'tokenRefreshed event observed (expiresAtUtc=$expiresAt)',
    );
  }

  String _resolveAuthRedirectUrl({required AuthRedirectFlow flow}) {
    final override = _redirectUrlResolver?.call(flow)?.trim();
    if (override != null && override.isNotEmpty) return override;

    if (kIsWeb) return _webRedirectFallback(flow: flow);

    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => _appRedirectFallback(flow: flow),
      TargetPlatform.android => _appRedirectFallback(flow: flow),
      TargetPlatform.macOS => _appRedirectFallback(flow: flow),
      TargetPlatform.fuchsia => _webRedirectFallback(flow: flow),
      TargetPlatform.linux => _webRedirectFallback(flow: flow),
      TargetPlatform.windows => _webRedirectFallback(flow: flow),
    };
  }

  String _webRedirectFallback({required AuthRedirectFlow flow}) {
    try {
      final configured = switch (flow) {
        AuthRedirectFlow.signUp => Env.authSignUpWebRedirectUrl.trim(),
        AuthRedirectFlow.passwordRecovery =>
          Env.authPasswordRecoveryWebRedirectUrl.trim(),
      };
      if (configured.isNotEmpty) return configured;
    } catch (_) {
      // Test/non-configured entrypoints can safely use the default below.
    }
    return 'https://sebastianhobby.github.io/taskly_bloc/auth/callback';
  }

  String _appRedirectFallback({required AuthRedirectFlow flow}) {
    try {
      final configured = switch (flow) {
        AuthRedirectFlow.signUp => Env.authSignUpAppRedirectUrl.trim(),
        AuthRedirectFlow.passwordRecovery =>
          Env.authPasswordRecoveryAppRedirectUrl.trim(),
      };
      if (configured.isNotEmpty) return configured;
    } catch (_) {
      // Test/non-configured entrypoints can safely use the default below.
    }
    return 'taskly://auth-callback';
  }
}
