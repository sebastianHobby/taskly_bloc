/// Dependency injection configuration using GetIt.
library;

import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:get_it/get_it.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_bloc/data/services/occurrence_write_helper.dart';
import 'package:taskly_bloc/data/services/occurrence_stream_expander.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/infrastructure/powersync/api_connector.dart';
import 'package:taskly_bloc/data/repositories/auth_repository.dart';
import 'package:taskly_bloc/data/allocation/repositories/allocation_snapshot_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/data/infrastructure/supabase/supabase.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/allocation/contracts/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/data/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_bloc/data/features/analytics/services/analytics_service_impl.dart';
import 'package:taskly_bloc/data/features/journal/repositories/journal_repository_impl.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_definitions_repository_impl.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/data/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_bloc/data/features/notifications/services/logging_notification_presenter.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/allocation/engine/allocation_snapshot_coordinator.dart';
import 'package:taskly_bloc/domain/services/time/app_lifecycle_service.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';
import 'package:taskly_bloc/domain/services/time/temporal_trigger_service.dart';
import 'package:taskly_bloc/domain/interfaces/analytics_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/pending_notifications_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/journal_repository_contract.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_query_builder.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_grouper.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_section_data_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/trigger_evaluator.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';
import 'package:taskly_bloc/domain/services/attention/attention_temporal_invalidation_service.dart';
import 'package:taskly_bloc/domain/attention/contracts/attention_engine_contract.dart'
    as attention_engine_v2;
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart'
    as attention_repo_v2;
import 'package:taskly_bloc/domain/attention/engine/attention_engine.dart'
    as attention_engine_v2_impl;
import 'package:taskly_bloc/data/attention/repositories/attention_repository_v2.dart'
    as attention_repo_v2_impl;
import 'package:taskly_bloc/domain/services/notifications/pending_notifications_processor.dart';
import 'package:taskly_bloc/domain/services/notifications/notification_presenter.dart';
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/agenda_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/check_in_summary_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/data_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/entity_header_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/issues_summary_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/interleaved_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_banner_section_interpreter_v1.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';

final GetIt getIt = GetIt.instance;

// Register all the classes you want to inject
Future<void> setupDependencies() async {
  // Load supabase and powersync before registering dependencies
  await loadSupabase();

  // Track if this is first auth callback (from openDatabase itself when already logged in)
  // vs later callbacks from auth state changes
  var initialSetupComplete = false;

  final PowerSyncDatabase syncDb = await openDatabase(
    onAuthenticated: () async {
      // This callback runs:
      // 1. Immediately after openDatabase if user is already logged in
      // 2. On each signedIn event
      //
      // On first call (from openDatabase), DI setup isn't complete yet.
      // On subsequent calls, we can run maintenance.
      if (!initialSetupComplete) {
        // First call - DI not ready, skip (we'll run maintenance below)
        return;
      }
      // Run post-auth maintenance (seeding, cleanup)
      await runPostAuthMaintenance(
        driftDb: getIt<AppDatabase>(),
        idGenerator: getIt<IdGenerator>(),
      );
    },
  );

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
    ..registerLazySingleton<ValueRepositoryContract>(
      () => ValueRepository(
        driftDb: getIt<AppDatabase>(),
        idGenerator: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<SettingsRepositoryContract>(
      () => SettingsRepository(driftDb: getIt<AppDatabase>()),
    )
    ..registerLazySingleton<HomeDayKeyService>(
      () => HomeDayKeyService(
        settingsRepository: getIt<SettingsRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<AppLifecycleService>(AppLifecycleService.new)
    ..registerLazySingleton<PerformanceLogger>(PerformanceLogger.new)
    ..registerLazySingleton<TemporalTriggerService>(
      () => TemporalTriggerService(
        dayKeyService: getIt<HomeDayKeyService>(),
        lifecycleService: getIt<AppLifecycleService>(),
      ),
    )
    ..registerLazySingleton<AttentionTemporalInvalidationService>(
      () => AttentionTemporalInvalidationService(
        temporalTriggerService: getIt<TemporalTriggerService>(),
      ),
    )
    ..registerLazySingleton<AllocationSnapshotRepositoryContract>(
      () => AllocationSnapshotRepository(db: getIt<AppDatabase>()),
    )
    // Screens - all screens come from DB (system seeded + custom)
    ..registerLazySingleton<ScreenDefinitionsRepositoryContract>(
      () => ScreenDefinitionsRepository(
        databaseRepository: ScreenDefinitionsRepositoryImpl(
          getIt<AppDatabase>(),
        ),
      ),
    )
    ..registerLazySingleton<AllocationOrchestrator>(
      () => AllocationOrchestrator(
        taskRepository: getIt<TaskRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        analyticsService: getIt<AnalyticsService>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        allocationSnapshotRepository:
            getIt<AllocationSnapshotRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
      ),
    )
    ..registerLazySingleton<AllocationSnapshotCoordinator>(
      () => AllocationSnapshotCoordinator(
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
      ),
    )
    // Entity action service for unified screen model
    ..registerLazySingleton<EntityActionService>(
      () => EntityActionService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
      ),
    )
    ..registerLazySingleton<AgendaSectionDataService>(
      () => AgendaSectionDataService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<SectionDataService>(
      () => SectionDataService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        agendaDataService: getIt<AgendaSectionDataService>(),
        allocationSnapshotRepository:
            getIt<AllocationSnapshotRepositoryContract>(),
        analyticsService: getIt<AnalyticsService>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
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
        valueRepo: getIt<ValueRepositoryContract>(),
        journalRepo: getIt<JournalRepositoryContract>(),
        analyticsRepo: getIt<AnalyticsRepositoryContract>(),
      ),
    )
    // Journal
    ..registerLazySingleton<JournalRepositoryContract>(
      () => JournalRepositoryImpl(
        getIt<AppDatabase>(),
        getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<ScreenQueryBuilder>(ScreenQueryBuilder.new)
    ..registerLazySingleton<EntityGrouper>(EntityGrouper.new)
    ..registerLazySingleton<TriggerEvaluator>(TriggerEvaluator.new)
    ..registerLazySingleton<TaskStatsCalculator>(TaskStatsCalculator.new)
    // Attention system (v2 bounded context)
    ..registerLazySingleton<attention_repo_v2.AttentionRepositoryContract>(
      () => attention_repo_v2_impl.AttentionRepositoryV2(
        db: getIt<AppDatabase>(),
      ),
    )
    ..registerLazySingleton<attention_engine_v2.AttentionEngineContract>(
      () => attention_engine_v2_impl.AttentionEngine(
        attentionRepository:
            getIt<attention_repo_v2.AttentionRepositoryContract>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        allocationSnapshotRepository:
            getIt<AllocationSnapshotRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
        invalidations:
            getIt<AttentionTemporalInvalidationService>().invalidations,
      ),
    )
    ..registerLazySingleton<DataListSectionInterpreterV2>(
      () => DataListSectionInterpreterV2(
        templateId: SectionTemplateId.taskListV2,
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.taskListV2,
    )
    ..registerLazySingleton<DataListSectionInterpreterV2>(
      () => DataListSectionInterpreterV2(
        templateId: SectionTemplateId.projectListV2,
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.projectListV2,
    )
    ..registerLazySingleton<DataListSectionInterpreterV2>(
      () => DataListSectionInterpreterV2(
        templateId: SectionTemplateId.valueListV2,
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.valueListV2,
    )
    ..registerLazySingleton<InterleavedListSectionInterpreterV2>(
      () => InterleavedListSectionInterpreterV2(
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.interleavedListV2,
    )
    ..registerLazySingleton<HierarchyValueProjectTaskSectionInterpreterV2>(
      () => HierarchyValueProjectTaskSectionInterpreterV2(
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.hierarchyValueProjectTaskV2,
    )
    ..registerLazySingleton<AgendaSectionInterpreterV2>(
      () => AgendaSectionInterpreterV2(
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.agendaV2,
    )
    ..registerLazySingleton<IssuesSummarySectionInterpreter>(
      () => IssuesSummarySectionInterpreter(
        attentionEngine: getIt<attention_engine_v2.AttentionEngineContract>(),
      ),
      instanceName: SectionTemplateId.issuesSummary,
    )
    ..registerLazySingleton<AllocationAlertsSectionInterpreter>(
      () => AllocationAlertsSectionInterpreter(
        attentionEngine: getIt<attention_engine_v2.AttentionEngineContract>(),
      ),
      instanceName: SectionTemplateId.allocationAlerts,
    )
    ..registerLazySingleton<CheckInSummarySectionInterpreter>(
      () => CheckInSummarySectionInterpreter(
        attentionEngine: getIt<attention_engine_v2.AttentionEngineContract>(),
      ),
      instanceName: SectionTemplateId.checkInSummary,
    )
    ..registerLazySingleton<AttentionBannerSectionInterpreterV1>(
      () => AttentionBannerSectionInterpreterV1(
        engine: getIt<attention_engine_v2.AttentionEngineContract>(),
      ),
      instanceName: SectionTemplateId.attentionBannerV1,
    )
    ..registerLazySingleton<EntityHeaderSectionInterpreter>(
      () => EntityHeaderSectionInterpreter(
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        taskRepository: getIt<TaskRepositoryContract>(),
      ),
      instanceName: SectionTemplateId.entityHeader,
    )
    ..registerLazySingleton<ScreenSpecDataInterpreter>(
      () => ScreenSpecDataInterpreter(
        settingsRepository: getIt<SettingsRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        taskListInterpreter: getIt<DataListSectionInterpreterV2>(
          instanceName: SectionTemplateId.taskListV2,
        ),
        projectListInterpreter: getIt<DataListSectionInterpreterV2>(
          instanceName: SectionTemplateId.projectListV2,
        ),
        valueListInterpreter: getIt<DataListSectionInterpreterV2>(
          instanceName: SectionTemplateId.valueListV2,
        ),
        interleavedListInterpreter: getIt<InterleavedListSectionInterpreterV2>(
          instanceName: SectionTemplateId.interleavedListV2,
        ),
        hierarchyValueProjectTaskInterpreter:
            getIt<HierarchyValueProjectTaskSectionInterpreterV2>(
              instanceName: SectionTemplateId.hierarchyValueProjectTaskV2,
            ),
        agendaInterpreter: getIt<AgendaSectionInterpreterV2>(
          instanceName: SectionTemplateId.agendaV2,
        ),
        issuesSummaryInterpreter: getIt<IssuesSummarySectionInterpreter>(
          instanceName: SectionTemplateId.issuesSummary,
        ),
        allocationAlertsInterpreter: getIt<AllocationAlertsSectionInterpreter>(
          instanceName: SectionTemplateId.allocationAlerts,
        ),
        checkInSummaryInterpreter: getIt<CheckInSummarySectionInterpreter>(
          instanceName: SectionTemplateId.checkInSummary,
        ),
        attentionBannerInterpreter: getIt<AttentionBannerSectionInterpreterV1>(
          instanceName: SectionTemplateId.attentionBannerV1,
        ),
        entityHeaderInterpreter: getIt<EntityHeaderSectionInterpreter>(
          instanceName: SectionTemplateId.entityHeader,
        ),
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

  // Mark DI setup as complete for future auth callbacks
  initialSetupComplete = true;

  // Run post-auth maintenance if user was already logged in during openDatabase
  // (The callback above would have skipped because initialSetupComplete was false)
  if (isLoggedIn()) {
    await runPostAuthMaintenance(
      driftDb: getIt<AppDatabase>(),
      idGenerator: getIt<IdGenerator>(),
    );
  }
}
