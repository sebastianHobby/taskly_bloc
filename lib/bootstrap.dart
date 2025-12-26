import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';
import 'package:taskly_bloc/core/environment/env.dart';
import 'package:taskly_bloc/core/utils/app_logger.dart';

/// BLoC observer that logs all BLoC lifecycle events and errors.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  static final _logger = AppLogger('bloc.observer');

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    _logger.debug('onCreate: ${bloc.runtimeType}');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      _logger.trace('onChange: ${bloc.runtimeType} - $change');
    }
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    _logger.debug('onEvent: ${bloc.runtimeType} - $event');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    _logger.debug('onClose: ${bloc.runtimeType}');
    super.onClose(bloc);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    _logger.error(
      'BLoC Error in ${bloc.runtimeType}',
      error,
      stackTrace,
    );
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  // Initialize logging system
  AppLogger.initialize(
    minimumLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
  );

  final logger = AppLogger('app.bootstrap');

  // Capture Flutter framework errors
  FlutterError.onError = (details) {
    logger.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );
  };

  // Capture errors outside of Flutter (async errors)
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.critical('Uncaught platform error', error, stack);
    return true;
  };

  Bloc.observer = const AppBlocObserver();

  logger.info('Initializing dependencies...');
  await setupDependencies();
  logger.info('Dependencies initialized successfully');

  await _maybeDevAutoLogin();

  // Add cross-flavor configuration here

  logger.info('Starting application...');
  runApp(await builder());
}

Future<void> _maybeDevAutoLogin() async {
  if (!kDebugMode) return;

  final logger = AppLogger('app.dev_auth');
  final supabase = Supabase.instance.client;

  if (supabase.auth.currentSession != null) {
    logger.debug('Already authenticated, skipping dev auto-login');
    return;
  }

  if (Env.devUsername.isEmpty || Env.devPassword.isEmpty) {
    logger.debug('Dev credentials not configured, skipping auto-login');
    return;
  }

  try {
    logger.info('Attempting dev auto-login...');
    await supabase.auth.signInWithPassword(
      email: Env.devUsername,
      password: Env.devPassword,
    );
    logger.info('Dev auto-login successful');
  } catch (error, stackTrace) {
    logger.warning('Dev auto-login failed', error, stackTrace);
  }
}
