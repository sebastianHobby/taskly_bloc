import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/core/environment/env.dart';
import 'package:taskly_bloc/core/dependency_injection/dependency_injection.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    log('BLOC onCreate(${bloc.runtimeType})', name: 'BlocLifecycle');
  }

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('BLOC onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    log('BLOC onEvent(${bloc.runtimeType}, $event)');
  }

  @override
  void onClose(BlocBase<dynamic> bloc) {
    log('BLOC onClose(${bloc.runtimeType})', name: 'BlocLifecycle');
    super.onClose(bloc);
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('BLOC onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();
  await setupDependencies();

  await _maybeDevAutoLogin();

  // Add cross-flavor configuration here

  runApp(await builder());
}

Future<void> _maybeDevAutoLogin() async {
  if (!kDebugMode) return;

  final supabase = Supabase.instance.client;

  if (supabase.auth.currentSession != null) return;
  if (Env.devUsername.isEmpty || Env.devPassword.isEmpty) return;

  try {
    await supabase.auth.signInWithPassword(
      email: Env.devUsername,
      password: Env.devPassword,
    );
  } catch (error, stackTrace) {
    log('Dev auto-login failed', error: error, stackTrace: stackTrace);
  }
}
