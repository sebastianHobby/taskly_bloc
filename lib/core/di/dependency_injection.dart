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
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_inbox_bloc.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_rules_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_bell_cubit.dart';
import 'package:taskly_bloc/presentation/features/attention/bloc/attention_banner_session_cubit.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_history_bloc.dart';
import 'package:taskly_bloc/presentation/features/journal/bloc/journal_today_bloc.dart';
import 'package:taskly_bloc/presentation/features/settings/bloc/settings_maintenance_cubit.dart';
import 'package:taskly_bloc/presentation/features/app/bloc/my_day_prewarm_cubit.dart';

import 'package:taskly_bloc/core/startup/authenticated_app_services_coordinator.dart';

import 'package:taskly_bloc/presentation/screens/bloc/my_day_gate_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_bloc.dart';
import 'package:taskly_bloc/presentation/screens/services/my_day_query_service.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_header_bloc.dart';
import 'package:taskly_bloc/presentation/screens/bloc/my_day_ritual_bloc.dart';

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
    ..registerSingleton<TaskRepositoryContract>(
      getIt<TasklyDataBindings>().taskRepository,
    )
    ..registerSingleton<ValueRepositoryContract>(
      getIt<TasklyDataBindings>().valueRepository,
    )
    ..registerSingleton<SettingsRepositoryContract>(
      getIt<TasklyDataBindings>().settingsRepository,
    )
    ..registerSingleton<MyDayRepositoryContract>(
      getIt<TasklyDataBindings>().myDayRepository,
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
    ..registerLazySingleton<TemporalTriggerService>(
      () => TemporalTriggerService(
        dayKeyService: getIt<HomeDayKeyService>(),
        lifecycleService: getIt<AppLifecycleService>(),
        clock: getIt<Clock>(),
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
    // Entity action service for cross-screen entity mutations.
    ..registerLazySingleton<EntityActionService>(
      () => EntityActionService(
        taskRepository: getIt<TaskRepositoryContract>(),
        projectRepository: getIt<ProjectRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        occurrenceCommandService: getIt<OccurrenceCommandService>(),
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
        valueRepository: getIt<ValueRepositoryContract>(),
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
    ..registerFactory<AttentionInboxBloc>(
      () => AttentionInboxBloc(
        engine: getIt<attention_engine_v2.AttentionEngineContract>(),
        resolutionService: getIt<AttentionResolutionService>(),
        nowService: getIt<NowService>(),
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
      () => JournalTodayBloc(
        repository: getIt<JournalRepositoryContract>(),
        nowUtc: getIt<NowService>().nowUtc,
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
        settingsRepository: getIt<SettingsRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
      ),
    )
    ..registerFactory<MyDayPrewarmCubit>(
      () => MyDayPrewarmCubit(
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        myDayRepository: getIt<MyDayRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
      ),
    )
    ..registerFactory<MyDayQueryService>(
      () => MyDayQueryService(
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        valueRepository: getIt<ValueRepositoryContract>(),
        settingsRepository: getIt<SettingsRepositoryContract>(),
        myDayRepository: getIt<MyDayRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
      ),
    )
    ..registerFactory<MyDayBloc>(
      () => MyDayBloc(
        queryService: getIt<MyDayQueryService>(),
      ),
    )
    ..registerFactory<MyDayRitualBloc>(
      () => MyDayRitualBloc(
        settingsRepository: getIt<SettingsRepositoryContract>(),
        myDayRepository: getIt<MyDayRepositoryContract>(),
        allocationOrchestrator: getIt<AllocationOrchestrator>(),
        taskRepository: getIt<TaskRepositoryContract>(),
        dayKeyService: getIt<HomeDayKeyService>(),
        temporalTriggerService: getIt<TemporalTriggerService>(),
        nowService: getIt<NowService>(),
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
      ),
    );
}
