import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_data/src/attention/repositories/attention_repository_v2.dart'
    as attention_repo_v2_impl;
import 'package:taskly_data/src/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_data/src/features/analytics/services/analytics_service_impl.dart';
import 'package:taskly_data/src/features/journal/repositories/journal_repository_impl.dart';
import 'package:taskly_data/src/features/my_day/repositories/my_day_repository_impl.dart';
import 'package:taskly_data/src/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_data/src/features/notifications/services/logging_notification_presenter.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/api_connector.dart';
import 'package:taskly_data/src/infrastructure/supabase/supabase.dart';
import 'package:taskly_data/src/repositories/auth_repository.dart';
import 'package:taskly_data/src/repositories/project_repository.dart';
import 'package:taskly_data/src/repositories/settings_repository.dart';
import 'package:taskly_data/src/repositories/task_repository.dart';
import 'package:taskly_data/src/repositories/value_repository.dart';
import 'package:taskly_data/src/services/occurrence_stream_expander.dart';
import 'package:taskly_data/src/services/occurrence_write_helper.dart';
import 'package:taskly_data/src/services/sync/powersync_initial_sync_service.dart';

/// Strongly-typed bindings for Taskly's day-1 data stack.
///
/// The app composition root can register these into its DI container without
/// importing `taskly_data` implementation classes.
final class TasklyDataBindings {
  const TasklyDataBindings({
    required this.driftDb,
    required this.idGenerator,
    required this.authRepository,
    required this.localDataMaintenanceService,
    required this.projectRepository,
    required this.taskRepository,
    required this.valueRepository,
    required this.myDayRepository,
    required this.settingsRepository,
    required this.homeDayKeyService,
    required this.attentionRepository,
    required this.analyticsRepository,
    required this.journalRepository,
    required this.analyticsService,
    required this.notificationPresenter,
    required this.pendingNotificationsRepository,
    required this.pendingNotificationsProcessor,
    required this.initialSyncService,
  });

  final AppDatabase driftDb;
  final IdGenerator idGenerator;
  final AuthRepositoryContract authRepository;
  final LocalDataMaintenanceService localDataMaintenanceService;

  final ProjectRepositoryContract projectRepository;
  final TaskRepositoryContract taskRepository;
  final ValueRepositoryContract valueRepository;
  final MyDayRepositoryContract myDayRepository;
  final SettingsRepositoryContract settingsRepository;
  final HomeDayKeyService homeDayKeyService;
  final AttentionRepositoryContract attentionRepository;

  final AnalyticsRepositoryContract analyticsRepository;
  final JournalRepositoryContract journalRepository;
  final AnalyticsService analyticsService;

  final NotificationPresenter notificationPresenter;
  final PendingNotificationsRepositoryContract pendingNotificationsRepository;
  final PendingNotificationsProcessor pendingNotificationsProcessor;

  final InitialSyncService initialSyncService;
}

/// Strongly-typed handles for the day-1 data stack.
///
/// This is intentionally the only place that knows the exact wiring between
/// Supabase, PowerSync, and Drift.
final class TasklyDataStack implements SyncAnomalyStream {
  TasklyDataStack._({
    required this.supabaseClient,
    required this.syncDb,
    required this.driftDb,
    required this.idGenerator,
    required this.authRepository,
    required this.localDataMaintenanceService,
  });

  /// Supabase client (auth + PostgREST).
  final SupabaseClient supabaseClient;

  /// PowerSync database (sync runtime) backing the local SQLite file.
  final PowerSyncDatabase syncDb;

  /// Drift database connection on top of the PowerSync SQLite database.
  final AppDatabase driftDb;

  /// ID generator (lazy userId resolution).
  final IdGenerator idGenerator;

  /// Auth repository implementation.
  final AuthRepositoryContract authRepository;

  /// Local maintenance service implementation.
  final LocalDataMaintenanceService localDataMaintenanceService;

  final StreamController<SyncAnomaly> _syncAnomaliesController =
      StreamController<SyncAnomaly>.broadcast();

  @override
  Stream<SyncAnomaly> get anomalies => _syncAnomaliesController.stream;

  SupabaseConnector? _connector;
  String? _sessionUserId;
  bool _sessionStarted = false;

  bool get isSessionStarted => _sessionStarted;

  /// Initialize the full day-1 data stack.
  ///
  /// The stack is safe to initialize before authentication.
  /// When the user signs in, PowerSync connects and post-auth maintenance
  /// runs (seeders/cleanup).
  static Future<TasklyDataStack> initialize({
    String? powersyncPathOverride,
  }) async {
    await loadSupabase();

    late AppDatabase driftDb;
    late IdGenerator idGenerator;

    final syncDb = await openDatabase(pathOverride: powersyncPathOverride);

    driftDb = AppDatabase(
      DatabaseConnection(SqliteAsyncDriftConnection(syncDb)),
    );

    idGenerator = IdGenerator(() {
      final userId = getUserId();
      if (userId == null) {
        throw StateError('IdGenerator requires authenticated user');
      }
      return userId;
    });

    final supabaseClient = Supabase.instance.client;

    final stack = TasklyDataStack._(
      supabaseClient: supabaseClient,
      syncDb: syncDb,
      driftDb: driftDb,
      idGenerator: idGenerator,
      authRepository: AuthRepository(client: supabaseClient),
      localDataMaintenanceService: _PowerSyncLocalDataMaintenanceService(
        syncDb,
      ),
    );

    return stack;
  }

  /// Starts the authenticated sync session.
  ///
  /// This connects PowerSync and runs post-auth maintenance (seeders/cleanup).
  ///
  /// Idempotent for the same user.
  Future<void> startSession() async {
    final userId = getUserId();
    if (userId == null) {
      talker.info('[data_stack] startSession skipped (no authenticated user)');
      return;
    }

    if (_sessionStarted && _sessionUserId == userId) return;

    // If the user changed without an explicit stop, avoid cross-user leakage.
    if (_sessionStarted && _sessionUserId != null && _sessionUserId != userId) {
      await stopSession(reason: 'user switch', clearLocalData: true);
    }

    talker.info('[data_stack] Starting session (userId=$userId)');
    _connector = SupabaseConnector(
      syncDb,
      onAnomaly: _syncAnomaliesController.add,
    );
    await syncDb.connect(connector: _connector!);

    await runPostAuthMaintenance(driftDb: driftDb, idGenerator: idGenerator);

    _sessionUserId = userId;
    _sessionStarted = true;
  }

  /// Stops the authenticated sync session.
  ///
  /// When [clearLocalData] is true, local user-scoped tables are cleared.
  Future<void> stopSession({
    required String reason,
    required bool clearLocalData,
  }) async {
    talker.info('[data_stack] Stopping session ($reason)');

    _connector = null;
    _sessionUserId = null;
    _sessionStarted = false;

    try {
      await syncDb.disconnect();
    } catch (_) {}

    if (clearLocalData) {
      await localDataMaintenanceService.clearLocalData();
    }
  }

  /// Best-effort cleanup.
  ///
  /// In most app lifecycles this is not needed, but it is useful for tests.
  Future<void> dispose() async {
    try {
      await syncDb.disconnect();
    } catch (_) {}

    await driftDb.close();

    await _syncAnomaliesController.close();
  }

  /// Creates the app-facing `taskly_domain` contract implementations for this
  /// stack.
  ///
  /// The stack itself owns the wiring between infra + repositories. The app
  /// provides occurrence services (still owned outside of `taskly_data` today).
  TasklyDataBindings createBindings({
    Clock clock = systemClock,
  }) {
    final settingsRepository = SettingsRepository(driftDb: driftDb);

    final homeDayKeyService = HomeDayKeyService(
      settingsRepository: settingsRepository,
      clock: clock,
    );

    final occurrenceExpander = OccurrenceStreamExpander(clock: clock);
    final occurrenceWriteHelper = OccurrenceWriteHelper(
      driftDb: driftDb,
      idGenerator: idGenerator,
      clock: clock,
    );

    final projectRepository = ProjectRepository(
      driftDb: driftDb,
      occurrenceExpander: occurrenceExpander,
      occurrenceWriteHelper: occurrenceWriteHelper,
      idGenerator: idGenerator,
      dayKeyService: homeDayKeyService,
    );

    final taskRepository = TaskRepository(
      driftDb: driftDb,
      occurrenceExpander: occurrenceExpander,
      occurrenceWriteHelper: occurrenceWriteHelper,
      idGenerator: idGenerator,
      dayKeyService: homeDayKeyService,
    );

    final valueRepository = ValueRepository(
      driftDb: driftDb,
      idGenerator: idGenerator,
    );

    final myDayRepository = MyDayRepositoryImpl(
      driftDb: driftDb,
      ids: idGenerator,
    );

    final attentionRepository = attention_repo_v2_impl.AttentionRepositoryV2(
      db: driftDb,
    );

    final analyticsRepository = AnalyticsRepositoryImpl(driftDb, idGenerator);

    final journalRepository = JournalRepositoryImpl(driftDb, idGenerator);

    final analyticsService = AnalyticsServiceImpl(
      taskRepo: taskRepository,
      projectRepo: projectRepository,
      valueRepo: valueRepository,
      journalRepo: journalRepository,
      analyticsRepo: analyticsRepository,
      dayKeyService: homeDayKeyService,
      clock: clock,
    );

    final notificationPresenter = LoggingNotificationPresenter().call;

    final pendingNotificationsRepository = PendingNotificationsRepositoryImpl(
      driftDb,
    );

    final pendingNotificationsProcessor = PendingNotificationsProcessor(
      repository: pendingNotificationsRepository,
      presenter: notificationPresenter,
    );

    final initialSyncService = PowerSyncInitialSyncService(syncDb);

    return TasklyDataBindings(
      driftDb: driftDb,
      idGenerator: idGenerator,
      authRepository: authRepository,
      localDataMaintenanceService: localDataMaintenanceService,
      projectRepository: projectRepository,
      taskRepository: taskRepository,
      valueRepository: valueRepository,
      myDayRepository: myDayRepository,
      settingsRepository: settingsRepository,
      homeDayKeyService: homeDayKeyService,
      attentionRepository: attentionRepository,
      analyticsRepository: analyticsRepository,
      journalRepository: journalRepository,
      analyticsService: analyticsService,
      notificationPresenter: notificationPresenter,
      pendingNotificationsRepository: pendingNotificationsRepository,
      pendingNotificationsProcessor: pendingNotificationsProcessor,
      initialSyncService: initialSyncService,
    );
  }
}

final class _PowerSyncLocalDataMaintenanceService
    implements LocalDataMaintenanceService {
  _PowerSyncLocalDataMaintenanceService(this._database);

  final PowerSyncDatabase _database;

  @override
  Future<void> clearLocalData() async {
    await _database.disconnect();
    await _database.disconnectedAndClear();
  }
}
