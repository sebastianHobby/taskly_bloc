// This file performs setup of the PowerSync database

import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:powersync/powersync.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:taskly_core/env.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/src/infrastructure/powersync/powersync_log_forwarding.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/attention/maintenance/attention_seeder.dart';
import 'package:taskly_data/src/features/journal/maintenance/journal_tracker_seeder.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/powersync/schema.dart';
import 'package:taskly_data/src/infrastructure/powersync/upload_data_normalizer.dart'
    as upload_normalizer;
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/telemetry.dart';

/// Postgres Response codes that we cannot recover from by retrying.
/// Note: 23505 (unique violation) is handled separately in _handle23505.
final List<RegExp> fatalResponseCodes = [
  // Class 22 — Data Exception
  // Examples include data type mismatch.
  RegExp(r'^22...$'),
  // Class 23 — Integrity Constraint Violation (except 23505 handled separately)
  // 23502 = NOT NULL, 23503 = FOREIGN KEY, 23514 = CHECK
  RegExp(r'^2350[234]$'),
  RegExp(r'^23514$'),
  // INSUFFICIENT PRIVILEGE - typically a row-level security violation
  RegExp(r'^42501$'),
];

/// PostgREST error codes that indicate schema mismatch (table doesn't exist).
/// PGRST205: Could not find the table in the schema cache
const _schemaNotFoundCode = 'PGRST205';

Map<String, dynamic> _normalizeUploadData(
  String table,
  String rowId,
  UpdateType opType,
  Map<String, dynamic> data,
) {
  return upload_normalizer.normalizeUploadData(
    table: table,
    rowId: rowId,
    opType: opType,
    data: data,
    logError: talker.error,
  );
}

/// Use Supabase for authentication and data upload.
class SupabaseConnector extends PowerSyncBackendConnector {
  SupabaseConnector(this.db, {void Function(SyncAnomaly anomaly)? onAnomaly})
    : _onAnomaly = onAnomaly;

  PowerSyncDatabase db;

  final void Function(SyncAnomaly anomaly)? _onAnomaly;

  Future<void>? _refreshFuture;

  /// Get a Supabase token to authenticate against the PowerSync instance.
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Wait for pending session refresh if any
    await _refreshFuture;

    // Use Supabase token for PowerSync
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      // Not logged in
      return null;
    }

    // Use the access token to authenticate against PowerSync
    final token = session.accessToken;

    // expiresAt is for debugging purposes only
    final expiresAt = session.expiresAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
    return PowerSyncCredentials(
      endpoint: Env.powersyncUrl,
      token: token,
      expiresAt: expiresAt,
    );
  }

  @override
  void invalidateCredentials() {
    // Trigger a session refresh if auth fails on PowerSync.
    // Generally, sessions should be refreshed automatically by Supabase.
    // However, in some cases it can be a while before the session refresh is
    // retried. We attempt to trigger the refresh as soon as we get an auth
    // failure on PowerSync.
    //
    // This could happen if the device was offline for a while and the session
    // expired, and nothing else attempt to use the session it in the meantime.
    //
    // Timeout the refresh call to avoid waiting for long retries,
    // and ignore any errors. Errors will surface as expired tokens.
    _refreshFuture = Supabase.instance.client.auth
        .refreshSession()
        .timeout(const Duration(seconds: 5))
        .then((response) => null, onError: (error) => null);
  }

  // Upload pending changes to Supabase.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    // This function is called whenever there is data to upload, whether the
    // device is online or offline.
    // If this call throws an error, it is retried periodically.
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) {
      return;
    }

    // IMPORTANT: Never discard/consume queued CRUD when the user is signed out.
    // If we proceed without a session, REST calls may fail with RLS/auth errors
    // and our fatal handler would discard the transaction (data loss).
    final session = Supabase.instance.client.auth.currentSession;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (session == null) {
      talker.info(
        '[powersync] uploadData skipped (no Supabase session)\n'
        '  queuedOps=${transaction.crud.length}\n'
        '  hint=Wait for sign-in before uploading',
      );
      return;
    }

    talker.debug(
      '[powersync] uploadData starting\n'
      '  queuedOps=${transaction.crud.length}\n'
      '  userId=${currentUser?.id ?? "<null>"}',
    );

    final rest = Supabase.instance.client.rest;
    CrudEntry? lastOp;
    var lastOpIndex = -1;
    try {
      // Note: If transactional consistency is important, use database functions
      // or edge functions to process the entire transaction in a single call.
      for (final op in transaction.crud) {
        lastOp = op;
        lastOpIndex++;

        // Enhanced logging for user_profiles to trace sync sequence
        final isUserProfiles = op.table == 'user_profiles';
        final uploadStartTime = DateTime.now();

        if (isUserProfiles) {
          talker.debug(
            '[POWERSYNC UPLOAD] user_profiles operation START at $uploadStartTime\n'
            '  op.type=${op.op}\n'
            '  op.id=${op.id}\n'
            '  op.opData keys: ${op.opData?.keys.toList()}\n'
            '  updated_at in opData: ${op.opData?['updated_at']}',
          );
        }

        final table = rest.from(op.table);
        if (op.op == UpdateType.put) {
          final data = _normalizeUploadData(
            op.table,
            op.id,
            op.op,
            Map<String, dynamic>.of(op.opData!),
          );
          data['id'] = op.id;
          await table.upsert(data);
        } else if (op.op == UpdateType.patch) {
          final data = _normalizeUploadData(
            op.table,
            op.id,
            op.op,
            Map<String, dynamic>.of(op.opData!),
          );
          await table.update(data).eq('id', op.id);
        } else if (op.op == UpdateType.delete) {
          await table.delete().eq('id', op.id);
        }

        if (isUserProfiles) {
          final uploadEndTime = DateTime.now();
          talker.debug(
            '[POWERSYNC UPLOAD] user_profiles operation COMPLETE at $uploadEndTime\n'
            '  Duration: ${uploadEndTime.difference(uploadStartTime).inMilliseconds}ms\n'
            '  Supabase REST returned SUCCESS\n'
            '  NOTE: CDC may not have captured this yet!',
          );
        }
      }

      // All operations successful.
      await transaction.complete();
      talker.debug(
        '[POWERSYNC UPLOAD] transaction.complete() called at ${DateTime.now()}\n'
        '  All ${transaction.crud.length} operations uploaded to Supabase\n'
        '  PowerSync will now wait for CDC to sync back',
      );
    } on PostgrestException catch (e, st) {
      if (e.code == '23505') {
        // Unique constraint violation - handle based on table ID strategy
        await _handle23505(rest, lastOp!, e);
        // Mark as complete - either expected duplicate or logged conflict
        await transaction.complete();
      } else if (e.code == _schemaNotFoundCode) {
        // Table doesn't exist in Supabase schema (e.g., removed/migrated table).
        // This can happen after schema migrations when stale CRUD operations
        // reference tables that no longer exist (like allocation_preferences).
        // Discard these operations as they're no longer relevant.
        talker.warning(
          '[powersync] Table not found in Supabase schema - discarding '
          'operation for ${lastOp?.table}/${lastOp?.id}.\n'
          'This is expected after schema migrations.',
        );

        final op = lastOp;
        if (op != null) {
          _emitAnomaly(
            kind: SyncAnomalyKind.supabaseRejectedButLocalApplied,
            reason: SyncAnomalyReason.schemaNotFound,
            op: op,
            remoteCode: e.code,
            remoteMessage: e.message,
            details: <String, Object?>{
              'transactionOps': transaction.crud.length,
              'lastOpIndex': lastOpIndex,
            },
          );
        }
        await transaction.complete();
      } else if (e.code != null &&
          fatalResponseCodes.any((re) => re.hasMatch(e.code!))) {
        /// Instead of blocking the queue with these errors,
        /// discard the (rest of the) transaction.
        ///
        /// Note that these errors typically indicate a bug in the application.
        /// If protecting against data loss is important, save the failing records
        /// elsewhere instead of discarding, and/or notify the user.
        final userId = Supabase.instance.client.auth.currentUser?.id;
        final opContext = lastOp == null
            ? '  lastOp=<null>'
            : '  lastOp.index=$lastOpIndex/${transaction.crud.length - 1}\n'
                  '  lastOp.table=${lastOp.table}\n'
                  '  lastOp.op=${lastOp.op}\n'
                  '  lastOp.id=${lastOp.id}\n'
                  '  lastOp.opData keys=${lastOp.opData?.keys.toList()}';

        talker.handle(
          e,
          st,
          '[powersync] Data upload error - discarding transaction\n'
          '  userId=${userId ?? "<null>"}\n'
          '  powersyncEndpoint=${Env.powersyncUrl}\n'
          '  transaction.ops=${transaction.crud.length}\n'
          '$opContext\n'
          '  postgrest.code=${e.code ?? "<null>"}\n'
          '  postgrest.message=${e.message}\n'
          '  postgrest.details=${e.details ?? "<null>"}\n'
          '  postgrest.hint=${e.hint ?? "<null>"}',
        );

        final op = lastOp;
        if (op != null) {
          _emitAnomaly(
            kind: SyncAnomalyKind.supabaseRejectedButLocalApplied,
            reason: SyncAnomalyReason.fatalRemoteRejection,
            op: op,
            remoteCode: e.code,
            remoteMessage: e.message,
            details: <String, Object?>{
              'transactionOps': transaction.crud.length,
              'lastOpIndex': lastOpIndex,
              'postgrestDetails': e.details,
              'postgrestHint': e.hint,
            },
          );
        }

        await transaction.complete();
      } else {
        // Error may be retryable - e.g. network error or temporary server error.
        // Throwing an error here causes this call to be retried after a delay.
        rethrow;
      }
    }
  }

  /// Handle unique constraint violations (23505) based on ID strategy.
  ///
  /// For v5 (deterministic) tables:
  /// - If ID exists: Expected duplicate, another device synced first → OK
  /// - If ID doesn't exist: Natural key conflict with different ID → Bug
  ///
  /// For v4 (random) tables:
  /// - Should never happen (UUID collision is astronomically unlikely)
  /// - Log prominently but continue
  Future<void> _handle23505(
    PostgrestClient rest,
    CrudEntry op,
    PostgrestException e,
  ) async {
    final table = op.table;
    final id = op.id;

    if (IdGenerator.isDeterministic(table)) {
      // v5 table - check if this exact ID already exists
      try {
        final existing = await rest
            .from(table)
            .select('id')
            .eq('id', id)
            .maybeSingle();

        if (existing != null) {
          // Expected: Same ID exists, another device already synced this row
          talker.info(
            '[powersync] Expected duplicate on $table/$id - already synced',
          );
        } else {
          // Bug: Different ID has same natural key
          // This means v5 inputs are inconsistent across devices
          _emitAnomaly(
            kind: SyncAnomalyKind.supabaseRejectedButLocalApplied,
            reason: SyncAnomalyReason.naturalKeyConflictDifferentId,
            op: op,
            remoteCode: e.code,
            remoteMessage: e.message,
            details: <String, Object?>{
              'naturalKey': _extractNaturalKeyInfo(table, op.opData),
            },
          );
          _logNaturalKeyConflict(table, op);
        }
      } catch (queryError) {
        // If we can't query, log the original error
        talker.warning(
          '[powersync] Could not verify 23505 on $table/$id',
          queryError,
        );
      }
    } else {
      // v4 table - this should essentially never happen
      talker.warning(
        '[powersync] UNEXPECTED 23505 on v4 table $table/$id!\n'
        'UUID collision or constraint misconfiguration.\n'
        'Error: ${e.message}',
      );

      _emitAnomaly(
        kind: SyncAnomalyKind.supabaseRejectedButLocalApplied,
        reason: SyncAnomalyReason.unexpectedUniqueViolation,
        op: op,
        remoteCode: e.code,
        remoteMessage: e.message,
      );
    }
  }

  /// Log detailed info for natural key conflicts (v5 bug detection).
  void _logNaturalKeyConflict(String table, CrudEntry op) {
    final naturalKeyInfo = _extractNaturalKeyInfo(table, op.opData);

    talker.error(
      '[powersync] V5 CONFLICT DETECTED!\n'
      '  Table: $table\n'
      '  Attempted ID: ${op.id}\n'
      '  Natural key: $naturalKeyInfo\n'
      '  Action: Row NOT inserted - existing row has same natural key '
      'with different ID.\n'
      '  This indicates inconsistent v5 inputs across devices.\n'
      '  Check: case sensitivity, whitespace, userId source.',
    );
  }

  /// Extract natural key fields for debugging based on table.
  String _extractNaturalKeyInfo(String table, Map<String, dynamic>? data) {
    if (data == null) return 'unknown';

    return switch (table) {
      'labels' => 'name="${data['name']}", type="${data['type']}"',
      'task_labels' =>
        'taskId="${data['task_id']}", labelId="${data['label_id']}"',
      'project_labels' =>
        'projectId="${data['project_id']}", labelId="${data['label_id']}"',
      'task_completion_history' =>
        'taskId="${data['task_id']}", date="${data['occurrence_date']}"',
      'project_completion_history' =>
        'projectId="${data['project_id']}", date="${data['occurrence_date']}"',
      'task_recurrence_exceptions' =>
        'taskId="${data['task_id']}", date="${data['original_date']}"',
      'project_recurrence_exceptions' =>
        'projectId="${data['project_id']}", date="${data['original_date']}"',
      'tracker_definitions' =>
        'name="${data['name']}", scope="${data['scope']}", '
            'systemKey="${data['system_key']}"',
      'tracker_preferences' => 'trackerId="${data['tracker_id']}"',
      'tracker_definition_choices' =>
        'trackerId="${data['tracker_id']}", choiceKey="${data['choice_key']}"',
      'analytics_snapshots' =>
        'entityType="${data['entity_type']}", entityId="${data['entity_id']}",'
            ' date="${data['snapshot_date']}"',
      _ => data.toString(),
    };
  }

  void _emitAnomaly({
    required SyncAnomalyKind kind,
    required CrudEntry op,
    SyncAnomalyReason? reason,
    String? remoteCode,
    String? remoteMessage,
    Map<String, Object?>? details,
  }) {
    final onAnomaly = _onAnomaly;
    if (onAnomaly == null) return;

    String? correlationId;
    String? source;
    String? occurredAt;

    final Object? metadata = op.metadata;
    Map<String, dynamic>? decodedMetadata;

    if (metadata is Map) {
      decodedMetadata = Map<String, dynamic>.from(metadata);
    } else if (metadata is String && metadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata);
        if (decoded is Map) {
          decodedMetadata = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Ignore metadata parse failures; anomalies still publish.
      }
    }

    if (decodedMetadata != null) {
      final cid = decodedMetadata['cid'];
      if (cid is String && cid.trim().isNotEmpty) {
        correlationId = cid;
      }

      final src = decodedMetadata['src'];
      if (src is String && src.trim().isNotEmpty) {
        source = src;
      }

      final ts = decodedMetadata['ts'];
      if (ts is String && ts.trim().isNotEmpty) {
        occurredAt = ts;
      }
    }

    final mergedDetails = <String, Object?>{...?details};
    if (source != null) mergedDetails['src'] = source;
    if (occurredAt != null) mergedDetails['ts'] = occurredAt;

    final anomaly = SyncAnomaly(
      kind: kind,
      occurredAt: DateTime.now(),
      table: op.table,
      rowId: op.id,
      operation: op.op.name,
      reason: reason,
      remoteCode: remoteCode,
      remoteMessage: remoteMessage,
      correlationId: correlationId,
      details: mergedDetails.isEmpty ? null : mergedDetails,
    );

    try {
      onAnomaly(anomaly);
    } catch (e, st) {
      talker.handle(e, st, '[powersync] Failed to publish SyncAnomaly');
    }
  }
}

bool isLoggedIn() {
  try {
    return Supabase.instance.client.auth.currentSession?.accessToken != null;
  } on Exception {
    return false;
  }
}

/// id of the user currently logged in
String? getUserId() {
  try {
    return Supabase.instance.client.auth.currentSession?.user.id;
  } on Exception {
    return null;
  }
}

Future<String> getDatabasePath() async {
  const dbFilename = 'powersync-demo.db';
  // getApplicationSupportDirectory is not supported on Web
  if (kIsWeb) {
    return dbFilename;
  }
  final dir = await getApplicationSupportDirectory();
  return join(dir.path, dbFilename);
}

/// Opens the PowerSync database and sets up auth state listeners.
Future<PowerSyncDatabase> openDatabase({String? pathOverride}) async {
  installPowerSyncLogForwarding();

  const powersyncVerbose = bool.fromEnvironment('POWERSYNC_VERBOSE_LOGS');
  const dbLockDiagnostics = bool.fromEnvironment('DB_LOCK_DIAGNOSTICS');
  const enableDbDiagnostics =
      dbLockDiagnostics || (kDebugMode && powersyncVerbose);

  final db = PowerSyncDatabase(
    schema: schema,
    path: pathOverride ?? await getDatabasePath(),
    logger: attachedLogger,
  );
  await db.initialize();

  Future<void> logSqlitePragmas(PowerSyncDatabase database) async {
    // This is a low-cost, one-time diagnostic to confirm WAL/busy_timeout/etc.
    // It should not run in production unless explicitly enabled.
    if (!enableDbDiagnostics) return;

    try {
      Future<String?> singleValue(String pragmaSql) async {
        final result = await database.execute(pragmaSql);
        if (result.rows.isEmpty) return null;
        final row = result.rows.first;
        if (row.isEmpty) return null;
        return row.first?.toString();
      }

      final journalMode = await singleValue('PRAGMA journal_mode;');
      final busyTimeout = await singleValue('PRAGMA busy_timeout;');
      final synchronous = await singleValue('PRAGMA synchronous;');
      final tempStore = await singleValue('PRAGMA temp_store;');
      final walCheckpoint = await singleValue('PRAGMA wal_autocheckpoint;');

      talker.info(
        '[db] SQLite PRAGMAs\n'
        '  journal_mode=${journalMode ?? "<null>"}\n'
        '  busy_timeout=${busyTimeout ?? "<null>"}\n'
        '  synchronous=${synchronous ?? "<null>"}\n'
        '  temp_store=${tempStore ?? "<null>"}\n'
        '  wal_autocheckpoint=${walCheckpoint ?? "<null>"}',
      );
    } catch (e, st) {
      // Best-effort diagnostics only.
      talker.handle(e, st, '[db] Failed to read SQLite PRAGMAs');
    }
  }

  await logSqlitePragmas(db);

  // Helper to log user_profiles state after sync checkpoint
  Future<void> logUserProfilesAfterSync(
    PowerSyncDatabase database,
    DateTime syncTime,
  ) async {
    if (!enableDbDiagnostics) return;
    try {
      final results = await database.execute(
        'SELECT id, updated_at, '
        'substr(settings_overrides, 1, 80) as overrides_preview '
        'FROM user_profiles LIMIT 1',
      );
      if (results.rows.isNotEmpty) {
        final row = results.rows.first;
        talker.debug(
          '[POWERSYNC CHECKPOINT] user_profiles state AFTER sync at $syncTime\n'
          '  id=${row[0]}\n'
          '  updated_at=${row[1]}\n'
          '  settings_overrides preview: ${row[2]}...',
        );
      }
    } catch (e) {
      // Ignore errors - this is just debug logging
    }
  }

  // Log sync status changes only when diagnostics are enabled.
  if (enableDbDiagnostics) {
    db.statusStream.listen((status) {
      final now = DateTime.now();
      talker.debug(
        '[POWERSYNC SYNC STATUS] at $now\n'
        '  connected=${status.connected}\n'
        '  downloading=${status.downloading}\n'
        '  uploading=${status.uploading}\n'
        '  lastSyncedAt=${status.lastSyncedAt}\n'
        '  hasSynced=${status.hasSynced}',
      );

      // When downloading completes, query user_profiles to see what was synced.
      if (!status.downloading && (status.hasSynced ?? false)) {
        logUserProfilesAfterSync(db, now);
      }
    });
  }

  return db;
}

/// Run post-authentication maintenance tasks.
///
/// Should be called once during app initialization after user is authenticated.
/// This ensures:
/// 1. Orphaned system data is cleaned up (after template changes)
Future<void> runPostAuthMaintenance({
  required AppDatabase driftDb,
  required IdGenerator idGenerator,
}) async {
  if (!isLoggedIn()) {
    talker.debug('[PostAuthMaintenance] Skipping - user not logged in');
    return;
  }

  talker.info('[PostAuthMaintenance] Running post-auth maintenance');

  // Seed system attention rules into the local database.
  // This is required when Supabase has no rows yet because the UI reads from
  // the local Drift/PowerSync database.
  await AttentionSeeder(db: driftDb, idGenerator: idGenerator).ensureSeeded();

  await _backfillAttentionRulesDomain(db: driftDb);

  // Seed system Journal trackers + default preferences.
  await JournalTrackerSeeder(
    db: driftDb,
    idGenerator: idGenerator,
  ).ensureSeeded();

  await _cleanupOrphanedSystemAttentionRules(
    db: driftDb,
    idGenerator: idGenerator,
  );
  await _cleanupOrphanedAttentionResolutions(db: driftDb);

  talker.info('[PostAuthMaintenance] Completed');
}

Future<void> _backfillAttentionRulesDomain({required AppDatabase db}) async {
  try {
    final updated = await db.customUpdate(
      'UPDATE attention_rules '
      'SET domain = ? '
      "WHERE domain IS NULL OR domain = ''",
      variables: [Variable.withString(AttentionSeeder.attentionRulesDomain)],
      updates: {db.attentionRules},
    );

    if (updated > 0) {
      talker.info(
        '[PostAuthMaintenance] Backfilled domain for '
        '$updated attention rule(s)',
      );
    }
  } catch (e, stackTrace) {
    // Best-effort: if the local PowerSync schema hasn't applied the new column
    // yet, we don't want to crash app startup.
    talker.warning(
      '[PostAuthMaintenance] Failed to backfill attention_rules.domain',
    );
    talker.handle(e, stackTrace);
  }
}

Future<void> _cleanupOrphanedSystemAttentionRules({
  required AppDatabase db,
  required IdGenerator idGenerator,
}) async {
  // Compute known deterministic IDs from the current rule templates.
  final knownIds = SystemAttentionRules.all
      .map((t) => idGenerator.attentionRuleId(ruleKey: t.ruleKey))
      .toSet();
  final systemRuleKeys = SystemAttentionRules.all.map((t) => t.ruleKey).toSet();

  final deleted =
      await (db.delete(db.attentionRules)..where(
            (r) => r.ruleKey.isIn(systemRuleKeys) & r.id.isNotIn(knownIds),
          ))
          .go();

  if (deleted > 0) {
    talker.info(
      '[PostAuthMaintenance] Deleted $deleted orphaned system attention rule(s)',
    );
  }
}

Future<void> _cleanupOrphanedAttentionResolutions({
  required AppDatabase db,
}) async {
  // Foreign keys are not enforced because PowerSync exposes schema as views.
  // Best-effort cleanup prevents broken joins/queries when templates change.
  final deleted = await db.customUpdate(
    'DELETE FROM attention_resolutions '
    'WHERE rule_id NOT IN (SELECT id FROM attention_rules)',
    updates: {db.attentionResolutions},
  );

  if (deleted > 0) {
    talker.info(
      '[PostAuthMaintenance] Deleted $deleted orphaned attention resolution(s)',
    );
  }
}
