import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:flutter/foundation.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_core/env.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/taskly_domain.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_data/src/attention/repositories/attention_repository_v2.dart'
    as attention_repo_v2_impl;
import 'package:taskly_data/src/features/analytics/repositories/analytics_repository_impl.dart';
import 'package:taskly_data/src/features/analytics/services/analytics_service_impl.dart';
import 'package:taskly_data/src/features/journal/repositories/journal_repository_impl.dart';
import 'package:taskly_data/src/features/my_day/repositories/my_day_decision_event_repository_impl.dart';
import 'package:taskly_data/src/features/my_day/repositories/my_day_repository_impl.dart';
import 'package:taskly_data/src/features/notifications/repositories/pending_notifications_repository_impl.dart';
import 'package:taskly_data/src/features/notifications/services/logging_notification_presenter.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/powersync/api_connector.dart';
import 'package:taskly_data/src/infrastructure/powersync/identifier_hash.dart';
import 'package:taskly_data/src/infrastructure/powersync/powersync_status_stream.dart';
import 'package:taskly_data/src/infrastructure/supabase/supabase.dart';
import 'package:taskly_data/src/repositories/auth_repository.dart';
import 'package:taskly_data/src/repositories/project_anchor_state_repository.dart';
import 'package:taskly_data/src/repositories/project_repository.dart';
import 'package:taskly_data/src/repositories/routine_repository.dart';
import 'package:taskly_data/src/repositories/routine_checklist_repository.dart';
import 'package:taskly_data/src/repositories/settings_repository.dart';
import 'package:taskly_data/src/repositories/sync_issue_repository.dart';
import 'package:taskly_data/src/repositories/task_repository.dart';
import 'package:taskly_data/src/repositories/task_checklist_repository.dart';
import 'package:taskly_data/src/repositories/value_repository.dart';
import 'package:taskly_data/src/repositories/value_ratings_repository.dart';
import 'package:taskly_data/src/services/occurrence_write_helper.dart';
import 'package:taskly_data/src/services/maintenance/user_data_wipe_service_impl.dart';
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
    required this.userDataWipeService,
    required this.projectRepository,
    required this.projectAnchorStateRepository,
    required this.taskRepository,
    required this.valueRepository,
    required this.valueRatingsRepository,
    required this.myDayRepository,
    required this.myDayDecisionEventRepository,
    required this.routineRepository,
    required this.taskChecklistRepository,
    required this.routineChecklistRepository,
    required this.settingsRepository,
    required this.homeDayKeyService,
    required this.occurrenceReadService,
    required this.attentionRepository,
    required this.analyticsRepository,
    required this.journalRepository,
    required this.analyticsService,
    required this.notificationPresenter,
    required this.pendingNotificationsRepository,
    required this.pendingNotificationsProcessor,
    required this.initialSyncService,
    required this.syncIssueRepository,
  });

  final AppDatabase driftDb;
  final IdGenerator idGenerator;
  final AuthRepositoryContract authRepository;
  final LocalDataMaintenanceService localDataMaintenanceService;
  final UserDataWipeService userDataWipeService;

  final ProjectRepositoryContract projectRepository;
  final ProjectAnchorStateRepositoryContract projectAnchorStateRepository;
  final TaskRepositoryContract taskRepository;
  final ValueRepositoryContract valueRepository;
  final ValueRatingsRepositoryContract valueRatingsRepository;
  final MyDayRepositoryContract myDayRepository;
  final MyDayDecisionEventRepositoryContract myDayDecisionEventRepository;
  final RoutineRepositoryContract routineRepository;
  final TaskChecklistRepositoryContract taskChecklistRepository;
  final RoutineChecklistRepositoryContract routineChecklistRepository;
  final SettingsRepositoryContract settingsRepository;
  final HomeDayKeyService homeDayKeyService;
  final OccurrenceReadService occurrenceReadService;
  final AttentionRepositoryContract attentionRepository;

  final AnalyticsRepositoryContract analyticsRepository;
  final JournalRepositoryContract journalRepository;
  final AnalyticsService analyticsService;

  final NotificationPresenter notificationPresenter;
  final PendingNotificationsRepositoryContract pendingNotificationsRepository;
  final PendingNotificationsProcessor pendingNotificationsProcessor;

  final InitialSyncService initialSyncService;
  final SyncIssueRepositoryContract syncIssueRepository;
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
    required this.syncIssueRepository,
    required Clock clock,
  }) : _clock = clock;

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
  final SyncIssueRepositoryContract syncIssueRepository;
  final Clock _clock;

  final StreamController<SyncAnomaly> _syncAnomaliesController =
      StreamController<SyncAnomaly>.broadcast();

  @override
  /// Stream contract:
  /// - broadcast: yes
  /// - replay: none
  /// - cold/hot: hot
  Stream<SyncAnomaly> get anomalies => _syncAnomaliesController.stream;

  SupabaseConnector? _connector;
  String? _sessionUserId;
  String? _syncSessionId;
  StreamSubscription<SyncStatus>? _statusSubscription;
  _SyncStatusSnapshot? _lastStatusSnapshot;
  DateTime? _lastStatusSnapshotLogAt;
  int _sessionSequence = 0;
  bool _sessionStarted = false;

  bool get isSessionStarted => _sessionStarted;

  /// Initialize the full day-1 data stack.
  ///
  /// The stack is safe to initialize before authentication.
  /// When the user signs in, PowerSync connects and post-auth maintenance
  /// runs (seeders/cleanup).
  static Future<TasklyDataStack> initialize({
    String? powersyncPathOverride,
    Clock clock = systemClock,
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
      syncIssueRepository: SyncIssueRepository(client: supabaseClient),
      clock: clock,
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

    final clientId = await syncDb.getClientId();
    final syncSessionId = _nextSyncSessionId(clientId: clientId);
    final userIdHash = _hashIdentifier(userId);
    final appMetadata = <String, String>{
      'client_id': clientId,
      'app_version': _appVersion(),
      'build_sha': _buildSha(),
      'platform': _platformLabel(),
      'env': _envName(),
      'sync_session_id': syncSessionId,
      ...?userIdHash == null
          ? null
          : <String, String>{'user_id_hash': userIdHash},
    };

    AppLog.infoStructured(
      'sync',
      'sync.connect.start',
      fields: <String, Object?>{
        'sync_session_id': syncSessionId,
        'client_id': clientId,
        'env': _envName(),
      },
    );

    _connector = SupabaseConnector(
      syncDb,
      onAnomaly: _syncAnomaliesController.add,
      onRecordSyncIssue: syncIssueRepository.recordAnomaly,
      syncSessionId: syncSessionId,
      clientId: clientId,
      userIdHash: userIdHash,
    );
    try {
      await syncDb.connect(
        connector: _connector!,
        options: SyncOptions(appMetadata: appMetadata),
      );
      _syncSessionId = syncSessionId;
      await _startStatusTelemetry(
        syncSessionId: syncSessionId,
        clientId: clientId,
      );
      AppLog.infoStructured(
        'sync',
        'sync.connect.success',
        fields: <String, Object?>{
          'sync_session_id': syncSessionId,
          'client_id': clientId,
        },
      );
    } catch (error, stackTrace) {
      _connector = null;
      AppLog.handleStructured(
        'sync',
        'sync.connect.fail',
        error,
        stackTrace,
        <String, Object?>{
          'sync_session_id': syncSessionId,
          'client_id': clientId,
          'env': _envName(),
          'platform': _platformLabel(),
        },
      );
      rethrow;
    }

    try {
      await runPostAuthMaintenance(driftDb: driftDb, idGenerator: idGenerator);
    } catch (error, stackTrace) {
      AppLog.handleStructured(
        'sync',
        'sync.post_auth_maintenance.fail',
        error,
        stackTrace,
        <String, Object?>{
          'sync_session_id': syncSessionId,
          'client_id': clientId,
          'env': _envName(),
          'platform': _platformLabel(),
        },
      );

      await _statusSubscription?.cancel();
      _statusSubscription = null;
      _lastStatusSnapshot = null;
      _lastStatusSnapshotLogAt = null;

      _connector = null;
      _sessionUserId = null;
      _syncSessionId = null;
      _sessionStarted = false;

      try {
        await syncDb.disconnect();
      } catch (_) {}

      rethrow;
    }

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
    AppLog.infoStructured(
      'sync',
      'sync.connect.stop',
      fields: <String, Object?>{
        'reason': reason,
        'sync_session_id': _syncSessionId ?? '<none>',
      },
    );

    await _statusSubscription?.cancel();
    _statusSubscription = null;
    _lastStatusSnapshot = null;
    _lastStatusSnapshotLogAt = null;

    _connector = null;
    _sessionUserId = null;
    _syncSessionId = null;
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
    await _statusSubscription?.cancel();
    _statusSubscription = null;
    _lastStatusSnapshotLogAt = null;

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
  /// consumes domain services via the returned bindings.
  TasklyDataBindings createBindings({Clock clock = systemClock}) {
    final settingsRepository = SettingsRepository(
      driftDb: driftDb,
      clock: clock,
    );

    final homeDayKeyService = HomeDayKeyService(
      settingsRepository: settingsRepository,
      clock: clock,
    );

    final myDayDecisionEventRepository = MyDayDecisionEventRepositoryImpl(
      driftDb: driftDb,
      ids: idGenerator,
      clock: clock,
    );

    final occurrenceExpander = OccurrenceStreamExpander(clock: clock);
    final occurrenceWriteHelper = OccurrenceWriteHelper(
      driftDb: driftDb,
      idGenerator: idGenerator,
      decisionEventsRepository: myDayDecisionEventRepository,
      clock: clock,
    );

    final projectRepository = ProjectRepository(
      driftDb: driftDb,
      occurrenceExpander: occurrenceExpander,
      occurrenceWriteHelper: occurrenceWriteHelper,
      idGenerator: idGenerator,
      clock: clock,
    );

    final projectAnchorStateRepository = ProjectAnchorStateRepository(
      driftDb: driftDb,
      idGenerator: idGenerator,
      clock: clock,
    );

    final taskRepository = TaskRepository(
      driftDb: driftDb,
      occurrenceExpander: occurrenceExpander,
      occurrenceWriteHelper: occurrenceWriteHelper,
      idGenerator: idGenerator,
      decisionEventsRepository: myDayDecisionEventRepository,
      clock: clock,
    );

    final valueRepository = ValueRepository(
      driftDb: driftDb,
      idGenerator: idGenerator,
      clock: clock,
    );

    final valueRatingsRepository = ValueRatingsRepository(
      driftDb: driftDb,
      idGenerator: idGenerator,
      clock: clock,
    );

    final myDayRepository = MyDayRepositoryImpl(
      driftDb: driftDb,
      ids: idGenerator,
      decisionEventsRepository: myDayDecisionEventRepository,
      clock: clock,
    );

    final routineRepository = RoutineRepository(
      driftDb: driftDb,
      idGenerator: idGenerator,
      decisionEventsRepository: myDayDecisionEventRepository,
      clock: clock,
    );
    final taskChecklistRepository = TaskChecklistRepository(
      driftDb: driftDb,
      idGenerator: idGenerator,
      clock: clock,
    );
    final routineChecklistRepository = RoutineChecklistRepository(
      driftDb: driftDb,
      idGenerator: idGenerator,
      clock: clock,
    );

    final attentionRepository = attention_repo_v2_impl.AttentionRepositoryV2(
      db: driftDb,
      clock: clock,
    );

    final analyticsRepository = AnalyticsRepositoryImpl(
      driftDb,
      idGenerator,
      clock: clock,
    );

    final journalRepository = JournalRepositoryImpl(
      driftDb,
      idGenerator,
      clock: clock,
    );

    final occurrenceReadService = OccurrenceReadService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      dayKeyService: homeDayKeyService,
      occurrenceExpander: occurrenceExpander,
    );

    final analyticsService = AnalyticsServiceImpl(
      taskRepo: taskRepository,
      projectRepo: projectRepository,
      valueRepo: valueRepository,
      journalRepo: journalRepository,
      analyticsRepo: analyticsRepository,
      dayKeyService: homeDayKeyService,
      occurrenceReadService: occurrenceReadService,
      clock: clock,
    );

    final notificationPresenter = LoggingNotificationPresenter().call;

    final pendingNotificationsRepository = PendingNotificationsRepositoryImpl(
      driftDb,
      clock: clock,
    );

    final pendingNotificationsProcessor = PendingNotificationsProcessor(
      repository: pendingNotificationsRepository,
      presenter: notificationPresenter,
    );

    final initialSyncService = PowerSyncInitialSyncService(syncDb);
    final userDataWipeService = PowerSyncUserDataWipeService(
      driftDb: driftDb,
      syncDb: syncDb,
      clock: clock,
    );

    return TasklyDataBindings(
      driftDb: driftDb,
      idGenerator: idGenerator,
      authRepository: authRepository,
      localDataMaintenanceService: localDataMaintenanceService,
      userDataWipeService: userDataWipeService,
      projectRepository: projectRepository,
      projectAnchorStateRepository: projectAnchorStateRepository,
      taskRepository: taskRepository,
      valueRepository: valueRepository,
      valueRatingsRepository: valueRatingsRepository,
      myDayRepository: myDayRepository,
      myDayDecisionEventRepository: myDayDecisionEventRepository,
      routineRepository: routineRepository,
      taskChecklistRepository: taskChecklistRepository,
      routineChecklistRepository: routineChecklistRepository,
      settingsRepository: settingsRepository,
      homeDayKeyService: homeDayKeyService,
      occurrenceReadService: occurrenceReadService,
      attentionRepository: attentionRepository,
      analyticsRepository: analyticsRepository,
      journalRepository: journalRepository,
      analyticsService: analyticsService,
      notificationPresenter: notificationPresenter,
      pendingNotificationsRepository: pendingNotificationsRepository,
      pendingNotificationsProcessor: pendingNotificationsProcessor,
      initialSyncService: initialSyncService,
      syncIssueRepository: syncIssueRepository,
    );
  }

  Future<void> _startStatusTelemetry({
    required String syncSessionId,
    required String clientId,
  }) async {
    await _statusSubscription?.cancel();
    _lastStatusSnapshot = null;
    _lastStatusSnapshotLogAt = null;

    _statusSubscription = sharedPowerSyncStatusStream(syncDb).listen((status) {
      final next = _SyncStatusSnapshot.fromStatus(status);
      final previous = _lastStatusSnapshot;

      if (previous == null || previous != next) {
        AppLog.infoStructured(
          'sync',
          'sync.status.transition',
          fields: <String, Object?>{
            'sync_session_id': syncSessionId,
            'client_id': clientId,
            'connected': next.connected,
            'downloading': next.downloading,
            'uploading': next.uploading,
            'has_synced': next.hasSynced,
            'last_synced_at': status.lastSyncedAt?.toUtc().toIso8601String(),
          },
        );
        _lastStatusSnapshot = next;
      }

      final now = _clock.nowUtc();
      final lastSnapshotAt = _lastStatusSnapshotLogAt;
      final shouldLogSnapshot =
          lastSnapshotAt == null ||
          now.difference(lastSnapshotAt) >= const Duration(seconds: 60);
      if (shouldLogSnapshot) {
        _lastStatusSnapshotLogAt = now;
        AppLog.infoStructured(
          'sync',
          'sync.status.snapshot',
          fields: <String, Object?>{
            'sync_session_id': syncSessionId,
            'client_id': clientId,
            'connected': status.connected,
            'connecting': status.connecting,
            'downloading': status.downloading,
            'uploading': status.uploading,
            'has_synced': status.hasSynced,
            'downloaded_fraction': status.downloadProgress?.downloadedFraction,
            'last_synced_at': status.lastSyncedAt?.toUtc().toIso8601String(),
          },
        );
      }
    });
  }

  String _nextSyncSessionId({required String clientId}) {
    _sessionSequence += 1;
    final epochMs = _clock.nowUtc().millisecondsSinceEpoch;
    return '$clientId:$epochMs:$_sessionSequence';
  }

  static String _platformLabel() {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }

  String _envName() => Env.config?.name ?? 'unknown';

  String _appVersion() {
    final configured = Env.config?.appVersion.trim() ?? '';
    if (configured.isNotEmpty) return configured;
    return const String.fromEnvironment('APP_VERSION', defaultValue: 'unknown');
  }

  String _buildSha() {
    final configured = Env.config?.buildSha.trim() ?? '';
    if (configured.isNotEmpty) return configured;
    return const String.fromEnvironment('BUILD_SHA', defaultValue: 'unknown');
  }

  static String? _hashIdentifier(String? value) {
    return hashIdentifierForTelemetry(value);
  }
}

final class _SyncStatusSnapshot {
  const _SyncStatusSnapshot({
    required this.connected,
    required this.downloading,
    required this.uploading,
    required this.hasSynced,
  });

  factory _SyncStatusSnapshot.fromStatus(SyncStatus status) {
    return _SyncStatusSnapshot(
      connected: status.connected,
      downloading: status.downloading,
      uploading: status.uploading,
      hasSynced: status.hasSynced ?? false,
    );
  }

  final bool connected;
  final bool downloading;
  final bool uploading;
  final bool hasSynced;

  @override
  bool operator ==(Object other) {
    return other is _SyncStatusSnapshot &&
        other.connected == connected &&
        other.downloading == downloading &&
        other.uploading == uploading &&
        other.hasSynced == hasSynced;
  }

  @override
  int get hashCode => Object.hash(connected, downloading, uploading, hasSynced);
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
