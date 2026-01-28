/// Dependency injection configuration using GetIt.
library;

import 'package:get_it/get_it.dart';
import 'package:taskly_data/data_stack.dart';
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_domain/attention.dart'
    as attention_engine_v2
    show AttentionEngineContract;
import 'package:taskly_domain/attention.dart'
    as attention_repo_v2
    show AttentionRepositoryContract;
import 'package:taskly_domain/attention.dart'
    as attention_engine_v2_impl
    show AttentionEngine;
import 'package:taskly_bloc/presentation/shared/services/time/home_day_service.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
import 'package:taskly_bloc/core/services/time/app_lifecycle_service.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/allocation_settings_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_bloc.dart';
import 'package:taskly_bloc/presentation/features/anytime/services/anytime_session_query_service.dart';
import 'package:taskly_bloc/presentation/features/scheduled/services/scheduled_session_query_service.dart';
import 'package:taskly_bloc/presentation/shared/services/streams/session_stream_cache.dart';

import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';

import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_gate_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_query_service.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_session_query_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/plan_my_day_bloc.dart';
import 'package:taskly_bloc/presentation/shared/services/time/session_day_key_service.dart';
import 'package:taskly_bloc/presentation/shared/session/presentation_session_services_coordinator.dart';
import 'package:taskly_bloc/presentation/shared/session/session_allocation_cache_service.dart';
import 'package:taskly_bloc/presentation/shared/session/session_shared_data_service.dart';

final GetIt getIt = GetIt.instance;

// Register all the classes you want to inject
Future<void> setupDependencies() async {
  final dataStack = await TasklyDataStack.initialize();

  // Core stack handles.
  getIt
    ..registerSingleton<TasklyDataStack>(dataStack)
    ..registerSingleton<SyncAnomalyStream>(dataStack)
    ..registerSingleton<AppDatabase>(dataStack.driftDb)
    ..registerSingleton<IdGenerator>(dataStack.idGenerator)
    ..registerSingleton<AuthRepositoryContract>(dataStack.authRepository)
    ..registerSingleton<LocalDataMaintenanceService>(
      dataStack.localDataMaintenanceService,
    );

  getIt.registerSingleton<Clock>(systemClock);

  getIt
    ..registerLazySingleton<NowService>(SystemNowService.new)
    ..registerLazySingleton<HomeDayService>(
      () => HomeDayService(
        dayKeyService: getIt<HomeDayKeyService>(),
        nowService: getIt<NowService>(),
      ),
    )
    // Bind taskly_data implementations to taskly_domain contracts.
    ..registerSingleton<TasklyDataBindings>(
      dataStack.createBindings(
        clock: getIt<Clock>(),
      ),
    )
    ..registerSingleton<OccurrenceReadService>(
      getIt<TasklyDataBindings>().occurrenceReadService,
    )
    ..registerSingleton<ProjectRepositoryContract>(
      getIt<TasklyDataBindings>().projectRepository,
    )
    ..registerSingleton<ProjectNextActionsRepositoryContract>(
      getIt<TasklyDataBindings>().projectNextActionsRepository,
    )
    ..registerSingleton<ProjectAnchorStateRepositoryContract>(
      getIt<TasklyDataBindings>().projectAnchorStateRepository,
    )
    ..registerSingleton<TaskRepositoryContract>(
      getIt<TasklyDataBindings>().taskRepository,
    )
    ..registerSingleton<ValueRepositoryContract>(
      getIt<TasklyDataBindings>().valueRepository,
    )
    ..registerSingleton<RoutineRepositoryContract>(
      getIt<TasklyDataBindings>().routineRepository,
    )
    ..registerSingleton<SettingsRepositoryContract>(
      getIt<TasklyDataBindings>().settingsRepository,
    )
    ..registerSingleton<MyDayRepositoryContract>(
      getIt<TasklyDataBindings>().myDayRepository,
    )
    ..registerLazySingleton<MyDayRitualStatusService>(
      () => MyDayRitualStatusService(
        myDayRepository: getIt<MyDayRepositoryContract>(),
      ),
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
    ..registerSingleton<InitialSyncService>(
      getIt<TasklyDataBindings>().initialSyncService,
    )
    ..registerSingleton<HomeDayKeyService>(
      getIt<TasklyDataBindings>().homeDayKeyService,
    )
    ..registerLazySingleton<AppLifecycleService>(AppLifecycleService.new)
    ..registerLazySingleton<AppLifecycleEvents>(
      getIt.get<AppLifecycleService>,
    )
    ..registerLazySingleton<TemporalTriggerService>(
      () => TemporalTriggerService(
        dayKeyService: getIt<HomeDayKeyService>(),
        lifecycleService: getIt<AppLifecycleEvents>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerLazySingleton<SessionDayKeyService>(
      () => SessionDayKeyService(
        dayKeyService: getIt<HomeDayKeyService>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
      ),
    )
    ..registerLazySingleton<SessionStreamCacheManager>(
      () => SessionStreamCacheManager(
        appLifecycleService: getIt<AppLifecycleEvents>(),
      ),
    )
    ..registerLazySingleton<SessionSharedDataService>(
      () => SessionSharedDataService(
        cacheManager: getIt<SessionStreamCacheManager>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        taskRepository: getIt<TaskRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<SessionAllocationCacheService>(
      () => SessionAllocationCacheService(
        cacheManager: getIt<SessionStreamCacheManager>(),
        sessionDayKeyService: getIt<SessionDayKeyService>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        projectNextActionsRepository:
            getIt<ProjectNextActionsRepositoryContract>(),
        projectAnchorStateRepository:
            getIt<ProjectAnchorStateRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<AttentionTemporalInvalidationService>(
      () => AttentionTemporalInvalidationService(
        temporalTriggerService: getIt<TemporalTriggerService>(),
      ),
    )
    ..registerLazySingleton<AllocationOrchestrator>(
      () => AllocationOrchestrator(
        taskRepository: getIt<TaskRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        analyticsService: getIt<AnalyticsService>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        projectNextActionsRepository:
            getIt<ProjectNextActionsRepositoryContract>(),
        projectAnchorStateRepository:
            getIt<ProjectAnchorStateRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerLazySingleton<TaskSuggestionService>(
      () => TaskSuggestionService(
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerLazySingleton<OccurrenceCommandService>(
      () => OccurrenceCommandService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
      ),
    )
    ..registerLazySingleton<TaskWriteService>(
      () => TaskWriteService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        occurrenceCommandService: getIt<OccurrenceCommandService>(),
      ),
    )
    ..registerLazySingleton<ProjectWriteService>(
      () => ProjectWriteService(
        projectRepository: getIt<ProjectRepositoryContract>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        occurrenceCommandService: getIt<OccurrenceCommandService>(),
      ),
    )
    ..registerLazySingleton<ValueWriteService>(
      () => ValueWriteService(
        valueRepository: getIt<ValueRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<RoutineWriteService>(
      () => RoutineWriteService(
        routineRepository: getIt<RoutineRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<ScheduledOccurrencesService>(
      () => ScheduledOccurrencesService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        occurrenceReadService: getIt<OccurrenceReadService>(),
      ),
    )
    ..registerLazySingleton<TaskStatsCalculator>(TaskStatsCalculator.new)
    // Attention repository binding is owned by taskly_data module.
    ..registerLazySingleton<attention_engine_v2_impl.AttentionEngine>(
      () => attention_engine_v2_impl.AttentionEngine(
        attentionRepository:
            getIt<attention_repo_v2.AttentionRepositoryContract>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        projectNextActionsRepository:
            getIt<ProjectNextActionsRepositoryContract>(),
        invalidations:
            getIt<AttentionTemporalInvalidationService>().invalidations,
        clock: getIt<Clock>(),
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
    ..registerLazySingleton<AttentionResolutionService>(
      () => AttentionResolutionService(
        repository: getIt<attention_repo_v2.AttentionRepositoryContract>(),
        newResolutionId: getIt<IdGenerator>().attentionResolutionId,
      ),
    )
    // Debug/maintenance services (used by Settings in debug builds)
    ..registerLazySingleton<TemplateDataService>(
      () => TemplateDataService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        routineRepository: getIt<RoutineRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        myDayRepository: getIt<MyDayRepositoryContract>(),
      ),
    )
    ..registerLazySingleton<AuthenticatedAppServicesCoordinator>(
      () => AuthenticatedAppServicesCoordinator(
        dataStack: getIt<TasklyDataStack>(),
        homeDayKeyService: getIt<HomeDayKeyService>(),
        appLifecycleService: getIt<AppLifecycleService>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
        attentionTemporalInvalidationService:
            getIt<AttentionTemporalInvalidationService>(),
        attentionPrewarmService: getIt<AttentionPrewarmService>(),
      ),
    )
    // Presentation BLoCs/Cubits
    ..registerFactory<JournalTodayBloc>(
      () => JournalTodayBloc(
        repository: getIt<JournalRepositoryContract>(),
      ),
    )
    ..registerFactory<JournalHistoryBloc>(
      () => JournalHistoryBloc(
        repository: getIt<JournalRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
      ),
    )
    ..registerFactory<MyDayGateBloc>(
      () => MyDayGateBloc(
        queryService: getIt<MyDayGateQueryService>(),
      ),
    )
    ..registerLazySingleton<MyDayGateQueryService>(
      () => MyDayGateQueryService(
        valueRepository: getIt<ValueRepositoryContract>(),
        sharedDataService: getIt<SessionSharedDataService>(),
      ),
    )
    ..registerFactory<MyDayQueryService>(
      () => MyDayQueryService(
        taskRepository: getIt<TaskRepositoryContract>(),
        myDayRepository: getIt<MyDayRepositoryContract>(),
        ritualStatusService: getIt<MyDayRitualStatusService>(),
        routineRepository: getIt<RoutineRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
        allocationCacheService: getIt<SessionAllocationCacheService>(),
        sharedDataService: getIt<SessionSharedDataService>(),
      ),
    )
    ..registerLazySingleton<MyDaySessionQueryService>(
      () => MyDaySessionQueryService(
        queryService: getIt<MyDayQueryService>(),
        cacheManager: getIt<SessionStreamCacheManager>(),
      ),
    )
    ..registerLazySingleton<ScheduledSessionQueryService>(
      () => ScheduledSessionQueryService(
        scheduledOccurrencesService: getIt<ScheduledOccurrencesService>(),
        sessionDayKeyService: getIt<SessionDayKeyService>(),
        cacheManager: getIt<SessionStreamCacheManager>(),
      ),
    )
    ..registerLazySingleton<AnytimeSessionQueryService>(
      () => AnytimeSessionQueryService(
        projectRepository: getIt<ProjectRepositoryContract>(),
        cacheManager: getIt<SessionStreamCacheManager>(),
        sharedDataService: getIt<SessionSharedDataService>(),
      ),
    )
    ..registerLazySingleton<PresentationSessionServicesCoordinator>(
      () => PresentationSessionServicesCoordinator(
        sessionDayKeyService: getIt<SessionDayKeyService>(),
        sessionStreamCacheManager: getIt<SessionStreamCacheManager>(),
        sharedDataService: getIt<SessionSharedDataService>(),
        allocationCacheService: getIt<SessionAllocationCacheService>(),
        myDaySessionQueryService: getIt<MyDaySessionQueryService>(),
        scheduledSessionQueryService: getIt<ScheduledSessionQueryService>(),
        anytimeSessionQueryService: getIt<AnytimeSessionQueryService>(),
      ),
    )
    ..registerFactory<MyDayBloc>(
      () => MyDayBloc(
        queryService: getIt<MyDaySessionQueryService>(),
        routineWriteService: getIt<RoutineWriteService>(),
        nowService: getIt<NowService>(),
      ),
    )
    ..registerFactory<PlanMyDayBloc>(
      () => PlanMyDayBloc(
        settingsRepository: getIt<SettingsRepositoryContract>(),
        myDayRepository: getIt<MyDayRepositoryContract>(),
        taskSuggestionService: getIt<TaskSuggestionService>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        routineRepository: getIt<RoutineRepositoryContract>(),
        taskWriteService: getIt<TaskWriteService>(),
        routineWriteService: getIt<RoutineWriteService>(),
        dayKeyService: getIt<HomeDayKeyService>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
        nowService: getIt<NowService>(),
      ),
    )
    ..registerFactory<SettingsMaintenanceBloc>(
      () => SettingsMaintenanceBloc(
        templateDataService: getIt<TemplateDataService>(),
      ),
    )
    ..registerFactory<AllocationSettingsBloc>(
      () => AllocationSettingsBloc(
        settingsRepository: getIt<SettingsRepositoryContract>(),
      ),
    );
}
