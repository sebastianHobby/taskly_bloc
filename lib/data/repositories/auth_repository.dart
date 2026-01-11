import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/core/logging/app_log.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';

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
    required String email,
    required String password,
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
      AppLog.handle('data.auth', 'signInWithPassword failed', e, st);
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
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
      AppLog.handle('data.auth', 'signUp failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    AppLog.info('data.auth', 'signOut');
    try {
      await _client.auth.signOut();
      AppLog.info('data.auth', 'signOut: success');
    } catch (e, st) {
      AppLog.handle('data.auth', 'signOut failed', e, st);
      rethrow;
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    AppLog.info(
      'data.auth',
      'resetPasswordForEmail: email=${AppLog.maskEmail(email)}',
    );
    try {
      await _client.auth.resetPasswordForEmail(email);
      AppLog.info('data.auth', 'resetPasswordForEmail: success');
    } catch (e, st) {
      AppLog.handle('data.auth', 'resetPasswordForEmail failed', e, st);
      rethrow;
    }
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    AppLog.info('data.auth', 'updatePassword');
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      AppLog.info('data.auth', 'updatePassword: success');
      return response;
    } catch (e, st) {
      AppLog.handle('data.auth', 'updatePassword failed', e, st);
      rethrow;
    }
  }
}
