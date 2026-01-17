/// Dependency injection configuration using GetIt.
library;

import 'package:get_it/get_it.dart';
import 'package:taskly_bloc/data/services/occurrence_stream_expander.dart';
import 'package:taskly_bloc/data/services/occurrence_write_helper.dart';
import 'package:taskly_data/data_stack.dart';
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_catalog_repository_impl.dart';
import 'package:taskly_bloc/data/screens/repositories/screen_catalog_repository.dart';
import 'package:taskly_bloc/domain/interfaces/screen_catalog_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_query_builder.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_grouper.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_section_data_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/trigger_evaluator.dart';
import 'package:taskly_domain/attention.dart'
    as attention_engine_v2
    show AttentionEngineContract;
import 'package:taskly_domain/attention.dart'
    as attention_repo_v2
    show AttentionRepositoryContract;
import 'package:taskly_domain/attention.dart'
    as attention_engine_v2_impl
    show AttentionEngine;
import 'package:taskly_bloc/domain/screens/runtime/section_data_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_style_resolver.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_module_interpreter_registry.dart';
import 'package:taskly_bloc/domain/screens/runtime/screen_spec_data_interpreter.dart';
import 'package:taskly_bloc/domain/screens/runtime/entity_action_service.dart';
import 'package:taskly_bloc/domain/screens/language/models/section_template_id.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/agenda_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/data_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/entity_header_section_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/hierarchy_value_project_task_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/interleaved_list_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_banner_section_interpreter_v2.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/attention_inbox_section_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/journal_history_list_module_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/journal_manage_trackers_module_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/journal_today_composer_module_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/journal_today_entries_module_interpreter_v1.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/my_day_ranked_tasks_v1_module_interpreter.dart';
import 'package:taskly_bloc/domain/screens/templates/interpreters/my_day_hero_v1_module_interpreter.dart';
import 'package:taskly_bloc/core/performance/performance_logger.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_inbox_bloc.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_rules_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_bell_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_banner_session_cubit.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/add_log_cubit.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_entry_editor_cubit.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_manage_trackers_cubit.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_trackers_cubit.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_cubit.dart';

import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';

import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_header_bloc.dart';

final GetIt getIt = GetIt.instance;

// Register all the classes you want to inject
Future<void> setupDependencies() async {
  final dataStack = await TasklyDataStack.initialize();

  // Core stack handles.
  getIt
    ..registerSingleton<AppDatabase>(dataStack.driftDb)
    ..registerSingleton<IdGenerator>(dataStack.idGenerator)
    ..registerSingleton<AuthRepositoryContract>(dataStack.authRepository)
    ..registerSingleton<LocalDataMaintenanceService>(
      dataStack.localDataMaintenanceService,
    );

  getIt
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

    // Bind taskly_data implementations to taskly_domain contracts.
    ..registerSingleton<TasklyDataBindings>(
      dataStack.createBindings(
        occurrenceExpander: getIt<OccurrenceStreamExpanderContract>(),
        occurrenceWriteHelper: getIt<OccurrenceWriteHelperContract>(),
      ),
    )
    ..registerSingleton<ProjectRepositoryContract>(
      getIt<TasklyDataBindings>().projectRepository,
    )
    ..registerSingleton<TaskRepositoryContract>(
      getIt<TasklyDataBindings>().taskRepository,
    )
    ..registerSingleton<ValueRepositoryContract>(
      getIt<TasklyDataBindings>().valueRepository,
    )
    ..registerSingleton<SettingsRepositoryContract>(
      getIt<TasklyDataBindings>().settingsRepository,
    )
    ..registerSingleton<AllocationSnapshotRepositoryContract>(
      getIt<TasklyDataBindings>().allocationSnapshotRepository,
    )
    ..registerSingleton<attention_repo_v2.AttentionRepositoryContract>(
      getIt<TasklyDataBindings>().attentionRepository,
    )
    ..registerSingleton<AnalyticsRepositoryContract>(
      getIt<TasklyDataBindings>().analyticsRepository,
    )
    ..registerSingleton<JournalRepositoryContract>(
      getIt<TasklyDataBindings>().journalRepository,
    )
    ..registerSingleton<AnalyticsService>(
      getIt<TasklyDataBindings>().analyticsService,
    )
    ..registerSingleton<NotificationPresenter>(
      getIt<TasklyDataBindings>().notificationPresenter,
    )
    ..registerSingleton<PendingNotificationsRepositoryContract>(
      getIt<TasklyDataBindings>().pendingNotificationsRepository,
    )
    ..registerSingleton<PendingNotificationsProcessor>(
      getIt<TasklyDataBindings>().pendingNotificationsProcessor,
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
    ..registerLazySingleton<TodayProgressService>(
      () => TodayProgressService(
        allocationSnapshotRepository:
            getIt<AllocationSnapshotRepositoryContract>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
      ),
    )
    ..registerLazySingleton<AttentionTemporalInvalidationService>(
      () => AttentionTemporalInvalidationService(
        temporalTriggerService: getIt<TemporalTriggerService>(),
      ),
    )
    // Screens - system screens come from code; user preferences come from DB.
    ..registerLazySingleton<ScreenCatalogRepositoryContract>(
      () => ScreenCatalogRepository(
        databaseRepository: ScreenCatalogRepositoryImpl(
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
        valueRepository: getIt<ValueRepositoryContract>(),
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
    ..registerLazySingleton<ScreenQueryBuilder>(ScreenQueryBuilder.new)
    ..registerLazySingleton<EntityGrouper>(EntityGrouper.new)
    ..registerLazySingleton<TriggerEvaluator>(TriggerEvaluator.new)
    ..registerLazySingleton<TaskStatsCalculator>(TaskStatsCalculator.new)
    // Attention repository binding is owned by taskly_data module.
    ..registerLazySingleton<attention_engine_v2_impl.AttentionEngine>(
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
    ..registerLazySingleton<attention_engine_v2.AttentionEngineContract>(
      () => CachedAttentionEngine(
        inner: getIt<attention_engine_v2_impl.AttentionEngine>(),
      ),
    )
    ..registerLazySingleton<AttentionPrewarmService>(
      () => AttentionPrewarmService(
        engine: getIt<attention_engine_v2.AttentionEngineContract>(),
      ),
    )
    // Debug/maintenance services (used by Settings in debug builds)
    ..registerLazySingleton<TemplateDataService>(
      () => TemplateDataService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        allocationSnapshotRepository:
            getIt<AllocationSnapshotRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<AuthenticatedAppServicesCoordinator>(
      () => AuthenticatedAppServicesCoordinator(
        homeDayKeyService: getIt<HomeDayKeyService>(),
        appLifecycleService: getIt<AppLifecycleService>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
        attentionTemporalInvalidationService:
            getIt<AttentionTemporalInvalidationService>(),
        attentionPrewarmService: getIt<AttentionPrewarmService>(),
        allocationSnapshotCoordinator: getIt<AllocationSnapshotCoordinator>(),
      ),
    )
    // Presentation BLoCs/Cubits
    ..registerFactory<AttentionInboxBloc>(
      () => AttentionInboxBloc(
        engine: getIt<attention_engine_v2.AttentionEngineContract>(),
        repository: getIt<attention_repo_v2.AttentionRepositoryContract>(),
        idGenerator: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<AttentionBellCubit>(
      () => AttentionBellCubit(
        engine: getIt<attention_engine_v2.AttentionEngineContract>(),
      ),
    )
    ..registerLazySingleton<AttentionBannerSessionCubit>(
      AttentionBannerSessionCubit.new,
    )
    ..registerFactory<AttentionRulesCubit>(
      () => AttentionRulesCubit(
        repository: getIt<attention_repo_v2.AttentionRepositoryContract>(),
      ),
    )
    ..registerFactory<JournalTodayBloc>(
      () => JournalTodayBloc(repository: getIt<JournalRepositoryContract>()),
    )
    ..registerFactory<JournalHistoryBloc>(
      () => JournalHistoryBloc(repository: getIt<JournalRepositoryContract>()),
    )
    ..registerFactoryParam<AddLogCubit, Set<String>, void>(
      (preselectedTrackerIds, _) => AddLogCubit(
        repository: getIt<JournalRepositoryContract>(),
        preselectedTrackerIds: preselectedTrackerIds,
      ),
    )
    ..registerFactoryParam<JournalEntryEditorCubit, String?, Set<String>>(
      (entryId, preselectedTrackerIds) => JournalEntryEditorCubit(
        repository: getIt<JournalRepositoryContract>(),
        entryId: entryId,
        preselectedTrackerIds: preselectedTrackerIds,
      ),
    )
    ..registerFactory<JournalManageTrackersCubit>(
      () => JournalManageTrackersCubit(
        repository: getIt<JournalRepositoryContract>(),
      ),
    )
    ..registerFactory<JournalTrackersCubit>(
      () =>
          JournalTrackersCubit(repository: getIt<JournalRepositoryContract>()),
    )
    ..registerFactory<MyDayGateBloc>(
      () => MyDayGateBloc(
        settingsRepository: getIt<SettingsRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
      ),
    )
    ..registerFactory<MyDayHeaderBloc>(
      () => MyDayHeaderBloc(
        settingsRepository: getIt<SettingsRepositoryContract>(),
      ),
    )
    ..registerFactory<SettingsMaintenanceCubit>(
      () => SettingsMaintenanceCubit(
        templateDataService: getIt<TemplateDataService>(),
        localDataMaintenanceService: getIt<LocalDataMaintenanceService>(),
        allocationSnapshotCoordinator: getIt<AllocationSnapshotCoordinator>(),
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
    ..registerLazySingleton<AttentionBannerSectionInterpreterV2>(
      () => AttentionBannerSectionInterpreterV2(
        engine: getIt<attention_engine_v2.AttentionEngineContract>(),
        todayProgressService: getIt<TodayProgressService>(),
      ),
      instanceName: SectionTemplateId.attentionBannerV2,
    )
    ..registerLazySingleton<AttentionInboxSectionInterpreterV1>(
      AttentionInboxSectionInterpreterV1.new,
      instanceName: SectionTemplateId.attentionInboxV1,
    )
    ..registerLazySingleton<EntityHeaderSectionInterpreter>(
      () => EntityHeaderSectionInterpreter(
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        taskRepository: getIt<TaskRepositoryContract>(),
      ),
      instanceName: SectionTemplateId.entityHeader,
    )
    ..registerLazySingleton<MyDayRankedTasksV1ModuleInterpreter>(
      () => MyDayRankedTasksV1ModuleInterpreter(
        hierarchyValueProjectTaskInterpreter:
            getIt<HierarchyValueProjectTaskSectionInterpreterV2>(
              instanceName: SectionTemplateId.hierarchyValueProjectTaskV2,
            ),
      ),
    )
    ..registerLazySingleton<MyDayHeroV1ModuleInterpreter>(
      () => MyDayHeroV1ModuleInterpreter(
        hierarchyValueProjectTaskInterpreter:
            getIt<HierarchyValueProjectTaskSectionInterpreterV2>(
              instanceName: SectionTemplateId.hierarchyValueProjectTaskV2,
            ),
      ),
    )
    ..registerLazySingleton<JournalTodayComposerModuleInterpreterV1>(
      () => JournalTodayComposerModuleInterpreterV1(
        repository: getIt<JournalRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<JournalTodayEntriesModuleInterpreterV1>(
      () => JournalTodayEntriesModuleInterpreterV1(
        repository: getIt<JournalRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<JournalHistoryListModuleInterpreterV1>(
      () => JournalHistoryListModuleInterpreterV1(
        repository: getIt<JournalRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<JournalManageTrackersModuleInterpreterV1>(
      () => JournalManageTrackersModuleInterpreterV1(
        repository: getIt<JournalRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<EntityStyleResolver>(
      () => const EntityStyleResolver(),
    )
    ..registerLazySingleton<ScreenModuleInterpreterRegistry>(
      () => DefaultScreenModuleInterpreterRegistry(
        entityStyleResolver: getIt<EntityStyleResolver>(),
        taskListInterpreter: getIt<DataListSectionInterpreterV2>(
          instanceName: SectionTemplateId.taskListV2,
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
        attentionBannerV2Interpreter:
            getIt<AttentionBannerSectionInterpreterV2>(
              instanceName: SectionTemplateId.attentionBannerV2,
            ),
        attentionInboxInterpreter: getIt<AttentionInboxSectionInterpreterV1>(
          instanceName: SectionTemplateId.attentionInboxV1,
        ),
        entityHeaderInterpreter: getIt<EntityHeaderSectionInterpreter>(
          instanceName: SectionTemplateId.entityHeader,
        ),
        myDayHeroV1Interpreter: getIt<MyDayHeroV1ModuleInterpreter>(),
        myDayRankedTasksV1Interpreter:
            getIt<MyDayRankedTasksV1ModuleInterpreter>(),
        journalTodayComposerV1Interpreter:
            getIt<JournalTodayComposerModuleInterpreterV1>(),
        journalTodayEntriesV1Interpreter:
            getIt<JournalTodayEntriesModuleInterpreterV1>(),
        journalHistoryListV1Interpreter:
            getIt<JournalHistoryListModuleInterpreterV1>(),
        journalManageTrackersV1Interpreter:
            getIt<JournalManageTrackersModuleInterpreterV1>(),
      ),
    )
    ..registerLazySingleton<ScreenSpecDataInterpreter>(
      () => ScreenSpecDataInterpreter(
        settingsRepository: getIt<SettingsRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        moduleInterpreterRegistry: getIt<ScreenModuleInterpreterRegistry>(),
      ),
    );
}
