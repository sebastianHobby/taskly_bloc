import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
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

  // Wrap everything in runZonedGuarded to catch uncaught async errors
  // ignore: unawaited_futures
  runZonedGuarded(
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

      talker.info('Initializing dependencies...');
      await setupDependencies();
      talker.info('Dependencies initialized successfully');

      await _maybeDevAutoLogin();

      // Add cross-flavor configuration here

      talker.info('Starting application...');
      talker.debug('>>> bootstrap: calling runApp()...');
      runApp(await builder());
      talker.debug('<<< bootstrap: runApp() returned');
    },
    // Zone error handler - catches any async errors that escape try/catch blocks
    (error, stack) {
      talker.handle(error, stack, 'Uncaught zone error');
    },
  );
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
