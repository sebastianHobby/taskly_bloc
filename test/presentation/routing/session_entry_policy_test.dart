@Tags(['unit', 'routing'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/routing/session_entry_policy.dart';
import 'package:taskly_domain/settings.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  GlobalSettingsState loadedSettings({bool onboardingCompleted = true}) {
    return GlobalSettingsState(
      isLoading: false,
      settings: GlobalSettings(onboardingCompleted: onboardingCompleted),
    );
  }

  const syncReady = InitialSyncGateReady();
  const syncBlocked = InitialSyncGateInProgress(progress: null);

  testSafe('identifies pre-auth routes', () async {
    expect(isPreAuthRoutePath('/sign-in'), isTrue);
    expect(isPreAuthRoutePath('/auth/callback'), isTrue);
    expect(isPreAuthRoutePath('/my-day'), isFalse);
  });

  testSafe(
    'sync blocking is true for in-progress with no checkpoint',
    () async {
      expect(shouldBlockOnSync(syncBlocked), isTrue);
      expect(shouldBlockOnSync(syncReady), isFalse);
    },
  );

  testSafe('initial auth redirects protected routes to splash', () async {
    final target = sessionEntryRedirectTarget(
      path: '/my-day',
      authState: const AppAuthState(status: AuthStatus.initial),
      settingsState: loadedSettings(),
      syncState: syncReady,
    );
    expect(target, splashPath);
  });

  testSafe('initial auth allows pre-auth routes', () async {
    final target = sessionEntryRedirectTarget(
      path: authCallbackPath,
      authState: const AppAuthState(status: AuthStatus.initial),
      settingsState: loadedSettings(),
      syncState: syncReady,
    );
    expect(target, isNull);
  });

  testSafe('loading auth allows pre-auth routes', () async {
    final target = sessionEntryRedirectTarget(
      path: signUpPath,
      authState: const AppAuthState(status: AuthStatus.loading),
      settingsState: loadedSettings(),
      syncState: syncReady,
    );
    expect(target, isNull);
  });

  testSafe('loading auth redirects protected routes to splash', () async {
    final target = sessionEntryRedirectTarget(
      path: '/my-day',
      authState: const AppAuthState(status: AuthStatus.loading),
      settingsState: loadedSettings(),
      syncState: syncReady,
    );
    expect(target, splashPath);
  });

  testSafe('unauthenticated allows pre-auth routes', () async {
    final target = sessionEntryRedirectTarget(
      path: forgotPasswordPath,
      authState: const AppAuthState(status: AuthStatus.unauthenticated),
      settingsState: loadedSettings(onboardingCompleted: false),
      syncState: syncBlocked,
    );
    expect(target, isNull);
  });

  testSafe(
    'unauthenticated always redirects protected routes to sign-in',
    () async {
      final target = sessionEntryRedirectTarget(
        path: '/onboarding',
        authState: const AppAuthState(status: AuthStatus.unauthenticated),
        settingsState: loadedSettings(onboardingCompleted: false),
        syncState: syncBlocked,
      );
      expect(target, signInPath);
    },
  );

  testSafe('authenticated recovery is forced to reset-password', () async {
    final target = sessionEntryRedirectTarget(
      path: '/my-day',
      authState: const AppAuthState(
        status: AuthStatus.authenticated,
        requiresPasswordUpdate: true,
      ),
      settingsState: loadedSettings(),
      syncState: syncReady,
    );
    expect(target, resetPasswordPath);
  });

  testSafe(
    'authenticated reset-password exits to my-day when not required',
    () async {
      final target = sessionEntryRedirectTarget(
        path: resetPasswordPath,
        authState: const AppAuthState(status: AuthStatus.authenticated),
        settingsState: loadedSettings(),
        syncState: syncReady,
      );
      expect(target, myDayPath);
    },
  );

  testSafe(
    'authenticated with blocked sync is routed to initial-sync',
    () async {
      final target = sessionEntryRedirectTarget(
        path: '/my-day',
        authState: const AppAuthState(status: AuthStatus.authenticated),
        settingsState: loadedSettings(),
        syncState: syncBlocked,
      );
      expect(target, initialSyncPath);
    },
  );

  testSafe('authenticated waits on settings load at splash', () async {
    final target = sessionEntryRedirectTarget(
      path: '/my-day',
      authState: const AppAuthState(status: AuthStatus.authenticated),
      settingsState: const GlobalSettingsState(isLoading: true),
      syncState: syncReady,
    );
    expect(target, splashPath);
  });

  testSafe(
    'authenticated with incomplete onboarding is routed to onboarding',
    () async {
      final target = sessionEntryRedirectTarget(
        path: '/my-day',
        authState: const AppAuthState(status: AuthStatus.authenticated),
        settingsState: loadedSettings(onboardingCompleted: false),
        syncState: syncReady,
      );
      expect(target, onboardingPath);
    },
  );

  testSafe(
    'authenticated debug onboarding can force onboarding route',
    () async {
      final target = sessionEntryRedirectTarget(
        path: '/projects',
        authState: const AppAuthState(status: AuthStatus.authenticated),
        settingsState: loadedSettings(onboardingCompleted: true),
        syncState: syncReady,
        allowOnboardingDebug: true,
      );
      expect(target, onboardingPath);
    },
  );

  testSafe('authenticated on splash enters app at my-day', () async {
    final target = sessionEntryRedirectTarget(
      path: splashPath,
      authState: const AppAuthState(status: AuthStatus.authenticated),
      settingsState: loadedSettings(),
      syncState: syncReady,
    );
    expect(target, myDayPath);
  });

  testSafe('authenticated app route remains unchanged', () async {
    final target = sessionEntryRedirectTarget(
      path: '/projects',
      authState: const AppAuthState(status: AuthStatus.authenticated),
      settingsState: loadedSettings(),
      syncState: syncReady,
    );
    expect(target, isNull);
  });

  testSafe(
    'authenticated onboarding route exits to canonical app home',
    () async {
      final target = sessionEntryRedirectTarget(
        path: onboardingPath,
        authState: const AppAuthState(status: AuthStatus.authenticated),
        settingsState: loadedSettings(onboardingCompleted: true),
        syncState: syncReady,
      );
      expect(target, myDayPath);
    },
  );
}
