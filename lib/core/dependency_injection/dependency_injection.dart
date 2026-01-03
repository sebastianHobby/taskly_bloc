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
import 'package:taskly_bloc/data/features/screens/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/data/features/workflow/repositories/workflow_repository_impl.dart';
import 'package:taskly_bloc/data/services/user_data_seeder.dart';
import 'package:taskly_bloc/data/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_bloc/data/features/notifications/services/logging_notification_presenter.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/interfaces/analytics_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/pending_notifications_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/user_data_seeder_contract.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/services/screens/entity_grouper.dart';
import 'package:taskly_bloc/domain/services/screens/trigger_evaluator.dart';
import 'package:taskly_bloc/domain/services/screens/support_block_computer.dart';
import 'package:taskly_bloc/domain/services/workflow/workflow_service.dart';
import 'package:taskly_bloc/domain/services/workflow/problem_detector_service.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';
import 'package:taskly_bloc/domain/services/notifications/pending_notifications_processor.dart';
import 'package:taskly_bloc/domain/services/notifications/notification_presenter.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';

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
    ..registerSingleton<PowerSyncDatabase>(syncDb)
    ..registerSingleton<AppDatabase>(appDatabase)
    ..registerLazySingleton<SupabaseClient>(
      () => Supabase.instance.client,
    )
    ..registerLazySingleton<AuthRepositoryContract>(
      () => AuthRepository(client: getIt<SupabaseClient>()),
    )
    // IdGenerator - uses lazy userId getter from session
    // The userId is only evaluated when actually generating IDs,
    // allowing repositories to be constructed before authentication
    ..registerLazySingleton<IdGenerator>(
      () => IdGenerator(() {
        final userId = getUserId();
        if (userId == null) {
          throw StateError('IdGenerator requires authenticated user');
        }
        return userId;
      }),
    )
    // Register occurrence stream expander for reading occurrences
    ..registerLazySingleton<OccurrenceStreamExpanderContract>(
      OccurrenceStreamExpander.new,
    )
    // Register occurrence write helper for writing occurrences
    ..registerLazySingleton<OccurrenceWriteHelperContract>(
      () => OccurrenceWriteHelper(
        driftDb: getIt<AppDatabase>(),
        idGenerator: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<ProjectRepositoryContract>(
      () => ProjectRepository(
        driftDb: getIt<AppDatabase>(),
        occurrenceExpander: getIt<OccurrenceStreamExpanderContract>(),
        occurrenceWriteHelper: getIt<OccurrenceWriteHelperContract>(),
        idGenerator: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<TaskRepositoryContract>(
      () => TaskRepository(
        driftDb: getIt<AppDatabase>(),
        occurrenceExpander: getIt<OccurrenceStreamExpanderContract>(),
        occurrenceWriteHelper: getIt<OccurrenceWriteHelperContract>(),
        idGenerator: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<LabelRepositoryContract>(
      () => LabelRepository(
        driftDb: getIt<AppDatabase>(),
        idGenerator: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<SettingsRepositoryContract>(
      () => SettingsRepository(driftDb: getIt<AppDatabase>()),
    )
    // Screens - thin wrapper over database implementation
    ..registerLazySingleton<ScreenDefinitionsRepositoryContract>(
      () => ScreenDefinitionsRepository(
        databaseRepository: ScreenDefinitionsRepositoryImpl(
          getIt<AppDatabase>(),
          getIt<IdGenerator>(),
        ),
      ),
    )
    // User data seeding service
    ..registerLazySingleton<UserDataSeederContract>(
      () => UserDataSeeder(
        labelRepository: getIt<LabelRepositoryContract>(),
        screenRepository: getIt<ScreenDefinitionsRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<AllocationOrchestrator>(
      () => AllocationOrchestrator(
        taskRepository: getIt<TaskRepositoryContract>(),
        labelRepository: getIt<LabelRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        analyticsService: getIt<AnalyticsService>(),
      ),
    )
    ..registerLazySingleton<SectionDataService>(
      () => SectionDataService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        labelRepository: getIt<LabelRepositoryContract>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
      ),
    )
    // Analytics
    ..registerLazySingleton<AnalyticsRepositoryContract>(
      () => AnalyticsRepositoryImpl(
        getIt<AppDatabase>(),
        getIt<IdGenerator>(),
      ),
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
      () => WellbeingRepositoryImpl(
        getIt<AppDatabase>(),
        getIt<IdGenerator>(),
      ),
    )
    // New workflow system
    ..registerLazySingleton<WorkflowRepositoryContract>(
      () => WorkflowRepositoryImpl(
        getIt<AppDatabase>(),
        getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<ScreenQueryBuilder>(ScreenQueryBuilder.new)
    ..registerLazySingleton<EntityGrouper>(EntityGrouper.new)
    ..registerLazySingleton<TriggerEvaluator>(TriggerEvaluator.new)
    ..registerLazySingleton<TaskStatsCalculator>(TaskStatsCalculator.new)
    ..registerLazySingleton<SupportBlockComputer>(
      () => SupportBlockComputer(
        statsCalculator: getIt<TaskStatsCalculator>(),
        analyticsService: getIt<AnalyticsService>(),
        problemDetectorService: getIt<ProblemDetectorService>(),
      ),
    )
    // ScreenDataInterpreter - coordinates section data and support blocks
    ..registerLazySingleton<ScreenDataInterpreter>(
      () => ScreenDataInterpreter(
        sectionDataService: getIt<SectionDataService>(),
        supportBlockComputer: getIt<SupportBlockComputer>(),
      ),
    )
    // EntityActionService - performs actions on entities from screens
    ..registerLazySingleton<EntityActionService>(
      () => EntityActionService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
      ),
    )
    // Screen architecture services
    ..registerLazySingleton<ProblemDetectorService>(
      () => ProblemDetectorService(
        settingsRepository: getIt<SettingsRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<WorkflowService>(
      () => WorkflowService(
        workflowRepository: getIt<WorkflowRepositoryContract>(),
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
