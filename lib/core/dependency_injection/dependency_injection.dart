// Todo setup get it / work out how to handle DI simply/effectively
import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:get_it/get_it.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/data/services/occurrence_write_helper.dart';
import 'package:taskly_bloc/data/services/occurrence_stream_expander.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/powersync/api_connector.dart';
import 'package:taskly_bloc/data/repositories/auth_repository.dart';
import 'package:taskly_bloc/data/repositories/label_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/supabase/supabase.dart';
import 'package:taskly_bloc/domain/contracts/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/label_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/contracts/project_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/data/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_bloc/data/features/analytics/services/analytics_service_impl.dart';
import 'package:taskly_bloc/data/features/wellbeing/repositories/wellbeing_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/screen_definitions_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/problem_acknowledgments_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/workflow_item_reviews_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/workflow_sessions_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/services/screen_system_seeder.dart';
import 'package:taskly_bloc/data/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_bloc/data/features/notifications/services/logging_notification_presenter.dart';
import 'package:taskly_bloc/domain/repositories/analytics_repository.dart';
import 'package:taskly_bloc/domain/repositories/pending_notifications_repository.dart';
import 'package:taskly_bloc/domain/repositories/problem_acknowledgments_repository.dart';
import 'package:taskly_bloc/domain/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/domain/repositories/wellbeing_repository.dart';
import 'package:taskly_bloc/domain/repositories/workflow_item_reviews_repository.dart';
import 'package:taskly_bloc/domain/repositories/workflow_sessions_repository.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/services/screens/entity_grouper.dart';
import 'package:taskly_bloc/domain/services/screens/trigger_evaluator.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';
import 'package:taskly_bloc/domain/services/notifications/pending_notifications_processor.dart';
import 'package:taskly_bloc/domain/services/notifications/notification_presenter.dart';

final GetIt getIt = GetIt.instance;

// Register all the classes you want to inject
Future<void> setupDependencies() async {
  // Load supabase and powersync before registering dependencies
  await loadSupabase();
  final PowerSyncDatabase syncDb = await openDatabase();

  // db variable is set by the openDatabase function. Someday improve this
  // so it's not a global variable ...

  // Create and register the Drift AppDatabase backed by the PowerSync DB
  final appDatabase = AppDatabase(
    DatabaseConnection(SqliteAsyncDriftConnection(syncDb)),
  );

  getIt
    ..registerSingleton<AppDatabase>(appDatabase)
    ..registerLazySingleton<SupabaseClient>(
      () => Supabase.instance.client,
    )
    ..registerLazySingleton<AuthRepositoryContract>(
      () => AuthRepository(client: getIt<SupabaseClient>()),
    )
    // Register occurrence stream expander for reading occurrences
    ..registerLazySingleton<OccurrenceStreamExpanderContract>(
      OccurrenceStreamExpander.new,
    )
    // Register occurrence write helper for writing occurrences
    ..registerLazySingleton<OccurrenceWriteHelperContract>(
      () => OccurrenceWriteHelper(driftDb: getIt<AppDatabase>()),
    )
    ..registerLazySingleton<ProjectRepositoryContract>(
      () => ProjectRepository(
        driftDb: getIt<AppDatabase>(),
        occurrenceExpander: getIt<OccurrenceStreamExpanderContract>(),
        occurrenceWriteHelper: getIt<OccurrenceWriteHelperContract>(),
      ),
    )
    ..registerLazySingleton<TaskRepositoryContract>(
      () => TaskRepository(
        driftDb: getIt<AppDatabase>(),
        occurrenceExpander: getIt<OccurrenceStreamExpanderContract>(),
        occurrenceWriteHelper: getIt<OccurrenceWriteHelperContract>(),
      ),
    )
    ..registerLazySingleton<LabelRepositoryContract>(
      () => LabelRepository(driftDb: getIt<AppDatabase>()),
    )
    ..registerLazySingleton<SettingsRepositoryContract>(
      () => SettingsRepository(driftDb: getIt<AppDatabase>()),
    )
    // Analytics
    ..registerLazySingleton<AnalyticsRepository>(
      () => AnalyticsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<AnalyticsService>(
      () => AnalyticsServiceImpl(
        taskRepo: getIt<TaskRepositoryContract>(),
        projectRepo: getIt<ProjectRepositoryContract>(),
        labelRepo: getIt<LabelRepositoryContract>(),
        wellbeingRepo: getIt<WellbeingRepository>(),
        analyticsRepo: getIt<AnalyticsRepository>(),
      ),
    )
    // Wellbeing
    ..registerLazySingleton<WellbeingRepository>(
      () => WellbeingRepositoryImpl(getIt<AppDatabase>()),
    )
    // Screens
    ..registerLazySingleton<ScreenDefinitionsRepository>(
      () => ScreenDefinitionsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<WorkflowSessionsRepository>(
      () => WorkflowSessionsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<WorkflowItemReviewsRepository>(
      () => WorkflowItemReviewsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<ProblemAcknowledgmentsRepository>(
      () => ProblemAcknowledgmentsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<ScreenQueryBuilder>(ScreenQueryBuilder.new)
    ..registerLazySingleton<EntityGrouper>(EntityGrouper.new)
    ..registerLazySingleton<TriggerEvaluator>(TriggerEvaluator.new)
    ..registerLazySingleton<TaskStatsCalculator>(TaskStatsCalculator.new)
    ..registerLazySingleton<SupportBlockComputer>(
      () => SupportBlockComputer(
        getIt<TaskStatsCalculator>(),
        getIt<AnalyticsService>(),
      ),
    );

  // Notifications (server-enqueued + PowerSync synced)
  getIt
    ..registerLazySingleton<NotificationPresenter>(
      () => LoggingNotificationPresenter().call,
    )
    ..registerLazySingleton<PendingNotificationsRepository>(
      () => PendingNotificationsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerSingleton<PendingNotificationsProcessor>(
      PendingNotificationsProcessor(
        repository: getIt<PendingNotificationsRepository>(),
        presenter: getIt<NotificationPresenter>(),
      ),
    );

  // Seed required system screens if missing.
  await ScreenSystemSeeder(
    screensRepository: getIt<ScreenDefinitionsRepository>(),
  ).seedDefaults();
}
