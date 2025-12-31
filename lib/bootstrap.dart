import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/environment/env.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // Initialize Talker logging system first (outside zone so it's always available)
  // Note: File logging observer defers initialization until first log to ensure bindings ready
  initializeTalker();

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
