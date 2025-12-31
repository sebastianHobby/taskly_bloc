/// Dependency injection configuration using GetIt.
library;

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
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/label_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/data/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_bloc/data/features/analytics/services/analytics_service_impl.dart';
import 'package:taskly_bloc/data/features/wellbeing/repositories/wellbeing_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/screen_definitions_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/problem_acknowledgments_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/workflow_item_reviews_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/workflow_sessions_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/services/screen_system_seeder.dart';
import 'package:taskly_bloc/data/services/system_label_seeder.dart';
import 'package:taskly_bloc/data/services/user_data_seeder.dart';
import 'package:taskly_bloc/data/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_bloc/data/features/notifications/services/logging_notification_presenter.dart';
import 'package:taskly_bloc/data/features/priority/repositories/priority_rankings_repository_impl.dart';
import 'package:taskly_bloc/data/features/priority/repositories/allocation_preferences_repository_impl.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/interfaces/analytics_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/pending_notifications_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/problem_acknowledgments_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_item_reviews_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_sessions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/priority_rankings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/allocation_preferences_repository_contract.dart';
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
    // Priority / Allocation (registered before UserDataSeeder since it depends on these)
    ..registerLazySingleton<PriorityRankingsRepositoryContract>(
      () => PriorityRankingsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<AllocationPreferencesRepositoryContract>(
      () => AllocationPreferencesRepositoryImpl(getIt<AppDatabase>()),
    )
    // Screens (registered before UserDataSeeder since it depends on this)
    ..registerLazySingleton<ScreenDefinitionsRepositoryContract>(
      () => ScreenDefinitionsRepositoryImpl(getIt<AppDatabase>()),
    )
    // User data seeding service (seeds screens, labels, and allocation defaults)
    ..registerLazySingleton<UserDataSeeder>(
      () => UserDataSeeder(
        labelRepository: getIt<LabelRepositoryContract>(),
        screenRepository: getIt<ScreenDefinitionsRepositoryContract>(),
        preferencesRepository: getIt<AllocationPreferencesRepositoryContract>(),
        rankingsRepository: getIt<PriorityRankingsRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<AllocationOrchestrator>(
      () => AllocationOrchestrator(
        taskRepository: getIt<TaskRepositoryContract>(),
        labelRepository: getIt<LabelRepositoryContract>(),
        rankingsRepository: getIt<PriorityRankingsRepositoryContract>(),
        preferencesRepository: getIt<AllocationPreferencesRepositoryContract>(),
      ),
    )
    // Analytics
    ..registerLazySingleton<AnalyticsRepositoryContract>(
      () => AnalyticsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<AnalyticsService>(
      () => AnalyticsServiceImpl(
        taskRepo: getIt<TaskRepositoryContract>(),
        projectRepo: getIt<ProjectRepositoryContract>(),
        labelRepo: getIt<LabelRepositoryContract>(),
        wellbeingRepo: getIt<WellbeingRepositoryContract>(),
        analyticsRepo: getIt<AnalyticsRepositoryContract>(),
      ),
    )
    // Wellbeing
    ..registerLazySingleton<WellbeingRepositoryContract>(
      () => WellbeingRepositoryImpl(getIt<AppDatabase>()),
    )
    // Screens (additional screen-related repositories)
    ..registerLazySingleton<WorkflowSessionsRepositoryContract>(
      () => WorkflowSessionsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<WorkflowItemReviewsRepositoryContract>(
      () => WorkflowItemReviewsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerLazySingleton<ProblemAcknowledgmentsRepositoryContract>(
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
    )
    // Notifications (server-enqueued + PowerSync synced)
    ..registerLazySingleton<NotificationPresenter>(
      () => LoggingNotificationPresenter().call,
    )
    ..registerLazySingleton<PendingNotificationsRepositoryContract>(
      () => PendingNotificationsRepositoryImpl(getIt<AppDatabase>()),
    )
    ..registerSingleton<PendingNotificationsProcessor>(
      PendingNotificationsProcessor(
        repository: getIt<PendingNotificationsRepositoryContract>(),
        presenter: getIt<NotificationPresenter>(),
      ),
    );

  // Note: Seeding has been moved to post-authentication flow
  // See UserDataSeeder service triggered by AuthBloc
}
