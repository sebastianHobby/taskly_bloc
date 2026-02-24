@Tags(['widget', 'routing'])
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/router.dart';
import 'package:taskly_domain/settings.dart';

import '../../helpers/test_imports.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AppAuthState>
    implements AuthBloc {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();
    registerAllFallbackValues();
  });
  setUp(setUpTestEnvironment);

  late MockAuthBloc authBloc;

  setUp(() {
    authBloc = MockAuthBloc();
    addTearDown(authBloc.close);
  });

  void stubAuth(AppAuthState authState) {
    when(() => authBloc.state).thenReturn(authState);
    whenListen(
      authBloc,
      Stream<AppAuthState>.value(authState),
      initialState: authState,
    );
  }

  Future<GoRouter> pumpRouter(
    WidgetTester tester, {
    required AppAuthState authState,
    required GlobalSettingsState settingsState,
    required InitialSyncGateState syncState,
  }) async {
    stubAuth(authState);
    final router = createRouter(
      authStateSelector: (_) => authState,
      settingsStateSelector: (_) => settingsState,
      syncStateSelector: (_) => syncState,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      BlocProvider<AuthBloc>.value(
        value: authBloc,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpForStream();
    return router;
  }

  Future<void> expectNavigation(
    WidgetTester tester,
    GoRouter router, {
    required String from,
    required String to,
  }) async {
    router.go(from);
    await tester.pumpForStream();
    await tester.pumpUntilCondition(
      () => router.routeInformationProvider.value.uri.path == to,
      reason: 'Expected route to be $to from $from',
    );
    expect(router.routeInformationProvider.value.uri.path, to);
  }

  testWidgetsSafe('unauthenticated protected route redirects to sign-in', (
    tester,
  ) async {
    final router = await pumpRouter(
      tester,
      authState: const AppAuthState(status: AuthStatus.unauthenticated),
      settingsState: const GlobalSettingsState(isLoading: false),
      syncState: const InitialSyncGateReady(),
    );
    await expectNavigation(tester, router, from: '/my-day', to: '/sign-in');
  });

  testWidgetsSafe('unauthenticated onboarding route redirects to sign-in', (
    tester,
  ) async {
    final router = await pumpRouter(
      tester,
      authState: const AppAuthState(status: AuthStatus.unauthenticated),
      settingsState: const GlobalSettingsState(
        isLoading: false,
        settings: GlobalSettings(onboardingCompleted: false),
      ),
      syncState: const InitialSyncGateInProgress(progress: null),
    );
    await expectNavigation(tester, router, from: '/onboarding', to: '/sign-in');
  });

  testWidgetsSafe('unauthenticated still allows sign-up route', (tester) async {
    final router = await pumpRouter(
      tester,
      authState: const AppAuthState(status: AuthStatus.unauthenticated),
      settingsState: const GlobalSettingsState(isLoading: false),
      syncState: const InitialSyncGateReady(),
    );
    await expectNavigation(tester, router, from: '/sign-up', to: '/sign-up');
  });

  testWidgetsSafe('unauthenticated still allows auth callback route', (
    tester,
  ) async {
    final router = await pumpRouter(
      tester,
      authState: const AppAuthState(status: AuthStatus.unauthenticated),
      settingsState: const GlobalSettingsState(isLoading: false),
      syncState: const InitialSyncGateReady(),
    );
    await expectNavigation(
      tester,
      router,
      from: '/auth/callback',
      to: '/auth/callback',
    );
  });

  testWidgetsSafe('loading auth keeps protected routes at splash', (
    tester,
  ) async {
    final router = await pumpRouter(
      tester,
      authState: const AppAuthState(status: AuthStatus.loading),
      settingsState: const GlobalSettingsState(isLoading: false),
      syncState: const InitialSyncGateReady(),
    );
    await expectNavigation(tester, router, from: '/my-day', to: '/splash');
  });

  testWidgetsSafe('authenticated recovery flow redirects to reset-password', (
    tester,
  ) async {
    final router = await pumpRouter(
      tester,
      authState: const AppAuthState(
        status: AuthStatus.authenticated,
        requiresPasswordUpdate: true,
      ),
      settingsState: const GlobalSettingsState(isLoading: false),
      syncState: const InitialSyncGateReady(),
    );
    await expectNavigation(
      tester,
      router,
      from: '/my-day',
      to: '/reset-password',
    );
  });
}
