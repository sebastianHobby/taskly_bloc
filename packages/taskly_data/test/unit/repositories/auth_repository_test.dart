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

class _MockSession extends Mock implements supabase.Session {}

class _MockUser extends Mock implements supabase.User {}

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
        emailRedirectTo: any(named: 'emailRedirectTo'),
      ),
    ).thenAnswer((_) async => supabase.AuthResponse());

    final repo = AuthRepository(client: client);
    final response = await repo.signUp(
      email: 'new@test.com',
      password: 'secret',
    );

    expect(response, isA<AuthResponse>());
  });

  testSafe('signUp prefers injected redirect resolver', () async {
    when(
      () => authClient.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        emailRedirectTo: any(named: 'emailRedirectTo'),
      ),
    ).thenAnswer((_) async => supabase.AuthResponse());

    final repo = AuthRepository(
      client: client,
      redirectUrlResolver: (_) => 'https://example.com/auth/callback',
    );

    await repo.signUp(
      email: 'new@test.com',
      password: 'secret',
    );

    verify(
      () => authClient.signUp(
        email: 'new@test.com',
        password: 'secret',
        emailRedirectTo: 'https://example.com/auth/callback',
      ),
    ).called(1);
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
      () => authClient.resetPasswordForEmail(
        any(),
        redirectTo: any(named: 'redirectTo'),
      ),
    ).thenAnswer((_) async {});

    final repo = AuthRepository(client: client);
    await repo.resetPasswordForEmail('reset@test.com');

    verify(
      () => authClient.resetPasswordForEmail(
        'reset@test.com',
        redirectTo: any(named: 'redirectTo'),
      ),
    ).called(1);
  });

  testSafe(
    'uses flow-specific redirect resolver for sign-up and recovery',
    () async {
      when(
        () => authClient.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async => supabase.AuthResponse());
      when(
        () => authClient.resetPasswordForEmail(
          any(),
          redirectTo: any(named: 'redirectTo'),
        ),
      ).thenAnswer((_) async {});

      final repo = AuthRepository(
        client: client,
        redirectUrlResolver: (flow) {
          return switch (flow) {
            AuthRedirectFlow.signUp =>
              'https://example.com/auth/callback/signup',
            AuthRedirectFlow.passwordRecovery =>
              'https://example.com/auth/callback/recovery',
          };
        },
      );

      await repo.signUp(email: 'new@test.com', password: 'secret');
      await repo.resetPasswordForEmail('reset@test.com');

      verify(
        () => authClient.signUp(
          email: 'new@test.com',
          password: 'secret',
          emailRedirectTo: 'https://example.com/auth/callback/signup',
        ),
      ).called(1);
      verify(
        () => authClient.resetPasswordForEmail(
          'reset@test.com',
          redirectTo: 'https://example.com/auth/callback/recovery',
        ),
      ).called(1);
    },
  );

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

  testSafe('watchAuthState maps additional auth events', () async {
    when(
      () => authClient.onAuthStateChange,
    ).thenAnswer(
      (_) => Stream.fromIterable([
        supabase.AuthState(supabase.AuthChangeEvent.passwordRecovery, null),
        supabase.AuthState(supabase.AuthChangeEvent.tokenRefreshed, null),
        supabase.AuthState(supabase.AuthChangeEvent.userUpdated, null),
      ]),
    );

    final repo = AuthRepository(client: client);
    final events = await repo.watchAuthState().take(3).toList();

    expect(events[0].event, AuthEventKind.passwordRecovery);
    expect(events[1].event, AuthEventKind.tokenRefreshed);
    expect(events[2].event, AuthEventKind.userUpdated);
  });

  testSafe('currentSession maps supabase session data', () async {
    final session = _MockSession();
    final user = _MockUser();
    when(() => user.id).thenReturn('user-10');
    when(() => user.email).thenReturn('user10@test.com');
    when(() => user.userMetadata).thenReturn(const {'role': 'tester'});
    when(() => session.user).thenReturn(user);
    when(() => session.expiresAt).thenReturn(1735689600);
    when(() => authClient.currentSession).thenReturn(session);

    final repo = AuthRepository(client: client);

    expect(repo.currentSession, isNotNull);
    expect(repo.currentSession!.user.id, 'user-10');
    expect(repo.currentSession!.expiresAt, isNotNull);
  });

  testSafe('currentSession/currentUser return null when absent', () async {
    when(() => authClient.currentSession).thenReturn(null);
    when(() => authClient.currentUser).thenReturn(null);

    final repo = AuthRepository(client: client);

    expect(repo.currentSession, isNull);
    expect(repo.currentUser, isNull);
  });

  testSafe('maps failures for all write auth methods', () async {
    when(
      () => authClient.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
        emailRedirectTo: any(named: 'emailRedirectTo'),
      ),
    ).thenThrow(Exception('signup-fail'));
    when(
      () => authClient.signOut(scope: supabase.SignOutScope.local),
    ).thenThrow(Exception('signout-fail'));
    when(
      () => authClient.resetPasswordForEmail(
        any(),
        redirectTo: any(named: 'redirectTo'),
      ),
    ).thenThrow(Exception('reset-fail'));
    when(
      () => authClient.updateUser(any(that: isA<supabase.UserAttributes>())),
    ).thenThrow(Exception('update-fail'));

    final repo = AuthRepository(client: client);

    await expectLater(
      () => repo.signUp(email: 'x@test.com', password: 'p'),
      throwsA(isA<UnknownFailure>()),
    );
    await expectLater(() => repo.signOut(), throwsA(isA<UnknownFailure>()));
    await expectLater(
      () => repo.resetPasswordForEmail('x@test.com'),
      throwsA(isA<UnknownFailure>()),
    );
    await expectLater(
      () => repo.updatePassword('new'),
      throwsA(isA<UnknownFailure>()),
    );
    await expectLater(
      () => repo.updateUserProfile(displayName: null),
      throwsA(isA<UnknownFailure>()),
    );
  });
}
