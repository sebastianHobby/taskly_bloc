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

  testSafe(
    'regression: unauthenticated users should not be evaluated by sync gate',
    () async {
      final shouldGate = shouldEvaluateSyncGate(AuthStatus.unauthenticated);

      expect(shouldGate, isFalse);
    },
  );
}
