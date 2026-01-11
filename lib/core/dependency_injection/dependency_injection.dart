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
import 'package:taskly_bloc/data/repositories/allocation_snapshot_repository.dart';
import 'package:taskly_bloc/data/repositories/project_repository.dart';
import 'package:taskly_bloc/data/repositories/settings_repository.dart';
import 'package:taskly_bloc/data/repositories/task_repository.dart';
import 'package:taskly_bloc/data/repositories/value_repository.dart';
import 'package:taskly_bloc/data/supabase/supabase.dart';
import 'package:taskly_bloc/domain/interfaces/auth_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/allocation_snapshot_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/value_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/settings_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/data/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_bloc/data/features/analytics/services/analytics_service_impl.dart';
import 'package:taskly_bloc/data/features/wellbeing/repositories/wellbeing_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/default_system_screen_provider.dart';
import 'package:taskly_bloc/data/features/screens/repositories/screen_definitions_repository_impl.dart';
import 'package:taskly_bloc/data/features/screens/repositories/screen_definitions_repository.dart';
import 'package:taskly_bloc/data/features/workflow/repositories/workflow_repository_impl.dart';
import 'package:taskly_bloc/data/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_bloc/data/features/notifications/services/logging_notification_presenter.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_orchestrator.dart';
import 'package:taskly_bloc/domain/services/allocation/allocation_snapshot_coordinator.dart';
import 'package:taskly_bloc/domain/services/time/app_lifecycle_service.dart';
import 'package:taskly_bloc/domain/services/time/home_day_key_service.dart';
import 'package:taskly_bloc/domain/services/time/temporal_trigger_service.dart';
import 'package:taskly_bloc/domain/interfaces/analytics_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/pending_notifications_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/screen_definitions_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/system_screen_provider.dart';
import 'package:taskly_bloc/domain/interfaces/wellbeing_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/workflow_repository_contract.dart';
import 'package:taskly_bloc/domain/services/analytics/analytics_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_query_builder.dart';
import 'package:taskly_bloc/domain/services/screens/entity_grouper.dart';
import 'package:taskly_bloc/domain/services/screens/agenda_section_data_service.dart';
import 'package:taskly_bloc/domain/services/screens/trigger_evaluator.dart';
import 'package:taskly_bloc/domain/services/workflow/workflow_service.dart';
import 'package:taskly_bloc/domain/services/workflow/problem_detector_service.dart';
import 'package:taskly_bloc/domain/services/analytics/task_stats_calculator.dart';
import 'package:taskly_bloc/domain/services/attention/attention_evaluator.dart';
import 'package:taskly_bloc/domain/services/attention/attention_temporal_invalidation_service.dart';
import 'package:taskly_bloc/domain/interfaces/attention_repository_contract.dart';
import 'package:taskly_bloc/data/repositories/attention_repository.dart';
import 'package:taskly_bloc/domain/services/notifications/pending_notifications_processor.dart';
import 'package:taskly_bloc/domain/services/notifications/notification_presenter.dart';
import 'package:taskly_bloc/domain/services/screens/section_data_service.dart';
import 'package:taskly_bloc/domain/services/screens/screen_data_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/entity_action_service.dart';
import 'package:taskly_bloc/domain/models/screens/section_template_id.dart';
import 'package:taskly_bloc/domain/services/screens/templates/agenda_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/allocation_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/allocation_alerts_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/check_in_summary_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/data_list_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/entity_header_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/issues_summary_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/interleaved_list_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/someday_null_dates_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/someday_backlog_section_interpreter.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_interpreter_registry.dart';
import 'package:taskly_bloc/domain/services/screens/templates/section_template_params_codec.dart';
import 'package:taskly_bloc/domain/services/screens/templates/static_section_interpreter.dart';

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
    // System screen provider - validates system screens
    ..registerLazySingleton<SystemScreenProvider>(
      () => const DefaultSystemScreenProvider(),
    )
    // Screens - all screens come from DB (system seeded + custom)
    ..registerLazySingleton<ScreenDefinitionsRepositoryContract>(
      () => ScreenDefinitionsRepository(
        databaseRepository: ScreenDefinitionsRepositoryImpl(
          getIt<AppDatabase>(),
          getIt<IdGenerator>(),
          getIt<SystemScreenProvider>(),
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
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.statisticsDashboard,
      ),
      instanceName: SectionTemplateId.statisticsDashboard,
    )
    ..registerLazySingleton<SectionDataService>(
      () => SectionDataService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        agendaDataService: getIt<AgendaSectionDataService>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
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
    // Attention system
    ..registerLazySingleton<AttentionRepositoryContract>(
      () => AttentionRepository(db: getIt<AppDatabase>()),
    )
    ..registerLazySingleton<AttentionEvaluator>(
      () => AttentionEvaluator(
        attentionRepository: getIt<AttentionRepositoryContract>(),
        allocationSnapshotRepository:
            getIt<AllocationSnapshotRepositoryContract>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
      ),
    )
    ..registerLazySingleton<SectionTemplateParamsCodec>(
      SectionTemplateParamsCodec.new,
    )
    ..registerLazySingleton<DataListSectionInterpreter>(
      () => DataListSectionInterpreter(
        templateId: SectionTemplateId.taskList,
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.taskList,
    )
    ..registerLazySingleton<DataListSectionInterpreter>(
      () => DataListSectionInterpreter(
        templateId: SectionTemplateId.projectList,
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.projectList,
    )
    ..registerLazySingleton<DataListSectionInterpreter>(
      () => DataListSectionInterpreter(
        templateId: SectionTemplateId.valueList,
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.valueList,
    )
    ..registerLazySingleton<InterleavedListSectionInterpreter>(
      () => InterleavedListSectionInterpreter(
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.interleavedList,
    )
    ..registerLazySingleton<SomedayNullDatesSectionInterpreter>(
      () => SomedayNullDatesSectionInterpreter(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        allocationSnapshotRepository:
            getIt<AllocationSnapshotRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
      ),
      instanceName: SectionTemplateId.somedayNullDates,
    )
    ..registerLazySingleton<SomedayBacklogSectionInterpreter>(
      () => SomedayBacklogSectionInterpreter(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        allocationSnapshotRepository:
            getIt<AllocationSnapshotRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
      ),
      instanceName: SectionTemplateId.somedayBacklog,
    )
    ..registerLazySingleton<AllocationSectionInterpreter>(
      () => AllocationSectionInterpreter(
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.allocation,
    )
    ..registerLazySingleton<AgendaSectionInterpreter>(
      () => AgendaSectionInterpreter(
        sectionDataService: getIt<SectionDataService>(),
      ),
      instanceName: SectionTemplateId.agenda,
    )
    ..registerLazySingleton<IssuesSummarySectionInterpreter>(
      () => IssuesSummarySectionInterpreter(
        attentionEvaluator: getIt<AttentionEvaluator>(),
      ),
      instanceName: SectionTemplateId.issuesSummary,
    )
    ..registerLazySingleton<AllocationAlertsSectionInterpreter>(
      () => AllocationAlertsSectionInterpreter(
        attentionEvaluator: getIt<AttentionEvaluator>(),
      ),
      instanceName: SectionTemplateId.allocationAlerts,
    )
    ..registerLazySingleton<CheckInSummarySectionInterpreter>(
      () => CheckInSummarySectionInterpreter(
        attentionEvaluator: getIt<AttentionEvaluator>(),
        attentionTemporalInvalidationService:
            getIt<AttentionTemporalInvalidationService>(),
      ),
      instanceName: SectionTemplateId.checkInSummary,
    )
    ..registerLazySingleton<EntityHeaderSectionInterpreter>(
      () => EntityHeaderSectionInterpreter(
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        taskRepository: getIt<TaskRepositoryContract>(),
      ),
      instanceName: SectionTemplateId.entityHeader,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () =>
          StaticSectionInterpreter(templateId: SectionTemplateId.settingsMenu),
      instanceName: SectionTemplateId.settingsMenu,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () =>
          StaticSectionInterpreter(templateId: SectionTemplateId.workflowList),
      instanceName: SectionTemplateId.workflowList,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.journalTimeline,
      ),
      instanceName: SectionTemplateId.journalTimeline,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.navigationSettings,
      ),
      instanceName: SectionTemplateId.navigationSettings,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.allocationSettings,
      ),
      instanceName: SectionTemplateId.allocationSettings,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.attentionRules,
      ),
      instanceName: SectionTemplateId.attentionRules,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.focusSetupWizard,
      ),
      instanceName: SectionTemplateId.focusSetupWizard,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.screenManagement,
      ),
      instanceName: SectionTemplateId.screenManagement,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.trackerManagement,
      ),
      instanceName: SectionTemplateId.trackerManagement,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.wellbeingDashboard,
      ),
      instanceName: SectionTemplateId.wellbeingDashboard,
    )
    ..registerLazySingleton<StaticSectionInterpreter>(
      () => StaticSectionInterpreter(
        templateId: SectionTemplateId.myDayFocusModeRequired,
      ),
      instanceName: SectionTemplateId.myDayFocusModeRequired,
    )
    ..registerLazySingleton<SectionTemplateInterpreterRegistry>(
      () => SectionTemplateInterpreterRegistry([
        getIt<DataListSectionInterpreter>(
          instanceName: SectionTemplateId.taskList,
        ),
        getIt<DataListSectionInterpreter>(
          instanceName: SectionTemplateId.projectList,
        ),
        getIt<DataListSectionInterpreter>(
          instanceName: SectionTemplateId.valueList,
        ),
        getIt<InterleavedListSectionInterpreter>(
          instanceName: SectionTemplateId.interleavedList,
        ),
        getIt<SomedayNullDatesSectionInterpreter>(
          instanceName: SectionTemplateId.somedayNullDates,
        ),
        getIt<SomedayBacklogSectionInterpreter>(
          instanceName: SectionTemplateId.somedayBacklog,
        ),
        getIt<AllocationSectionInterpreter>(
          instanceName: SectionTemplateId.allocation,
        ),
        getIt<AgendaSectionInterpreter>(instanceName: SectionTemplateId.agenda),
        getIt<IssuesSummarySectionInterpreter>(
          instanceName: SectionTemplateId.issuesSummary,
        ),
        getIt<AllocationAlertsSectionInterpreter>(
          instanceName: SectionTemplateId.allocationAlerts,
        ),
        getIt<CheckInSummarySectionInterpreter>(
          instanceName: SectionTemplateId.checkInSummary,
        ),
        getIt<EntityHeaderSectionInterpreter>(
          instanceName: SectionTemplateId.entityHeader,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.settingsMenu,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.statisticsDashboard,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.workflowList,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.journalTimeline,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.navigationSettings,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.allocationSettings,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.attentionRules,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.focusSetupWizard,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.screenManagement,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.trackerManagement,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.wellbeingDashboard,
        ),
        getIt<StaticSectionInterpreter>(
          instanceName: SectionTemplateId.myDayFocusModeRequired,
        ),
      ]),
    )
    // ScreenDataInterpreter - coordinates section templates
    ..registerLazySingleton<ScreenDataInterpreter>(
      () => ScreenDataInterpreter(
        interpreterRegistry: getIt<SectionTemplateInterpreterRegistry>(),
        paramsCodec: getIt<SectionTemplateParamsCodec>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
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
