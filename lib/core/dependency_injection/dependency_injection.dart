// Todo setup get it / work out how to handle DI simply/effectively
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/core/environment/env.dart';
import 'package:taskly_bloc/data/powersync/api_connector.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/supabase/supabase.dart';

final GetIt getIt = GetIt.instance;

// Register all the classes you want to inject
Future<void> setupDependencies() async {
  // Load supabase and powersync before registering dependencies
  await loadSupabase();
  await openDatabase();

  //Define here as a global.
  final supabase = Supabase.instance.client;
  //Todo remove this login once auth is implemented
  await supabase.auth.signInWithPassword(
    email: Env.devUsername,
    password: Env.devPassword,
  );

  // db variable is set by the openDatabase function. Someday improve this
  // so it's not a global variable ...
  getIt
    ..registerLazySingleton<ProjectRepository>(
      () => ProjectRepository(syncDb: db),
    )
    ..registerLazySingleton<TaskRepository>(
      () => TaskRepository(syncDb: db),
    );
}
