import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/environment/env.dart';
import 'package:taskly_bloc/core/routing/routing.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/models/screens/system_screen_definitions.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/presentation/features/navigation/view/navigation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/next_action/view/allocation_settings_page.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_detail_unified_page.dart';
import 'package:taskly_bloc/presentation/features/screens/view/screen_management_page.dart';
import 'package:taskly_bloc/presentation/features/settings/view/settings_screen.dart';
import 'package:taskly_bloc/presentation/features/tasks/bloc/task_detail_bloc.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_detail_view.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/journal_entry/journal_entry_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/tracker_management/tracker_management_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/bloc/wellbeing_dashboard/wellbeing_dashboard_bloc.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/journal_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/tracker_management_screen.dart';
import 'package:taskly_bloc/presentation/features/wellbeing/view/wellbeing_dashboard_screen.dart';
import 'package:taskly_bloc/presentation/features/workflow/view/workflow_list_page.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // Initialize Talker logging system first (outside zone so it's always available)
  // Note: File logging observer defers initialization until first log to ensure bindings ready
  initializeTalker();

  // Set up PowerSync logging integration
  // PowerSync uses Dart's logging package - forward logs to Talker
  _setupPowerSyncLogging();

  // Wrap everything in runZonedGuarded to catch uncaught async errors.
  await runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Trigger the file observer initialization now that bindings are ready
      talker.info('Bootstrap: Bindings initialized, logging ready');

      // Capture Flutter framework errors (widget build failures, layout errors)
      FlutterError.onError = (details) {
        talker.handle(
          details.exception,
          details.stack,
          'Flutter framework error: ${details.exceptionAsString()}',
        );
      };

      // Capture errors outside of Flutter that escape the zone
      PlatformDispatcher.instance.onError = (error, stack) {
        talker.handle(error, stack, 'Uncaught platform error');
        return true;
      };

      // Use TalkerBlocObserver for unified BLoC logging
      Bloc.observer = TalkerBlocObserver(
        talker: talker,
        settings: TalkerBlocLoggerSettings(
          printCreations: true,
          printClosings: true,
          printTransitions: false, // Reduce noise, events are sufficient
          printChanges: kDebugMode,
          printEventFullData: false, // Truncate for cleaner logs
          printStateFullData: false,
        ),
      );

      try {
        // Load environment configuration
        talker.debug('Loading environment configuration...');
        await Env.load();
        Env.logDiagnostics();
        Env.validateRequired();
        talker.debug('Environment configuration loaded');

        talker.info('Initializing dependencies...');
        await setupDependencies();
        talker.info('Dependencies initialized successfully');

        // Register screen and entity builders with Routing
        _registerRoutingBuilders();
        talker.debug('Routing builders registered');

        await _maybeDevAutoLogin();

        // Add cross-flavor configuration here

        talker.info('Starting application...');
        talker.debug('>>> bootstrap: calling runApp()...');
        runApp(await builder());
        talker.debug('<<< bootstrap: runApp() returned');
      } catch (error, stackTrace) {
        talker.handle(error, stackTrace, 'Bootstrap failed before runApp()');
        runApp(_BootstrapFailureApp(error: error, stackTrace: stackTrace));
      }
    },
    // Zone error handler - catches any async errors that escape try/catch blocks
    (error, stack) {
      talker.handle(error, stack, 'Uncaught zone error');
    },
  );
}

class _BootstrapFailureApp extends StatelessWidget {
  const _BootstrapFailureApp({
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: SelectionArea(
                child: Text(
                  'App failed to start.\n\n'
                  'Error: $error\n\n'
                  'Hints:\n'
                  '- Web (Chrome) cannot read .env; use --dart-define or '
                  '--dart-define-from-file=dart_defines.json\n'
                  '- Desktop/mobile debug can use .env (see ENVIRONMENT_SETUP.md)\n\n'
                  'StackTrace:\n$stackTrace',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _maybeDevAutoLogin() async {
  if (!kDebugMode) return;

  final supabase = Supabase.instance.client;

  if (supabase.auth.currentSession != null) {
    talker.debug('[auth] Already authenticated, skipping dev auto-login');
    return;
  }

  if (Env.devUsername.isEmpty || Env.devPassword.isEmpty) {
    talker.debug('[auth] Dev credentials not configured, skipping auto-login');
    return;
  }

  try {
    talker.info('[auth] Attempting dev auto-login...');
    await supabase.auth.signInWithPassword(
      email: Env.devUsername,
      password: Env.devPassword,
    );
    talker.info('[auth] Dev auto-login successful');
  } catch (error, stackTrace) {
    talker.handle(error, stackTrace, 'Dev auto-login failed');
  }
}

/// Register screen and entity builders with [Routing].
///
/// This centralizes all screen→bloc mappings. Screens not registered here
/// automatically use [UnifiedScreenPage] for convention-based rendering.
void _registerRoutingBuilders() {
  final wellbeingRepo = getIt<WellbeingRepositoryContract>();
  final analyticsService = getIt<AnalyticsService>();
  final settingsRepo = getIt<SettingsRepositoryContract>();
  final screensRepo = getIt<ScreenDefinitionsRepositoryContract>();
  final authRepo = getIt<AuthRepositoryContract>();
  final taskRepo = getIt<TaskRepositoryContract>();
  final projectRepo = getIt<ProjectRepositoryContract>();

  // Register custom screen builders (screens that need specific blocs or DI)
  // Keys reference SystemScreenDefinitions to prevent drift if screenKey changes.
  Routing.registerScreenBuilders({
    // Wellbeing screens with custom blocs
    SystemScreenDefinitions.journal.screenKey: () => BlocProvider(
      create: (_) => JournalEntryBloc(wellbeingRepo),
      child: const JournalScreen(),
    ),
    SystemScreenDefinitions.trackers.screenKey: () => BlocProvider(
      create: (_) => TrackerManagementBloc(wellbeingRepo),
      child: const TrackerManagementScreen(),
    ),
    SystemScreenDefinitions.wellbeingDashboard.screenKey: () => BlocProvider(
      create: (_) => WellbeingDashboardBloc(analyticsService),
      child: const WellbeingDashboardScreen(),
    ),

    // Settings-related screens with DI
    SystemScreenDefinitions.settings.screenKey: () => const SettingsScreen(),
    SystemScreenDefinitions.allocationSettings.screenKey: () =>
        AllocationSettingsPage(
          settingsRepository: settingsRepo,
        ),
    SystemScreenDefinitions.navigationSettings.screenKey: () =>
        NavigationSettingsPage(screensRepository: screensRepo),
    SystemScreenDefinitions.screenManagement.screenKey: () =>
        ScreenManagementPage(userId: authRepo.currentUser!.id),
    SystemScreenDefinitions.workflows.screenKey: () =>
        WorkflowListPage(userId: authRepo.currentUser!.id),
  });

  // Register entity detail builders
  Routing.registerEntityBuilders(
    taskBuilder: (id) => BlocProvider(
      create: (_) => TaskDetailBloc(
        taskId: id,
        taskRepository: taskRepo,
        projectRepository: projectRepo,
      ),
      child: const TaskDetailSheet(),
    ),
    projectBuilder: (id) => ProjectDetailUnifiedPage(projectId: id),
  );
}

/// Set up PowerSync logging integration.
///
/// PowerSync SDK uses Dart's `logging` package. By listening to
/// `Logger.root.onRecord`, we can forward all PowerSync logs to Talker.
///
/// This enables:
/// - Sync status visibility in Talker console/file
/// - Debug logs showing what PowerSync is doing during sync
/// - Error tracking for sync failures
void _setupPowerSyncLogging() {
  // Set level for PowerSync logger - INFO shows sync activity, FINE for details
  Logger.root.level = kDebugMode ? Level.FINE : Level.INFO;

  Logger.root.onRecord.listen((record) {
    // Only process PowerSync logs (not other logging package users)
    if (!record.loggerName.contains('PowerSync')) {
      return;
    }

    // Map logging levels to Talker methods
    final message =
        '[${record.loggerName}] ${record.level.name}: ${record.message}';

    if (record.level >= Level.SEVERE) {
      talker.error(message, record.error, record.stackTrace);
    } else if (record.level >= Level.WARNING) {
      talker.warning(message);
    } else if (record.level >= Level.INFO) {
      talker.info(message);
    } else {
      // FINE, FINER, FINEST -> debug
      talker.debug(message);
    }
  });
}
