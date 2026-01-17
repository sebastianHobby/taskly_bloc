import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_bloc/presentation/features/app/view/splash_screen.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/auth/view/sign_in_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/sign_up_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/forgot_password_view.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/services/today_badge_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/services/navigation_badge_service.dart';
import 'package:taskly_bloc/presentation/routing/router.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';

/// Root application widget with auth-gated UI.
///
/// The app shows different UIs based on authentication state:
/// - [AuthStatus.initial] / [AuthStatus.loading]: Splash screen
/// - [AuthStatus.authenticated]: Full app with router
/// - [AuthStatus.unauthenticated]: Auth flow (sign in/up)
///
/// This architecture ensures:
/// - No data access before authentication is confirmed
/// - No race conditions between auth and data seeding
/// - Clean separation between authenticated and unauthenticated UI
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    // GlobalSettingsBloc is provided at the root level, before AuthBloc,
    // so that theme/locale settings are available on all screens.
    return BlocProvider<GlobalSettingsBloc>(
      lazy: false, // Start immediately to load settings
      create: (_) => GlobalSettingsBloc(
        settingsRepository: getIt<SettingsRepositoryContract>(),
      )..add(const GlobalSettingsEvent.started()),
      child: BlocProvider<AuthBloc>(
        lazy: false, // Immediate creation to check auth state
        create: (context) {
          talker.debug('[app] Creating AuthBloc...');
          try {
            final bloc = AuthBloc(
              authRepository: getIt<AuthRepositoryContract>(),
            )..add(const AuthSubscriptionRequested());
            talker.debug('[app] AuthBloc created successfully');
            return bloc;
          } catch (e, st) {
            talker.handle(e, st, '[app] AuthBloc creation FAILED');
            rethrow;
          }
        },
        child: BlocListener<AuthBloc, AppAuthState>(
          listenWhen: (previous, current) {
            final becameAuthenticated =
                previous.status != AuthStatus.authenticated &&
                current.status == AuthStatus.authenticated;

            final leftAuthenticated =
                previous.status == AuthStatus.authenticated &&
                current.status != AuthStatus.authenticated;

            return becameAuthenticated || leftAuthenticated;
          },
          listener: (context, state) {
            final coordinator = getIt<AuthenticatedAppServicesCoordinator>();

            if (state.status == AuthStatus.authenticated) {
              unawaited(coordinator.start());
            } else {
              unawaited(coordinator.stop());
            }
          },
          child: BlocBuilder<AuthBloc, AppAuthState>(
            builder: (context, authState) {
              return switch (authState.status) {
                AuthStatus.initial ||
                AuthStatus.loading => const _ThemedApp(child: SplashScreen()),
                AuthStatus.authenticated => const _AuthenticatedApp(),
                AuthStatus.unauthenticated => const _UnauthenticatedApp(),
              };
            },
          ),
        ),
      ),
    );
  }
}

/// Wrapper that applies theme to a child widget (for splash/auth screens).
class _ThemedApp extends StatelessWidget {
  const _ThemedApp({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
      builder: (context, state) {
        return MaterialApp(
          theme: AppTheme.lightTheme(seedColor: state.seedColor),
          darkTheme: AppTheme.darkTheme(seedColor: state.seedColor),
          themeMode: state.flutterThemeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          home: child,
        );
      },
    );
  }
}

/// App shell for unauthenticated users.
///
/// Provides simple Navigator-based routing for auth screens only.
/// No data repositories are accessed in this tree.
class _UnauthenticatedApp extends StatelessWidget {
  const _UnauthenticatedApp();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
      builder: (context, state) {
        return MaterialApp(
          theme: AppTheme.lightTheme(seedColor: state.seedColor),
          darkTheme: AppTheme.darkTheme(seedColor: state.seedColor),
          themeMode: state.flutterThemeMode,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          initialRoute: '/sign-in',
          onGenerateRoute: (settings) {
            return switch (settings.name) {
              '/sign-in' => MaterialPageRoute(
                builder: (_) => const SignInView(),
                settings: settings,
              ),
              '/sign-up' => MaterialPageRoute(
                builder: (_) => const SignUpView(),
                settings: settings,
              ),
              '/forgot-password' => MaterialPageRoute(
                builder: (_) => const ForgotPasswordView(),
                settings: settings,
              ),
              _ => MaterialPageRoute(
                builder: (_) => const SignInView(),
                settings: settings,
              ),
            };
          },
        );
      },
    );
  }
}

/// App shell for authenticated users.
///
/// Provides full GoRouter-based navigation with all app features.
/// Data repositories are safe to access since auth is confirmed.
class _AuthenticatedApp extends StatelessWidget {
  const _AuthenticatedApp();

  static final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // TodayBadgeService: Lightweight service for navigation badge count
        Provider<TodayBadgeService>(
          create: (_) => TodayBadgeService(
            taskRepository: getIt<TaskRepositoryContract>(),
            homeDayService: getIt<HomeDayService>(),
          ),
        ),

        Provider<NavigationBadgeService>(
          create: (_) => NavigationBadgeService(
            taskRepository: getIt<TaskRepositoryContract>(),
            projectRepository: getIt<ProjectRepositoryContract>(),
          ),
        ),

        Provider<TileIntentDispatcher>(
          create: (_) => DefaultTileIntentDispatcher(
            projectRepository: getIt<ProjectRepositoryContract>(),
            editorLauncher: EditorLauncher.fromGetIt(),
          ),
        ),
      ],
      child: BlocProvider<ScreenActionsBloc>(
        create: (_) => ScreenActionsBloc(
          entityActionService: getIt<EntityActionService>(),
        ),
        child: BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
          builder: (context, state) {
            final settings = state.settings;

            return MaterialApp.router(
              scaffoldMessengerKey: _scaffoldMessengerKey,
              theme: AppTheme.lightTheme(seedColor: state.seedColor),
              darkTheme: AppTheme.darkTheme(seedColor: state.seedColor),
              themeMode: state.flutterThemeMode,
              locale: settings.localeCode == null
                  ? null
                  : Locale(settings.localeCode!),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return _ScreenActionsFailureSnackBarListener(
                  scaffoldMessengerKey: _scaffoldMessengerKey,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: TextScaler.linear(settings.textScaleFactor),
                    ),
                    child: _NotificationsBootstrapper(child: child!),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ScreenActionsFailureSnackBarListener extends StatefulWidget {
  const _ScreenActionsFailureSnackBarListener({
    required this.scaffoldMessengerKey,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  @override
  State<_ScreenActionsFailureSnackBarListener> createState() =>
      _ScreenActionsFailureSnackBarListenerState();
}

class _ScreenActionsFailureSnackBarListenerState
    extends State<_ScreenActionsFailureSnackBarListener> {
  final Map<_FailureDedupeKey, DateTime> _lastShownAt = {};

  @override
  Widget build(BuildContext context) {
    return BlocListener<ScreenActionsBloc, ScreenActionsState>(
      listenWhen: (previous, current) => current is ScreenActionsFailureState,
      listener: (context, state) {
        if (state is! ScreenActionsFailureState) return;

        final dedupeKey = _FailureDedupeKey(
          kind: state.failureKind,
          entityType: state.entityType,
          entityId: state.entityId,
        );

        final now = DateTime.now();
        final lastAt = _lastShownAt[dedupeKey];
        if (lastAt != null && now.difference(lastAt).inMilliseconds < 2000) {
          return;
        }
        _lastShownAt[dedupeKey] = now;

        final messenger = widget.scaffoldMessengerKey.currentState;
        if (messenger == null) return;

        final l10n = context.l10n;
        final baseMessage = _messageForFailureKind(l10n, state.failureKind);

        final message = state.error == null
            ? baseMessage
            : friendlyErrorMessageForUi(state.error!, l10n);

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      child: widget.child,
    );
  }

  String _messageForFailureKind(
    AppLocalizations l10n,
    ScreenActionsFailureKind kind,
  ) {
    return switch (kind) {
      ScreenActionsFailureKind.completionFailed => l10n.snackCompletionFailed,
      ScreenActionsFailureKind.pinFailed => l10n.snackPinFailed,
      ScreenActionsFailureKind.deleteFailed => l10n.snackDeleteFailed,
      ScreenActionsFailureKind.moveFailed => l10n.snackMoveFailed,
      ScreenActionsFailureKind.invalidOccurrenceData =>
        l10n.snackInvalidOccurrence,
    };
  }
}

@immutable
class _FailureDedupeKey {
  const _FailureDedupeKey({
    required this.kind,
    required this.entityType,
    required this.entityId,
  });

  final ScreenActionsFailureKind kind;
  final EntityType? entityType;
  final String? entityId;

  @override
  bool operator ==(Object other) {
    return other is _FailureDedupeKey &&
        other.kind == kind &&
        other.entityType == entityType &&
        other.entityId == entityId;
  }

  @override
  int get hashCode => Object.hash(kind, entityType, entityId);
}

class _NotificationsBootstrapper extends StatefulWidget {
  const _NotificationsBootstrapper({required this.child});

  final Widget child;

  @override
  State<_NotificationsBootstrapper> createState() =>
      _NotificationsBootstrapperState();
}

class _NotificationsBootstrapperState
    extends State<_NotificationsBootstrapper> {
  @override
  void initState() {
    super.initState();

    // Web is a secondary client: it should not consume/mark-delivered
    // notifications that mobile/desktop are expected to present.
    if (kIsWeb) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getIt<PendingNotificationsProcessor>().start();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
