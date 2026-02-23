@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../helpers/test_imports.dart';
import 'package:taskly_data/src/repositories/auth_repository.dart';
import 'package:taskly_domain/auth.dart';
import 'package:taskly_domain/errors.dart';

class _MockSupabaseClient extends Mock implements supabase.SupabaseClient {}

class _MockGoTrueClient extends Mock implements supabase.GoTrueClient {}

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUpAll(() {
    registerFallbackValue(supabase.UserAttributes());
  });
  setUp(setUpTestEnvironment);

  late _MockSupabaseClient client;
  late _MockGoTrueClient authClient;

  setUp(() {
    client = _MockSupabaseClient();
    authClient = _MockGoTrueClient();
    when(() => client.auth).thenReturn(authClient);
  });

  testSafe('signInWithPassword maps auth response', () async {
    when(
      () => authClient.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => supabase.AuthResponse());

    final repo = AuthRepository(client: client);
    final response = await repo.signInWithPassword(
      email: 'user@test.com',
      password: 'secret',
    );

    expect(response, isA<AuthResponse>());
    expect(response.session, isNull);
  });

  testSafe('updateUserProfile maps user response', () async {
    when(
      () => authClient.updateUser(any(that: isA<supabase.UserAttributes>())),
    ).thenAnswer(
      (_) async => supabase.UserResponse.fromJson({
        'id': 'user-1',
        'aud': 'authenticated',
        'created_at': '2025-01-01T00:00:00Z',
      }),
    );

    final repo = AuthRepository(client: client);
    final response = await repo.updateUserProfile(displayName: 'Alex');

    expect(response.user?.id, 'user-1');
  });

  testSafe('signUp maps auth response', () async {
    when(
      () => authClient.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => supabase.AuthResponse());

    final repo = AuthRepository(client: client);
    final response = await repo.signUp(
      email: 'new@test.com',
      password: 'secret',
    );

    expect(response, isA<AuthResponse>());
  });

  testSafe('signOut calls local sign out scope', () async {
    when(
      () => authClient.signOut(scope: supabase.SignOutScope.local),
    ).thenAnswer((_) async {});

    final repo = AuthRepository(client: client);
    await repo.signOut();

    verify(
      () => authClient.signOut(scope: supabase.SignOutScope.local),
    ).called(1);
  });

  testSafe('resetPasswordForEmail delegates to supabase auth', () async {
    when(
      () => authClient.resetPasswordForEmail(any()),
    ).thenAnswer((_) async {});

    final repo = AuthRepository(client: client);
    await repo.resetPasswordForEmail('reset@test.com');

    verify(() => authClient.resetPasswordForEmail('reset@test.com')).called(1);
  });

  testSafe('updatePassword maps user response', () async {
    when(
      () => authClient.updateUser(any(that: isA<supabase.UserAttributes>())),
    ).thenAnswer(
      (_) async => supabase.UserResponse.fromJson({
        'id': 'user-2',
        'aud': 'authenticated',
        'created_at': '2025-01-01T00:00:00Z',
      }),
    );

    final repo = AuthRepository(client: client);
    final response = await repo.updatePassword('new-secret');

    expect(response.user?.id, 'user-2');
  });

  testSafe('watchAuthState maps stream event', () async {
    when(
      () => authClient.onAuthStateChange,
    ).thenAnswer(
      (_) => Stream.value(
        supabase.AuthState(supabase.AuthChangeEvent.signedIn, null),
      ),
    );

    final repo = AuthRepository(client: client);
    final state = await repo.watchAuthState().first;

    expect(state.event, AuthEventKind.signedIn);
    expect(state.session, isNull);
  });

  testSafe('currentUser maps supabase user', () async {
    when(
      () => authClient.currentUser,
    ).thenReturn(
      supabase.User.fromJson({
        'id': 'user-3',
        'aud': 'authenticated',
        'created_at': '2025-01-01T00:00:00Z',
        'email': 'user3@test.com',
      }),
    );

    final repo = AuthRepository(client: client);

    expect(repo.currentUser?.id, 'user-3');
    expect(repo.currentUser?.email, 'user3@test.com');
  });

  testSafe('maps failures from auth exceptions', () async {
    when(
      () => authClient.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(Exception('boom'));

    final repo = AuthRepository(client: client);

    expect(
      () => repo.signInWithPassword(email: 'x@test.com', password: 'bad'),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
