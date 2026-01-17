import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/data/id/id_generator.dart';
import 'package:taskly_data/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/data/infrastructure/powersync/api_connector.dart';
import 'package:taskly_data/data/infrastructure/supabase/supabase.dart';
import 'package:taskly_data/data/repositories/auth_repository.dart';
import 'package:taskly_domain/taskly_domain.dart';

/// Strongly-typed handles for the day-1 data stack.
///
/// This is intentionally the only place that knows the exact wiring between
/// Supabase, PowerSync, and Drift.
final class TasklyDataStack {
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

  /// Initialize the full day-1 data stack.
  ///
  /// The stack is safe to initialize before authentication.
  /// When the user signs in, PowerSync connects and post-auth maintenance
  /// runs (seeders/cleanup).
  static Future<TasklyDataStack> initialize({
    String? powersyncPathOverride,
    Future<void> Function()? onAuthenticated,
  }) async {
    await loadSupabase();

    late AppDatabase driftDb;
    late IdGenerator idGenerator;

    var isFullyInitialized = false;
    var authCallbackFiredBeforeInit = false;

    final syncDb = await openDatabase(
      pathOverride: powersyncPathOverride,
      onAuthenticated: () async {
        if (!isFullyInitialized) {
          authCallbackFiredBeforeInit = true;
          return;
        }

        await runPostAuthMaintenance(
          driftDb: driftDb,
          idGenerator: idGenerator,
        );
        await onAuthenticated?.call();
      },
    );

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

    isFullyInitialized = true;

    // If openDatabase already authenticated and fired the callback, we skipped it
    // until Drift + IdGenerator were ready.
    if (authCallbackFiredBeforeInit || isLoggedIn()) {
      talker.debug('[data_stack] Running deferred post-auth maintenance');
      await runPostAuthMaintenance(driftDb: driftDb, idGenerator: idGenerator);
      await onAuthenticated?.call();
    }

    return stack;
  }

  /// Best-effort cleanup.
  ///
  /// In most app lifecycles this is not needed, but it is useful for tests.
  Future<void> dispose() async {
    try {
      await syncDb.disconnect();
    } catch (_) {}

    await driftDb.close();
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
