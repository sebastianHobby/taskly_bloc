import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';
import 'package:taskly_bloc/bootstrap/error_capture.dart';
import 'package:taskly_bloc/bootstrap/logging_bootstrap.dart';
import 'package:taskly_bloc/core/di/dependency_injection.dart';
import 'package:taskly_bloc/core/env/env.dart';
import 'package:taskly_core/logging.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  bootstrapLogging();

  await runWithBootstrapErrorCapture(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Trigger the file observer initialization now that bindings are ready
    talker.info('Bootstrap: Bindings initialized, logging ready');

    installGlobalErrorCapture();

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

      // Add cross-flavor configuration here

      talker.info('Starting application...');
      talker.debug('>>> bootstrap: calling runApp()...');
      runApp(await builder());
      talker.debug('<<< bootstrap: runApp() returned');
    } catch (error, stackTrace) {
      talker.handle(error, stackTrace, 'Bootstrap failed before runApp()');
      runApp(_BootstrapFailureApp(error: error, stackTrace: stackTrace));
    }
  });
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
