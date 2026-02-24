import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';

const splashPath = '/splash';
const signInPath = '/sign-in';
const signUpPath = '/sign-up';
const checkEmailPath = '/check-email';
const forgotPasswordPath = '/forgot-password';
const authCallbackPath = '/auth/callback';
const resetPasswordPath = '/reset-password';
const initialSyncPath = '/initial-sync';
const onboardingPath = '/onboarding';
const myDayPath = '/my-day';

const Set<String> _preAuthRoutes = <String>{
  signInPath,
  signUpPath,
  checkEmailPath,
  forgotPasswordPath,
  authCallbackPath,
};

@visibleForTesting
bool isPreAuthRoutePath(String path) => _preAuthRoutes.contains(path);

@visibleForTesting
bool shouldBlockOnSync(InitialSyncGateState state) {
  return switch (state) {
    InitialSyncGateReady() => false,
    InitialSyncGateFailure() => true,
    InitialSyncGateInProgress(:final progress) =>
      !(progress?.hasSynced ?? false) && progress?.lastSyncedAt == null,
  };
}

String? sessionEntryRedirectTarget({
  required String path,
  required AppAuthState authState,
  required GlobalSettingsState settingsState,
  required InitialSyncGateState syncState,
  bool allowOnboardingDebug = false,
  String appHomePath = myDayPath,
}) {
  final isSplashRoute = path == splashPath;
  final isPreAuthRoute = isPreAuthRoutePath(path);
  final isResetPasswordRoute = path == resetPasswordPath;
  final isInitialSyncRoute = path == initialSyncPath;
  final isOnboardingRoute = path == onboardingPath;

  switch (authState.status) {
    case AuthStatus.initial:
      return isSplashRoute ? null : splashPath;
    case AuthStatus.loading:
      return (isSplashRoute || isPreAuthRoute) ? null : splashPath;
    case AuthStatus.unauthenticated:
      return isPreAuthRoute ? null : signInPath;
    case AuthStatus.authenticated:
      break;
  }

  if (authState.requiresPasswordUpdate) {
    return isResetPasswordRoute ? null : resetPasswordPath;
  }

  if (isResetPasswordRoute) {
    return appHomePath;
  }

  if (shouldBlockOnSync(syncState)) {
    return isInitialSyncRoute ? null : initialSyncPath;
  }

  if (settingsState.isLoading) {
    return isSplashRoute ? null : splashPath;
  }

  final shouldShowOnboarding =
      !settingsState.settings.onboardingCompleted || allowOnboardingDebug;
  if (shouldShowOnboarding) {
    return isOnboardingRoute ? null : onboardingPath;
  }

  if (isSplashRoute ||
      isPreAuthRoute ||
      isInitialSyncRoute ||
      isOnboardingRoute) {
    return appHomePath;
  }

  return null;
}
