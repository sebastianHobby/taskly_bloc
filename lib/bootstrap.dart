import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/env/env.dart';
import 'package:taskly_bloc/presentation/routing/routing.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/presentation/features/projects/view/project_detail_unified_page.dart';
import 'package:taskly_bloc/presentation/features/tasks/view/task_editor_route_page.dart';
import 'package:taskly_bloc/presentation/features/values/view/value_detail_unified_page.dart';

DateTime? _lastDebugDumpAt;
String? _lastDebugDumpSignature;

const _debugDumpThrottleWindow = Duration(seconds: 5);

String _captureDebugPrintOutput(void Function() action) {
  final buffer = StringBuffer();
  final previousDebugPrint = debugPrint;

  debugPrint = (String? message, {int? wrapWidth}) {
    if (message == null) return;
    buffer.writeln(message);
    previousDebugPrint(message, wrapWidth: wrapWidth);
  };

  try {
    action();
  } catch (e, s) {
    buffer
      ..writeln('--- debug dump threw ---')
      ..writeln(e)
      ..writeln(s);
  } finally {
    debugPrint = previousDebugPrint;
  }

  return buffer.toString();
}

String _truncateForLog(String text, {int maxChars = 120000}) {
  if (text.length <= maxChars) return text;

  const headChars = 90000;
  const tailChars = 25000;
  final head = text.substring(0, headChars);
  final tail = text.substring(text.length - tailChars);
  return '$head\n\n--- TRUNCATED (${text.length} chars total) ---\n\n$tail';
}

void _maybeDumpDebugTreesToTalker({
  required String source,
  required String signature,
  required String routeSummary,
}) {
  if (!kDebugMode) return;

  final now = DateTime.now();
  final shouldThrottle =
      _lastDebugDumpAt != null &&
      _lastDebugDumpSignature == signature &&
      now.difference(_lastDebugDumpAt!) < _debugDumpThrottleWindow;

  if (shouldThrottle) return;

  _lastDebugDumpAt = now;
  _lastDebugDumpSignature = signature;

  final appDump = _captureDebugPrintOutput(debugDumpApp);
  talker.warning(
    _truncateForLog(
      '--- debugDumpApp ($source) ---\nroute: $routeSummary\n\n$appDump',
    ),
  );

  // Post-frame dump is usually more reliable for constraint/size issues.
  try {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final renderDump = _captureDebugPrintOutput(debugDumpRenderTree);
      talker.warning(
        _truncateForLog(
          '--- debugDumpRenderTree ($source, post-frame) ---\n'
          'route: $routeSummary\n\n$renderDump',
        ),
      );
    });
  } catch (_) {
    // If bindings aren't available for some reason, fall back to immediate.
    final renderDump = _captureDebugPrintOutput(debugDumpRenderTree);
    talker.warning(
      _truncateForLog(
        '--- debugDumpRenderTree ($source, immediate) ---\n'
        'route: $routeSummary\n\n$renderDump',
      ),
    );
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // Required by package:logging if we want to adjust levels on non-root loggers.
  // Without this, `Logger('PowerSync').level = ...` throws at runtime.
  hierarchicalLoggingEnabled = true;

  // Initialize Talker logging system first (outside zone so it's always available)
  // Note: File logging observer defers initialization until first log to ensure bindings ready
  initializeLogging();

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
        final routeSummary = appRouteObserver.currentRouteSummary;
        final signature =
            'FlutterError:${details.exceptionAsString()}|route:$routeSummary';

        final message = StringBuffer()
          ..writeln('Flutter framework error: ${details.exceptionAsString()}')
          ..writeln('route: $routeSummary')
          ..writeln('library: ${details.library ?? "<null>"}')
          ..writeln('context: ${details.context ?? "<null>"}')
          ..writeln('silent: ${details.silent}')
          ..writeln('--- FlutterErrorDetails ---')
          ..writeln(details.toString());

        talker.handle(
          details.exception,
          details.stack,
          message.toString(),
        );

        _maybeDumpDebugTreesToTalker(
          source: 'FlutterError.onError',
          signature: signature,
          routeSummary: routeSummary,
        );
      };

      // Capture errors outside of Flutter that escape the zone
      PlatformDispatcher.instance.onError = (error, stack) {
        final routeSummary = appRouteObserver.currentRouteSummary;
        talker.handle(
          error,
          stack,
          'Uncaught platform error\nroute: $routeSummary',
        );

        _maybeDumpDebugTreesToTalker(
          source: 'PlatformDispatcher.onError',
          signature: 'PlatformError:$error|route:$routeSummary',
          routeSummary: routeSummary,
        );
        return !talker.failFastPolicy.enabled;
      };

      // Use TalkerBlocObserver for unified BLoC logging
      Bloc.observer = TalkerBlocObserver(
        talker: talkerRaw,
        settings: TalkerBlocLoggerSettings(
          printCreations: kDebugMode,
          printClosings: kDebugMode,
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

        // Establish a fixed "home" day boundary for day-keyed features.
        final dayKeyService = getIt<HomeDayKeyService>();
        await dayKeyService.ensureInitialized();
        dayKeyService.start();

        // Lifecycle + time-based triggers (e.g., home-day rollover).
        getIt<AppLifecycleService>().start();
        getIt<TemporalTriggerService>().start();

        // In-app invalidation pulses for time-based attention sections.
        getIt<AttentionTemporalInvalidationService>().start();

        // Prewarm common attention queries so Inbox/banners render instantly.
        getIt<AttentionPrewarmService>().start();

        // Centralized trigger coordinator for keeping today's allocation
        // snapshot generated and refreshed (debounced, no reshuffle policy).
        getIt<AllocationSnapshotCoordinator>().start();

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
      final routeSummary = appRouteObserver.currentRouteSummary;
      talker.handle(
        error,
        stack,
        'Uncaught zone error\nroute: $routeSummary',
      );

      _maybeDumpDebugTreesToTalker(
        source: 'runZonedGuarded',
        signature: 'ZoneError:$error|route:$routeSummary',
        routeSummary: routeSummary,
      );
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

  final authRepo = getIt<AuthRepositoryContract>();

  if (authRepo.currentSession != null) {
    talker.debug('[auth] Already authenticated, skipping dev auto-login');
    return;
  }

  if (Env.devUsername.isEmpty || Env.devPassword.isEmpty) {
    talker.debug('[auth] Dev credentials not configured, skipping auto-login');
    return;
  }

  try {
    talker.info('[auth] Attempting dev auto-login...');
    await authRepo.signInWithPassword(
      email: Env.devUsername,
      password: Env.devPassword,
    );
    talker.info('[auth] Dev auto-login successful');
  } catch (error, stackTrace) {
    talker.handle(error, stackTrace, 'Dev auto-login failed');
  }
}

/// Register entity builders with [Routing].
///
/// System screens are resolved by [Routing.buildScreen] via `SystemScreenSpecs`.
/// Entity detail routes are resolved via registered builders.
void _registerRoutingBuilders() {
  // Register entity detail builders
  Routing.registerEntityBuilders(
    taskBuilder: (id) => TaskEditorRoutePage(taskId: id),
    valueBuilder: (id) => ValueDetailUnifiedPage(valueId: id),
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
  // Set level for PowerSync logs only.
  //
  // Default: INFO (useful sync activity, low noise)
  // Opt-in: FINE via --dart-define=POWERSYNC_VERBOSE_LOGS=true
  const powersyncVerbose = bool.fromEnvironment('POWERSYNC_VERBOSE_LOGS');
  Logger('PowerSync').level = (kDebugMode && powersyncVerbose)
      ? Level.FINE
      : Level.INFO;

  Logger.root.onRecord.listen((record) {
    // Only process PowerSync logs (not other logging package users)
    if (!record.loggerName.contains('PowerSync')) {
      return;
    }

    // Map logging levels to Talker methods
    final message =
        '[${record.loggerName}] ${record.level.name}: ${record.message}';

    // Persist a narrow slice of sync activity to the debug file log.
    // This helps correlate settings writes with PowerSync upload/download.
    final isSettingsSyncSignal =
        record.message.contains('user_profiles') ||
        record.message.contains('ps_crud');

    if (record.level >= Level.SEVERE) {
      talker.error(message, record.error, record.stackTrace);
    } else if (record.level >= Level.WARNING) {
      talker.warning(message);
    } else if (record.level >= Level.INFO) {
      if (isSettingsSyncSignal) {
        talker.warning(message);
      } else {
        talker.info(message);
      }
    } else {
      // FINE, FINER, FINEST -> debug
      talker.debug(message);
    }
  });
}
