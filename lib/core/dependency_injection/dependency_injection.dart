// Todo setup get it / work out how to handle DI simply/effectively
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:get_it/get_it.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/core/environment/env.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/powersync/api_connector.dart';
import 'package:taskly_bloc/data/repositories/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/data/repositories/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/data/repositories/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/data/repositories/contracts/value_repository_contract.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/data/supabase/supabase.dart';

final GetIt getIt = GetIt.instance;

// Register all the classes you want to inject
Future<void> setupDependencies() async {
  // Load supabase and powersync before registering dependencies
  await loadSupabase();
  final PowerSyncDatabase syncDb = await openDatabase();

  //Define here as a global.
  final supabase = Supabase.instance.client;
  if (kDebugMode &&
      (supabase.auth.currentSession == null) &&
      Env.devUsername.isNotEmpty &&
      Env.devPassword.isNotEmpty) {
    await supabase.auth.signInWithPassword(
      email: Env.devUsername,
      password: Env.devPassword,
    );
  }

  // db variable is set by the openDatabase function. Someday improve this
  // so it's not a global variable ...

  // Create and register the Drift AppDatabase backed by the PowerSync DB
  final appDatabase = AppDatabase(
    DatabaseConnection(SqliteAsyncDriftConnection(syncDb)),
  );

  getIt
    ..registerSingleton<AppDatabase>(appDatabase)
    ..registerLazySingleton<ProjectRepositoryContract>(
      () => ProjectRepository(driftDb: getIt<AppDatabase>()),
    )
    ..registerLazySingleton<TaskRepositoryContract>(
      () => TaskRepository(driftDb: getIt<AppDatabase>()),
    )
    ..registerLazySingleton<ValueRepositoryContract>(
      () => ValueRepository(driftDb: getIt<AppDatabase>()),
    )
    ..registerLazySingleton<LabelRepositoryContract>(
      () => LabelRepository(driftDb: getIt<AppDatabase>()),
    );
}
