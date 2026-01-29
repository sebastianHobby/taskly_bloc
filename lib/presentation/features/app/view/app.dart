import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:taskly_core/logging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/errors/app_error_reporter.dart';
import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';
import 'package:taskly_bloc/l10n/l10n.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_bloc/presentation/theme/app_theme.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_bloc/presentation/features/app/view/splash_screen.dart';
import 'package:taskly_bloc/presentation/features/auth/bloc/auth_bloc.dart';
import 'package:taskly_bloc/presentation/features/auth/view/sign_in_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/sign_up_view.dart';
import 'package:taskly_bloc/presentation/features/auth/view/forgot_password_view.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/initial_sync_gate_bloc.dart';
import 'package:taskly_bloc/presentation/features/app/view/initial_sync_gate_screen.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/debug_bootstrap_bloc.dart';
import 'package:taskly_bloc/presentation/features/app/view/debug_bootstrap_sheet.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/global_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/guided_tour/bloc/guided_tour_bloc.dart';
import 'package:taskly_bloc/presentation/routing/router.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/screen_actions_state.dart';
import 'package:taskly_bloc/presentation/screens/tiles/tile_intent_dispatcher.dart';
import 'package:taskly_bloc/presentation/shared/errors/friendly_error_message.dart';
import 'package:taskly_bloc/presentation/features/editors/editor_launcher.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_gate_query_service.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/sync/sync_anomaly_bloc.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_bloc/presentation/shared/session/presentation_session_services_coordinator.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_mode_service.dart';
import 'package:taskly_bloc/presentation/shared/session/demo_data_provider.dart';
import 'package:taskly_bloc/core/config/debug_bootstrap_flags.dart';

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

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static final AppErrorReporter errorReporter = AppErrorReporter(
    messengerKey: scaffoldMessengerKey,
  );

  @override
  Widget build(BuildContext context) {
    // GlobalSettingsBloc is provided at the root level, before AuthBloc,
    // so that theme/locale settings are available on all screens.
    return Provider<AppErrorReporter>.value(
      value: App.errorReporter,
      child: BlocProvider<GlobalSettingsBloc>(
        lazy: false, // Start immediately to load settings
        create: (context) => GlobalSettingsBloc(
          settingsRepository: getIt<SettingsRepositoryContract>(),
          attentionRepository: getIt<AttentionRepositoryContract>(),
          nowService: getIt<NowService>(),
          errorReporter: context.read<AppErrorReporter>(),
        )..add(const GlobalSettingsEvent.started()),
        child: BlocProvider<AuthBloc>(
          lazy: false, // Immediate creation to check auth state
          create: (context) {
            talker.debug('[app] Creating AuthBloc...');
            try {
              final bloc = AuthBloc(
                authRepository: getIt<AuthRepositoryContract>(),
                errorReporter: context.read<AppErrorReporter>(),
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
              final sessionCoordinator =
                  getIt<PresentationSessionServicesCoordinator>();

              if (state.status == AuthStatus.authenticated) {
                unawaited(() async {
                  await coordinator.start();
                  await sessionCoordinator.start();
                }());
              } else {
                unawaited(() async {
                  await sessionCoordinator.stop();
                  await coordinator.stop();
                }());
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
          navigatorKey: App.navigatorKey,
          scaffoldMessengerKey: App.scaffoldMessengerKey,
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
          navigatorKey: App.navigatorKey,
          scaffoldMessengerKey: App.scaffoldMessengerKey,
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepositoryContract>(
          create: (_) => getIt<AuthRepositoryContract>(),
        ),
        Provider<NowService>(create: (_) => getIt<NowService>()),
        Provider<HomeDayService>(create: (_) => getIt<HomeDayService>()),
        Provider<HomeDayKeyService>(create: (_) => getIt<HomeDayKeyService>()),
        Provider<TemporalTriggerService>(
          create: (_) => getIt<TemporalTriggerService>(),
        ),
        Provider<SessionDayKeyService>(
          create: (_) => getIt<SessionDayKeyService>(),
        ),
        Provider<SessionSharedDataService>(
          create: (_) => getIt<SessionSharedDataService>(),
        ),
        Provider<DemoModeService>(create: (_) => getIt<DemoModeService>()),
        Provider<DemoDataProvider>(create: (_) => getIt<DemoDataProvider>()),
        Provider<MyDayRepositoryContract>(
          create: (_) => getIt<MyDayRepositoryContract>(),
        ),
        Provider<TaskSuggestionService>(
          create: (_) => getIt<TaskSuggestionService>(),
        ),
        Provider<MyDaySessionQueryService>(
          create: (_) => getIt<MyDaySessionQueryService>(),
        ),
        Provider<MyDayGateQueryService>(
          create: (_) => getIt<MyDayGateQueryService>(),
        ),
        Provider<AnytimeSessionQueryService>(
          create: (_) => getIt<AnytimeSessionQueryService>(),
        ),
        Provider<ScheduledOccurrencesService>(
          create: (_) => getIt<ScheduledOccurrencesService>(),
        ),
        Provider<OccurrenceReadService>(
          create: (_) => getIt<OccurrenceReadService>(),
        ),
        Provider<AnalyticsService>(create: (_) => getIt<AnalyticsService>()),
        Provider<AttentionEngineContract>(
          create: (_) => getIt<AttentionEngineContract>(),
        ),
        Provider<TemplateDataService>(
          create: (_) => getIt<TemplateDataService>(),
        ),
        Provider<UserDataWipeService>(
          create: (_) => getIt<UserDataWipeService>(),
        ),
        Provider<SettingsRepositoryContract>(
          create: (_) => getIt<SettingsRepositoryContract>(),
        ),
        Provider<TaskRepositoryContract>(
          create: (_) => getIt<TaskRepositoryContract>(),
        ),
        Provider<ProjectRepositoryContract>(
          create: (_) => getIt<ProjectRepositoryContract>(),
        ),
        Provider<ProjectNextActionsRepositoryContract>(
          create: (_) => getIt<ProjectNextActionsRepositoryContract>(),
        ),
        Provider<ProjectAnchorStateRepositoryContract>(
          create: (_) => getIt<ProjectAnchorStateRepositoryContract>(),
        ),
        Provider<ValueRepositoryContract>(
          create: (_) => getIt<ValueRepositoryContract>(),
        ),
        Provider<ValueRatingsRepositoryContract>(
          create: (_) => getIt<ValueRatingsRepositoryContract>(),
        ),
        Provider<RoutineRepositoryContract>(
          create: (_) => getIt<RoutineRepositoryContract>(),
        ),
        Provider<JournalRepositoryContract>(
          create: (_) => getIt<JournalRepositoryContract>(),
        ),
        Provider<AuthenticatedAppServicesCoordinator>(
          create: (_) => getIt<AuthenticatedAppServicesCoordinator>(),
        ),
        Provider<PresentationSessionServicesCoordinator>(
          create: (_) => getIt<PresentationSessionServicesCoordinator>(),
        ),
        Provider<InitialSyncService>(
          create: (_) => getIt<InitialSyncService>(),
        ),
        Provider<PendingNotificationsProcessor>(
          create: (_) => getIt<PendingNotificationsProcessor>(),
        ),
        Provider<SyncAnomalyStream>(create: (_) => getIt<SyncAnomalyStream>()),
        Provider<TaskWriteService>(create: (_) => getIt<TaskWriteService>()),
        Provider<ProjectWriteService>(
          create: (_) => getIt<ProjectWriteService>(),
        ),
        Provider<ValueWriteService>(create: (_) => getIt<ValueWriteService>()),
        Provider<ValueRatingsWriteService>(
          create: (_) => getIt<ValueRatingsWriteService>(),
        ),
          Provider<RoutineWriteService>(
            create: (_) => getIt<RoutineWriteService>(),
          ),
          Provider<EditorLauncher>(
            create: (_) => EditorLauncher(
              errorReporter: App.errorReporter,
              demoModeService: getIt<DemoModeService>(),
              demoDataProvider: getIt<DemoDataProvider>(),
              taskRepository: getIt<TaskRepositoryContract>(),
              projectRepository: getIt<ProjectRepositoryContract>(),
              valueRepository: getIt<ValueRepositoryContract>(),
              routineRepository: getIt<RoutineRepositoryContract>(),
            taskWriteService: getIt<TaskWriteService>(),
            projectWriteService: getIt<ProjectWriteService>(),
            valueWriteService: getIt<ValueWriteService>(),
            routineWriteService: getIt<RoutineWriteService>(),
          ),
        ),

        Provider<TileIntentDispatcher>(
          create: (context) => DefaultTileIntentDispatcher(
            sharedDataService: context.read<SessionSharedDataService>(),
            editorLauncher: context.read<EditorLauncher>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<InitialSyncGateBloc>(
            lazy: false,
            create: (context) => InitialSyncGateBloc(
              coordinator: context.read<AuthenticatedAppServicesCoordinator>(),
              initialSyncService: context.read<InitialSyncService>(),
              sharedDataService: context.read<SessionSharedDataService>(),
            )..add(const InitialSyncGateStarted()),
          ),
          BlocProvider<GuidedTourBloc>(
            create: (context) => GuidedTourBloc(
              settingsRepository: context.read<SettingsRepositoryContract>(),
              demoModeService: context.read<DemoModeService>(),
            ),
          ),
          BlocProvider<ScreenActionsBloc>(
            create: (context) => ScreenActionsBloc(
              taskWriteService: context.read<TaskWriteService>(),
              projectWriteService: context.read<ProjectWriteService>(),
              valueWriteService: context.read<ValueWriteService>(),
              errorReporter: context.read<AppErrorReporter>(),
            ),
          ),
          BlocProvider<SyncAnomalyBloc>(
            lazy: false,
            create: (context) => SyncAnomalyBloc(
              source: context.read<SyncAnomalyStream>(),
            ),
          ),
        ],
        child: BlocBuilder<GlobalSettingsBloc, GlobalSettingsState>(
          builder: (context, state) {
            final settings = state.settings;
            return BlocBuilder<InitialSyncGateBloc, InitialSyncGateState>(
              builder: (context, gateState) {
                final commonLocale = settings.localeCode == null
                    ? null
                    : Locale(settings.localeCode!);

                final commonTheme = AppTheme.lightTheme(
                  seedColor: state.seedColor,
                );
                final commonDarkTheme = AppTheme.darkTheme(
                  seedColor: state.seedColor,
                );

                final shouldBlockOnSync = switch (gateState) {
                  InitialSyncGateReady() => false,
                  InitialSyncGateFailure() => true,
                  InitialSyncGateInProgress(:final progress) =>
                    !(progress?.hasSynced ?? false) &&
                        progress?.lastSyncedAt == null,
                };

                const debugBootstrapEnabled =
                    kDebugMode && DebugBootstrapFlags.enableDebugBootstrapModal;

                if (shouldBlockOnSync) {
                  return MaterialApp(
                    navigatorKey: App.navigatorKey,
                    scaffoldMessengerKey: App.scaffoldMessengerKey,
                    theme: commonTheme,
                    darkTheme: commonDarkTheme,
                    themeMode: state.flutterThemeMode,
                    locale: commonLocale,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    debugShowCheckedModeBanner: false,
                    home: MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: TextScaler.linear(
                          settings.textScaleFactor,
                        ),
                      ),
                      child: const InitialSyncGateScreen(),
                    ),
                  );
                }

                return MaterialApp.router(
                  scaffoldMessengerKey: App.scaffoldMessengerKey,
                  theme: commonTheme,
                  darkTheme: commonDarkTheme,
                  themeMode: state.flutterThemeMode,
                  locale: commonLocale,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  routerConfig: createRouter(
                    forceOnboarding: !state.settings.onboardingCompleted,
                    navigatorKey: App.navigatorKey,
                  ),
                  debugShowCheckedModeBanner: false,
                  builder: (context, child) {
                    final wrapped = _SyncAnomalySnackBarListener(
                      scaffoldMessengerKey: App.scaffoldMessengerKey,
                      child: _ScreenActionsFailureSnackBarListener(
                        scaffoldMessengerKey: App.scaffoldMessengerKey,
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(
                              settings.textScaleFactor,
                            ),
                          ),
                          child: _NotificationsBootstrapper(child: child!),
                        ),
                      ),
                    );

                    return _DebugBootstrapper(
                      enabled: debugBootstrapEnabled,
                      child: wrapped,
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DebugBootstrapper extends StatefulWidget {
  const _DebugBootstrapper({
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  State<_DebugBootstrapper> createState() => _DebugBootstrapperState();
}

class _DebugBootstrapperState extends State<_DebugBootstrapper> {
  static bool _shownThisSession = false;
  bool _showing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShow();
  }

  @override
  void didUpdateWidget(covariant _DebugBootstrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _maybeShow();
    }
  }

  void _maybeShow() {
    talker.debug(
      '[debug_bootstrap] maybeShow enabled=${widget.enabled} shown=$_shownThisSession showing=$_showing mounted=$mounted',
    );
    if (!widget.enabled || _shownThisSession || _showing) return;
    _showing = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        talker.debug('[debug_bootstrap] postFrame skipped (unmounted)');
        _showing = false;
        return;
      }

      final navigatorState = App.navigatorKey.currentState;
      final navigatorContext =
          navigatorState?.overlay?.context ?? App.navigatorKey.currentContext;
      if (navigatorContext == null) {
        talker.debug('[debug_bootstrap] no navigator context yet');
        _showing = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
        return;
      }

      talker.debug('[debug_bootstrap] presenting modal');
      _shownThisSession = true;

      await showModalBottomSheet<void>(
        context: navigatorContext,
        useRootNavigator: true,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (sheetContext) {
          return BlocProvider(
            create: (context) => DebugBootstrapBloc(
              templateDataService: context.read<TemplateDataService>(),
              userDataWipeService: context.read<UserDataWipeService>(),
              authRepository: context.read<AuthRepositoryContract>(),
              settingsRepository: context.read<SettingsRepositoryContract>(),
            ),
            child: const DebugBootstrapSheet(),
          );
        },
      );

      if (!mounted) return;
      _showing = false;
      talker.debug('[debug_bootstrap] modal closed');
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SyncAnomalySnackBarListener extends StatefulWidget {
  const _SyncAnomalySnackBarListener({
    required this.scaffoldMessengerKey,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  @override
  State<_SyncAnomalySnackBarListener> createState() =>
      _SyncAnomalySnackBarListenerState();
}

class _SyncAnomalySnackBarListenerState
    extends State<_SyncAnomalySnackBarListener> {
  final Stopwatch _dedupeClock = Stopwatch()..start();
  Duration? _lastShownAt;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SyncAnomalyBloc, SyncAnomalyState>(
      listenWhen: (previous, current) => previous.sequence != current.sequence,
      listener: (context, state) {
        if (!kDebugMode) return;

        final anomaly = state.lastAnomaly;
        if (anomaly == null) return;

        final now = _dedupeClock.elapsed;
        final last = _lastShownAt;
        if (last != null && (now - last) < const Duration(seconds: 2)) {
          return;
        }
        _lastShownAt = now;

        final messenger = widget.scaffoldMessengerKey.currentState;
        if (messenger == null) return;

        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Sync anomaly: ${anomaly.debugSummary()}'),
              duration: const Duration(seconds: 4),
            ),
          );
      },
      child: widget.child,
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
      listenWhen: (previous, current) {
        return current is ScreenActionsFailureState &&
            current.shouldShowSnackBar;
      },
      listener: (context, state) {
        if (state is! ScreenActionsFailureState) return;

        final dedupeKey = _FailureDedupeKey(
          kind: state.failureKind,
          entityType: state.entityType,
          entityId: state.entityId,
        );

        final now = context.read<NowService>().nowLocal();
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
      context.read<PendingNotificationsProcessor>().start();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
