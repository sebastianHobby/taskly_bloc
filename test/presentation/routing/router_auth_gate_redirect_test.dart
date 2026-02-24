@Tags(['unit', 'routing'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/routing/router.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('auth loading does not redirect away from auth routes', () async {
    final target = authGateRedirectTarget(
      authStatus: AuthStatus.loading,
      isSplashRoute: false,
      isAuthRoute: true,
    );

    expect(target, isNull);
  });

  testSafe('auth loading redirects protected routes to splash', () async {
    final target = authGateRedirectTarget(
      authStatus: AuthStatus.loading,
      isSplashRoute: false,
      isAuthRoute: false,
    );

    expect(target, '/splash');
  });

  testSafe('unauthenticated redirects protected routes to sign-in', () async {
    final target = authGateRedirectTarget(
      authStatus: AuthStatus.unauthenticated,
      isSplashRoute: false,
      isAuthRoute: false,
    );

    expect(target, '/sign-in');
  });

  testSafe('auth callback route is treated as auth route', () async {
    expect(isAuthRoutePath('/auth/callback'), isTrue);
  });

  testSafe(
    'regression: unauthenticated users should not be evaluated by sync gate',
    () async {
      final shouldGate = shouldEvaluateSyncGate(AuthStatus.unauthenticated);

      expect(shouldGate, isFalse);
    },
  );

  testSafe(
    'unauthenticated users cannot access reset-password route',
    () async {
      final target = passwordUpdateRedirectTarget(
        authStatus: AuthStatus.unauthenticated,
        requiresPasswordUpdate: false,
        isResetPasswordRoute: true,
      );

      expect(target, '/sign-in');
    },
  );

  testSafe('authenticated recovery flow is forced to reset-password', () async {
    final target = passwordUpdateRedirectTarget(
      authStatus: AuthStatus.authenticated,
      requiresPasswordUpdate: true,
      isResetPasswordRoute: false,
    );

    expect(target, '/reset-password');
  });

  testSafe(
    'authenticated users leave reset-password when not needed',
    () async {
      final target = passwordUpdateRedirectTarget(
        authStatus: AuthStatus.authenticated,
        requiresPasswordUpdate: false,
        isResetPasswordRoute: true,
      );

      expect(target, '/my-day');
    },
  );
}
