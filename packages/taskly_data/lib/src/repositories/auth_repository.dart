import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/telemetry.dart';

import 'package:taskly_data/src/errors/app_failure_mapper.dart';

/// Implementation of authentication repository using Supabase.
class AuthRepository implements AuthRepositoryContract {
  AuthRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Stream<AuthState> watchAuthState() {
    AppLog.routine('data.auth', 'watchAuthState: subscribing to auth changes');
    return _client.auth.onAuthStateChange;
  }

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email, required String password, OperationContext? context,
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
      return response;
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
    required String email, required String password, OperationContext? context,
  }) async {
    AppLog.info('data.auth', 'signUp: email=${AppLog.maskEmail(email)}');
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      AppLog.info('data.auth', 'signUp: success');
      return response;
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
  Future<UserResponse> updatePassword(
    String newPassword, {
    OperationContext? context,
  }) async {
    AppLog.info('data.auth', 'updatePassword');
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      AppLog.info('data.auth', 'updatePassword: success');
      return response;
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
}
