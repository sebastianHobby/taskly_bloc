import 'package:get_it/get_it.dart';
import 'package:taskly_data/data/allocation/repositories/allocation_snapshot_repository.dart';
import 'package:taskly_data/data/attention/repositories/attention_repository_v2.dart'
    as attention_repo_v2_impl;
import 'package:taskly_data/data/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_data/data/features/analytics/services/analytics_service_impl.dart';
import 'package:taskly_data/data/features/journal/repositories/journal_repository_impl.dart';
import 'package:taskly_data/data/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_data/data/features/notifications/services/logging_notification_presenter.dart';
import 'package:taskly_data/data/id/id_generator.dart';
import 'package:taskly_data/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/data/repositories/project_repository.dart';
import 'package:taskly_data/data/repositories/settings_repository.dart';
import 'package:taskly_data/data/repositories/task_repository.dart';
import 'package:taskly_data/data/repositories/value_repository.dart';
import 'package:taskly_data/data_stack.dart';
import 'package:taskly_domain/taskly_domain.dart';

/// Registers `taskly_data` implementations into the provided [GetIt] container.
///
/// This keeps the app composition root from importing `taskly_data` internals
/// (repositories, infra, etc). The app should only:
/// - initialize [TasklyDataStack]
/// - call this function
void registerTasklyData(GetIt getIt, TasklyDataStack stack) {
  // Low-level handles (registered for internal consumers).
  getIt
    ..registerSingleton<AppDatabase>(stack.driftDb)
    ..registerLazySingleton<IdGenerator>(() => stack.idGenerator)
    // Domain contracts.
    ..registerLazySingleton<AuthRepositoryContract>(() => stack.authRepository)
    ..registerLazySingleton<LocalDataMaintenanceService>(
      () => stack.localDataMaintenanceService,
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
    ..registerLazySingleton<AllocationSnapshotRepositoryContract>(
      () => AllocationSnapshotRepository(db: getIt<AppDatabase>()),
    )
    ..registerLazySingleton<AttentionRepositoryContract>(
      () => attention_repo_v2_impl.AttentionRepositoryV2(
        db: getIt<AppDatabase>(),
      ),
    )
    ..registerLazySingleton<AnalyticsRepositoryContract>(
      () => AnalyticsRepositoryImpl(
        getIt<AppDatabase>(),
        getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<JournalRepositoryContract>(
      () => JournalRepositoryImpl(
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
    // Notifications.
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
}
