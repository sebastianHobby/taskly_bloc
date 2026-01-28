@Tags(['unit', 'auth'])
library;

import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_imports.dart';
import '../../../../mocks/repository_mocks.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_domain/auth.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/telemetry.dart';

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
    registerFallbackValue(
      const OperationContext(
        correlationId: 'corr-1',
        feature: 'auth',
        intent: 'test',
        operation: 'test',
      ),
    );
  });
  setUp(setUpTestEnvironment);

  late MockAuthRepositoryContract authRepository;
  late AppErrorReporter errorReporter;
  late TestStreamController<AuthStateChange> authStream;

  AuthBloc buildBloc() {
    return AuthBloc(
      authRepository: authRepository,
      errorReporter: errorReporter,
    );
  }

  setUp(() {
    authRepository = MockAuthRepositoryContract();
    errorReporter = AppErrorReporter(
      messengerKey: GlobalKey<ScaffoldMessengerState>(),
    );
    authStream = TestStreamController.seeded(
      const AuthStateChange(event: AuthEventKind.initialSession),
    );

    when(() => authRepository.currentSession).thenReturn(null);
    when(() => authRepository.watchAuthState()).thenAnswer(
      (_) => authStream.stream,
    );
    addTearDown(authStream.close);
  });

  blocTestSafe<AuthBloc, AppAuthState>(
    'subscription emits authenticated when session exists',
    build: () {
      when(() => authRepository.currentSession).thenReturn(
        const AuthSession(user: AuthUser(id: 'user-1')),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const AuthSubscriptionRequested()),
    expect: () => [
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AuthStatus.authenticated)
          .having((s) => s.user?.id, 'user.id', 'user-1'),
    ],
  );

  blocTestSafe<AuthBloc, AppAuthState>(
    'updates to authenticated when auth stream emits session',
    build: buildBloc,
    act: (bloc) {
      bloc.add(const AuthSubscriptionRequested());
      authStream.emit(
        const AuthStateChange(
          event: AuthEventKind.signedIn,
          session: AuthSession(user: AuthUser(id: 'user-2')),
        ),
      );
    },
    expect: () => [
      isA<AppAuthState>().having(
        (s) => s.status,
        'status',
        AuthStatus.unauthenticated,
      ),
      isA<AppAuthState>()
          .having((s) => s.status, 'status', AuthStatus.authenticated)
          .having((s) => s.user?.id, 'user.id', 'user-2'),
    ],
  );

  blocTestSafe<AuthBloc, AppAuthState>(
    'sign in failure emits error and unauthenticated',
    build: () {
      when(
        () => authRepository.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
          context: any(named: 'context'),
        ),
      ).thenThrow(const AuthFailure(message: 'bad creds'));
      return buildBloc();
    },
    act: (bloc) {
      bloc.add(const AuthSignInRequested(email: 'a@b.com', password: 'pw'));
    },
    expect: () => [
      isA<AppAuthState>().having((s) => s.status, 'status', AuthStatus.loading),
      isA<AppAuthState>()
          .having(
            (s) => s.status,
            'status',
            AuthStatus.unauthenticated,
          )
          .having((s) => s.error, 'error', 'bad creds'),
    ],
  );

  blocTestSafe<AuthBloc, AppAuthState>(
    'sign out forwards operation context',
    build: () {
      when(() => authRepository.signOut(context: any(named: 'context')))
          .thenAnswer((_) async {});
      return buildBloc();
    },
    act: (bloc) => bloc.add(const AuthSignOutRequested()),
    expect: () => [
      isA<AppAuthState>().having(
        (s) => s.status,
        'status',
        AuthStatus.unauthenticated,
      ),
    ],
    verify: (_) {
      final captured = verify(
        () => authRepository.signOut(context: captureAny(named: 'context')),
      ).captured;
      final ctx = captured.single as OperationContext;
      expect(ctx.feature, 'auth');
      expect(ctx.operation, 'auth.sign_out');
      expect(ctx.screen, 'settings');
    },
  );
}

