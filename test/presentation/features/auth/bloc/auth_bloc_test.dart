import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';

import '..\..\..\..\../helpers/fallback_values.dart';
import '../../../../mocks/feature_mocks.dart';

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
  });

  setUpAll(registerAllFallbackValues);

  group('AuthBloc - Initialization', () {
    test('initial state is unauthenticated', () {
      final bloc = AuthBloc(authRepository: mockAuthRepo);
      expect(bloc.state.status, AuthStatus.initial);
      expect(bloc.state.user, isNull);
      bloc.close();
    });
  });

  group('AuthBloc - Subscription', () {
    blocTest<AuthBloc, AppAuthState>(
      'emits authenticated when session exists',
      setUp: () {
        final user = User(
          id: 'user-1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        final session = Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: user,
        );
        when(() => mockAuthRepo.currentSession).thenReturn(session);
        when(() => mockAuthRepo.watchAuthState()).thenAnswer(
          (_) => Stream.value(
            AuthState(AuthChangeEvent.signedIn, session),
          ),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
      expect: () => [
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.user, 'user', isNotNull)
            .having((s) => s.user?.id, 'user.id', 'user-1'),
      ],
    );

    blocTest<AuthBloc, AppAuthState>(
      'emits unauthenticated when no session exists',
      setUp: () {
        when(() => mockAuthRepo.currentSession).thenReturn(null);
        when(() => mockAuthRepo.watchAuthState()).thenAnswer(
          (_) => Stream.value(
            const AuthState(AuthChangeEvent.signedOut, null),
          ),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
      expect: () => [
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.user, 'user', isNull),
      ],
    );

    blocTest<AuthBloc, AppAuthState>(
      'listens to auth state changes',
      setUp: () {
        final user = User(
          id: 'user-1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        final session = Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: user,
        );
        when(() => mockAuthRepo.currentSession).thenReturn(null);
        when(() => mockAuthRepo.watchAuthState()).thenAnswer(
          (_) => Stream.fromIterable([
            const AuthState(AuthChangeEvent.signedOut, null),
            AuthState(AuthChangeEvent.signedIn, session),
          ]),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.unauthenticated,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.user, 'user', isNotNull),
      ],
    );
  });

  group('AuthBloc - Sign In', () {
    blocTest<AuthBloc, AppAuthState>(
      'emits loading then authenticated on successful sign in',
      setUp: () {
        final user = User(
          id: 'user-1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        final session = Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: user,
        );
        when(
          () => mockAuthRepo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(session: session, user: user),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(
        const AuthSignInRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.user, 'user', isNotNull)
            .having((s) => s.user?.id, 'user.id', 'user-1')
            .having((s) => s.error, 'error', isNull),
      ],
      verify: (_) {
        verify(
          () => mockAuthRepo.signInWithPassword(
            email: 'test@example.com',
            password: 'password123',
          ),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AppAuthState>(
      'emits loading then unauthenticated on sign in failure',
      setUp: () {
        when(
          () => mockAuthRepo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          AuthException('Invalid credentials'),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(
        const AuthSignInRequested(
          email: 'test@example.com',
          password: 'wrongpassword',
        ),
      ),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.error, 'error', contains('Invalid credentials'))
            .having((s) => s.user, 'user', isNull),
      ],
    );

    blocTest<AuthBloc, AppAuthState>(
      'emits unauthenticated when response has no session',
      setUp: () {
        when(
          () => mockAuthRepo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(
        const AuthSignInRequested(
          email: 'test@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.error, 'error', 'Sign in failed'),
      ],
    );
  });

  group('AuthBloc - Sign Up', () {
    blocTest<AuthBloc, AppAuthState>(
      'emits loading then authenticated on successful sign up',
      setUp: () {
        final user = User(
          id: 'user-1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        );
        final session = Session(
          accessToken: 'token',
          tokenType: 'bearer',
          user: user,
        );
        when(
          () => mockAuthRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async => AuthResponse(session: session, user: user),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(
        const AuthSignUpRequested(
          email: 'newuser@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.authenticated)
            .having((s) => s.user, 'user', isNotNull)
            .having((s) => s.user?.id, 'user.id', 'user-1'),
      ],
      verify: (_) {
        verify(
          () => mockAuthRepo.signUp(
            email: 'newuser@example.com',
            password: 'password123',
          ),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AppAuthState>(
      'emits loading then unauthenticated on sign up failure',
      setUp: () {
        when(
          () => mockAuthRepo.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          AuthException('Email already registered'),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(
        const AuthSignUpRequested(
          email: 'existing@example.com',
          password: 'password123',
        ),
      ),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having(
              (s) => s.error,
              'error',
              contains('Email already registered'),
            ),
      ],
    );
  });

  group('AuthBloc - Sign Out', () {
    blocTest<AuthBloc, AppAuthState>(
      'emits loading then unauthenticated on successful sign out',
      setUp: () {
        when(() => mockAuthRepo.signOut()).thenAnswer((_) async {});
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.user, 'user', isNull),
      ],
      verify: (_) {
        verify(() => mockAuthRepo.signOut()).called(1);
      },
    );

    blocTest<AuthBloc, AppAuthState>(
      'emits error on sign out failure',
      setUp: () {
        when(() => mockAuthRepo.signOut()).thenThrow(
          Exception('Sign out failed'),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.error, 'error', contains('Sign out failed')),
      ],
    );
  });

  group('AuthBloc - Password Reset', () {
    blocTest<AuthBloc, AppAuthState>(
      'emits success message on password reset request',
      setUp: () {
        when(
          () => mockAuthRepo.resetPasswordForEmail(any()),
        ).thenAnswer((_) async {});
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(
        const AuthPasswordResetRequested(email: 'test@example.com'),
      ),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.message, 'message', contains('Password reset')),
      ],
      verify: (_) {
        verify(
          () => mockAuthRepo.resetPasswordForEmail('test@example.com'),
        ).called(1);
      },
    );

    blocTest<AuthBloc, AppAuthState>(
      'emits error on password reset failure',
      setUp: () {
        when(
          () => mockAuthRepo.resetPasswordForEmail(any()),
        ).thenThrow(
          AuthException('Email not found'),
        );
      },
      build: () => AuthBloc(authRepository: mockAuthRepo),
      act: (bloc) => bloc.add(
        const AuthPasswordResetRequested(email: 'nonexistent@example.com'),
      ),
      expect: () => [
        isA<AppAuthState>().having(
          (s) => s.status,
          'status',
          AuthStatus.loading,
        ),
        isA<AppAuthState>()
            .having((s) => s.status, 'status', AuthStatus.unauthenticated)
            .having((s) => s.error, 'error', contains('Email not found')),
      ],
    );
  });

  group('AuthBloc - State Properties', () {
    test('isAuthenticated returns true when authenticated', () {
      final state = AppAuthState(
        status: AuthStatus.authenticated,
        user: User(
          id: 'user-1',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      expect(state.isAuthenticated, isTrue);
      expect(state.isUnauthenticated, isFalse);
      expect(state.isLoading, isFalse);
    });

    test('isUnauthenticated returns true when unauthenticated', () {
      const state = AppAuthState(status: AuthStatus.unauthenticated);
      expect(state.isAuthenticated, isFalse);
      expect(state.isUnauthenticated, isTrue);
      expect(state.isLoading, isFalse);
    });

    test('isLoading returns true when loading', () {
      const state = AppAuthState(status: AuthStatus.loading);
      expect(state.isAuthenticated, isFalse);
      expect(state.isUnauthenticated, isFalse);
      expect(state.isLoading, isTrue);
    });

    test('copyWith preserves existing values when not overridden', () {
      final user = User(
        id: 'user-1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      final state = AppAuthState(
        status: AuthStatus.authenticated,
        user: user,
        error: 'old error',
      );

      final newState = state.copyWith(status: AuthStatus.loading);

      expect(newState.status, AuthStatus.loading);
      expect(newState.user, user);
      expect(newState.error, isNull); // copyWith clears error
    });
  });
}
