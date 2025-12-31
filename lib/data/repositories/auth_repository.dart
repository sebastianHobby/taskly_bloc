import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';

/// Implementation of authentication repository using Supabase.
class AuthRepository implements AuthRepositoryContract {
  AuthRepository({required SupabaseClient client}) : _client = client;

  final SupabaseClient _client;

  @override
  Stream<AuthState> watchAuthState() {
    talker.debug(
      '[AuthRepository] watchAuthState: subscribing to auth changes',
    );
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
    talker.info('[AuthRepository] signInWithPassword: email=$email');
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      talker.info('[AuthRepository] signInWithPassword: success');
      return response;
    } catch (e, st) {
      talker.handle(e, st, '[AuthRepository] signInWithPassword failed');
      rethrow;
    }
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    talker.info('[AuthRepository] signUp: email=$email');
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      talker.info('[AuthRepository] signUp: success');
      return response;
    } catch (e, st) {
      talker.handle(e, st, '[AuthRepository] signUp failed');
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    talker.info('[AuthRepository] signOut');
    try {
      await _client.auth.signOut();
      talker.info('[AuthRepository] signOut: success');
    } catch (e, st) {
      talker.handle(e, st, '[AuthRepository] signOut failed');
      rethrow;
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    talker.info('[AuthRepository] resetPasswordForEmail: email=$email');
    try {
      await _client.auth.resetPasswordForEmail(email);
      talker.info('[AuthRepository] resetPasswordForEmail: success');
    } catch (e, st) {
      talker.handle(e, st, '[AuthRepository] resetPasswordForEmail failed');
      rethrow;
    }
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    talker.info('[AuthRepository] updatePassword');
    try {
      final response = await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      talker.info('[AuthRepository] updatePassword: success');
      return response;
    } catch (e, st) {
      talker.handle(e, st, '[AuthRepository] updatePassword failed');
      rethrow;
    }
  }
}
