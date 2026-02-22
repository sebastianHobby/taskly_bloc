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
import 'package:taskly_data/src/infrastructure/powersync/powersync_status_stream.dart';
import 'package:taskly_data/src/infrastructure/powersync/identifier_hash.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/attention/maintenance/attention_seeder.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_data/src/infrastructure/powersync/schema.dart';
import 'package:taskly_data/src/infrastructure/powersync/upload_data_normalizer.dart'
    as upload_normalizer;
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart' show Clock, systemClock;

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
const _postgresUndefinedTableCode = '42P01';

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
  SupabaseConnector(
    this.db, {
    void Function(SyncAnomaly anomaly)? onAnomaly,
    Clock clock = systemClock,
    this.syncSessionId,
    this.clientId,
    this.userIdHash,
  }) : _onAnomaly = onAnomaly,
       _clock = clock;

  PowerSyncDatabase db;

  final void Function(SyncAnomaly anomaly)? _onAnomaly;
  final Clock _clock;
  final String? syncSessionId;
  final String? clientId;
  final String? userIdHash;

  Future<bool>? _refreshFuture;
  int _uploadInFlightCount = 0;
  String? _lastUploadSignature;
  DateTime? _lastUploadSignatureAt;
  int _repeatUploadCount = 0;

  static const Duration _uploadLoopWindow = Duration(seconds: 3);
  static const int _uploadLoopThreshold = 3;
  static const int _uploadQueueHighThreshold = 100;
  static const Duration _refreshTimeout = Duration(seconds: 5);
  static const Duration _proactiveRefreshLead = Duration(minutes: 1);

  /// Get a Supabase token to authenticate against the PowerSync instance.
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    // Wait for pending session refresh if any
    await _refreshFuture;

    var session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      _logSyncEvent(
        'sync.credentials.fetch',
        fields: <String, Object?>{
          'result': 'no_session',
        },
      );
      return null;
    }

    final expiresAt = _expiresAtUtc(session);
    final now = _clock.nowUtc();
    final shouldRefresh =
        expiresAt != null &&
        !now.isBefore(expiresAt.subtract(_proactiveRefreshLead));
    if (shouldRefresh) {
      final refreshed = await _refreshSession(reason: 'proactive_fetch');
      if (!refreshed) {
        _logSyncEvent(
          'sync.credentials.fetch',
          level: _SyncLogLevel.warn,
          fields: <String, Object?>{
            'result': 'refresh_failed',
            'reason': 'proactive_fetch',
            'expires_at_utc': expiresAt.toIso8601String(),
          },
        );
        // Do not reuse expired / near-expiry credentials when refresh fails.
        return null;
      }
      session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        _logSyncEvent(
          'sync.credentials.fetch',
          fields: <String, Object?>{
            'result': 'session_missing_after_refresh',
          },
        );
        return null;
      }
    }

    final refreshedExpiresAt = _expiresAtUtc(session);
    final credentials = PowerSyncCredentials(
      endpoint: Env.powersyncUrl,
      token: session.accessToken,
      expiresAt: refreshedExpiresAt,
    );

    _logSyncEvent(
      'sync.credentials.fetch',
      fields: <String, Object?>{
        'result': 'success',
        'refreshed': shouldRefresh,
        'expires_at_utc': refreshedExpiresAt?.toIso8601String(),
      },
    );

    return credentials;
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
    // Best-effort refresh to recover quickly after auth failure.
    _logSyncEvent(
      'sync.auth.expired',
      level: _SyncLogLevel.warn,
      fields: <String, Object?>{
        'action': 'refresh_session',
        'reason': 'connector_invalidate_credentials',
      },
    );
    _refreshSession(reason: 'auth_invalidation');
  }

  DateTime? _expiresAtUtc(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      expiresAt * 1000,
      isUtc: true,
    );
  }

  Future<bool> _refreshSession({required String reason}) async {
    final inFlight = _refreshFuture;
    if (inFlight != null) return inFlight;

    _logSyncEvent(
      'sync.token.refresh.start',
      fields: <String, Object?>{
        'reason': reason,
      },
    );

    final refreshFuture = Supabase.instance.client.auth
        .refreshSession()
        .timeout(_refreshTimeout)
        .then((_) {
          final session = Supabase.instance.client.auth.currentSession;
          _logSyncEvent(
            'sync.token.refresh.success',
            fields: <String, Object?>{
              'reason': reason,
              'expires_at_utc': session == null
                  ? null
                  : _expiresAtUtc(session)?.toIso8601String(),
            },
          );
          if (kReleaseMode) {
            talker.info(
              '[powersync] supabase session refreshed\n'
              '  reason=$reason\n'
              '  expiresAtUtc=${session == null ? null : _expiresAtUtc(session)}',
            );
          }
          return session != null;
        })
        .onError((error, stackTrace) {
          final resolvedError =
              error ?? StateError('Unknown Supabase refresh error');
          _logSyncEvent(
            'sync.token.refresh.fail',
            level: _SyncLogLevel.warn,
            fields: <String, Object?>{
              'reason': reason,
              'error': resolvedError.runtimeType.toString(),
            },
          );
          talker.warning(
            '[powersync] supabase session refresh failed\n'
            '  reason=$reason\n'
            '  error=$resolvedError',
          );
          if (kReleaseMode) {
            talker.handle(
              resolvedError,
              stackTrace,
              '[powersync] production refresh failure (reason=$reason)',
            );
          }
          return false;
        });

    _refreshFuture = refreshFuture;
    final refreshed = await refreshFuture;
    if (identical(_refreshFuture, refreshFuture)) {
      _refreshFuture = null;
    }
    return refreshed;
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

    final wasInFlight = _uploadInFlightCount > 0;
    _uploadInFlightCount++;

    if (transaction.crud.length >= _uploadQueueHighThreshold) {
      AppLog.warnThrottledStructured(
        'sync.upload.queue.high.${syncSessionId ?? "unknown"}',
        const Duration(seconds: 30),
        'sync',
        'sync.upload.queue.high',
        fields: <String, Object?>{
          ..._syncContextFields(),
          'queued_ops': transaction.crud.length,
          'threshold': _uploadQueueHighThreshold,
        },
      );
    }

    late final PostgrestClient rest;
    CrudEntry? lastOp;
    var lastOpIndex = -1;
    var missingContextReported = false;

    try {
      // IMPORTANT: Never discard/consume queued CRUD when the user is signed out.
      // If we proceed without a session, REST calls may fail with RLS/auth errors
      // and our fatal handler would discard the transaction (data loss).
      final session = Supabase.instance.client.auth.currentSession;
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (session == null) {
        _logSyncEvent(
          'sync.upload.skipped',
          fields: <String, Object?>{
            'reason': 'no_session',
            'queued_ops': transaction.crud.length,
          },
        );
        talker.info(
          '[powersync] uploadData skipped (no Supabase session)\n'
          '  queuedOps=${transaction.crud.length}\n'
          '  hint=Wait for sign-in before uploading',
        );
        return;
      }

      final userIdHash = _hashIdentifier(currentUser?.id) ?? '<null>';
      talker.debug(
        '[powersync] uploadData starting\n'
        '  queuedOps=${transaction.crud.length}\n'
        '  userIdHash=$userIdHash',
      );

      if (wasInFlight && transaction.crud.isNotEmpty) {
        final op = transaction.crud.first;
        _logSyncEvent(
          'sync.upload.reentrancy',
          level: _SyncLogLevel.warn,
          fields: <String, Object?>{
            'queued_ops': transaction.crud.length,
            'sample_table': op.table,
            'sample_row_id': op.id,
            'sample_op': op.op.name,
            'user_id_hash': userIdHash,
          },
        );
        talker.warning(
          '[powersync] uploadData re-entered while previous upload is in flight\n'
          '  queuedOps=${transaction.crud.length}\n'
          '  userIdHash=$userIdHash\n'
          '  sample=${op.table}/${op.id}/${op.op.name}',
        );
        _emitAnomaly(
          kind: SyncAnomalyKind.syncPipelineIssue,
          reason: SyncAnomalyReason.uploadReentrancy,
          op: op,
          details: <String, Object?>{
            'queuedOps': transaction.crud.length,
            'user_id_hash': userIdHash,
          },
        );
      }

      _recordUploadSignature(transaction, userIdHash: userIdHash);

      rest = Supabase.instance.client.rest;
      // Note: If transactional consistency is important, use database functions
      // or edge functions to process the entire transaction in a single call.
      for (final op in transaction.crud) {
        lastOp = op;
        lastOpIndex++;

        if (!missingContextReported &&
            op.metadata != null &&
            !_hasOperationContext(op.metadata)) {
          missingContextReported = true;
          _logSyncEvent(
            'sync.upload.missing_operation_context',
            level: _SyncLogLevel.warn,
            fields: <String, Object?>{
              'table': op.table,
              'row_id': op.id,
              'op': op.op.name,
              'queued_ops': transaction.crud.length,
              'metadata_type': op.metadata.runtimeType.toString(),
            },
          );
          talker.warning(
            '[powersync] CRUD metadata missing operation context\n'
            '  table=${op.table}\n'
            '  id=${op.id}\n'
            '  op=${op.op.name}',
          );
          _emitAnomaly(
            kind: SyncAnomalyKind.syncPipelineIssue,
            reason: SyncAnomalyReason.missingOperationContext,
            op: op,
            details: <String, Object?>{
              'queuedOps': transaction.crud.length,
              'metadataType': op.metadata.runtimeType.toString(),
            },
          );
        }

        // Enhanced logging for user_profiles to trace sync sequence
        final isUserProfiles = op.table == 'user_profiles';
        final uploadStartTime = _clock.nowUtc();

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
        if (op.op == UpdateType.put || op.op == UpdateType.patch) {
          final opData = op.opData;
          if (opData == null) {
            final payloadError = StateError(
              'PowerSync CRUD payload missing for ${op.op.name}',
            );
            final fields = <String, Object?>{
              ..._syncContextFields(),
              'table': op.table,
              'row_id': op.id,
              'op': op.op.name,
              'transaction_ops': transaction.crud.length,
              'last_op_index': lastOpIndex,
            };
            AppLog.handleStructured(
              'sync',
              'sync.upload.missing_crud_payload',
              payloadError,
              null,
              fields,
            );
            _logSyncEvent(
              'sync.upload.missing_crud_payload',
              level: _SyncLogLevel.error,
              fields: fields,
            );
            _emitAnomaly(
              kind: SyncAnomalyKind.syncPipelineIssue,
              reason: SyncAnomalyReason.missingCrudPayload,
              op: op,
              details: <String, Object?>{
                'transactionOps': transaction.crud.length,
                'lastOpIndex': lastOpIndex,
              },
            );

            // Prevent an endless retry/crash loop on malformed local CRUD.
            await transaction.complete();
            return;
          }

          final data = _normalizeUploadData(
            op.table,
            op.id,
            op.op,
            Map<String, dynamic>.of(opData),
          );
          if (op.op == UpdateType.put) {
            data['id'] = op.id;
            await table.upsert(data);
          } else {
            await table.update(data).eq('id', op.id);
          }
        } else if (op.op == UpdateType.delete) {
          await table.delete().eq('id', op.id);
        }

        if (isUserProfiles) {
          final uploadEndTime = _clock.nowUtc();
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
        '[POWERSYNC UPLOAD] transaction.complete() called at ${_clock.nowUtc()}\n'
        '  All ${transaction.crud.length} operations uploaded to Supabase\n'
        '  PowerSync will now wait for CDC to sync back',
      );
    } on PostgrestException catch (e, st) {
      if (e.code == '23505') {
        // Unique constraint violation - handle based on table ID strategy
        final op = lastOp;
        if (op == null) {
          _logSyncEvent(
            'sync.upload.unique_violation_without_context',
            level: _SyncLogLevel.error,
            fields: <String, Object?>{
              'remote_code': e.code,
              'remote_message': e.message,
              'transaction_ops': transaction.crud.length,
              'last_op_index': lastOpIndex,
            },
          );
          AppLog.handleStructured(
            'sync',
            'sync.upload.unique_violation_without_context',
            StateError('23505 received without CRUD operation context'),
            st,
            <String, Object?>{
              ..._syncContextFields(),
              'remote_code': e.code,
              'remote_message': e.message,
              'transaction_ops': transaction.crud.length,
              'last_op_index': lastOpIndex,
            },
          );
        } else {
          await _handle23505(rest, op, e);
        }
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
        _logSyncEvent(
          'sync.upload.schema_not_found',
          level: _SyncLogLevel.warn,
          fields: <String, Object?>{
            'table': lastOp?.table,
            'row_id': lastOp?.id,
            'remote_code': e.code,
            'remote_message': e.message,
            'transaction_ops': transaction.crud.length,
            'last_op_index': lastOpIndex,
          },
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
      } else if (e.code == _postgresUndefinedTableCode) {
        // PostgreSQL undefined table/relation. Treat as schema mismatch and
        // drop stale operations to prevent endless retry loops.
        talker.warning(
          '[powersync] Relation not found in Supabase schema - discarding '
          'operation for ${lastOp?.table}/${lastOp?.id}.',
        );
        _logSyncEvent(
          'sync.upload.schema_not_found',
          level: _SyncLogLevel.warn,
          fields: <String, Object?>{
            'table': lastOp?.table,
            'row_id': lastOp?.id,
            'remote_code': e.code,
            'remote_message': e.message,
            'remote_details': e.details,
            'transaction_ops': transaction.crud.length,
            'last_op_index': lastOpIndex,
          },
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
              'postgrestDetails': e.details,
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
        final userIdHash = _hashIdentifier(
          Supabase.instance.client.auth.currentUser?.id,
        );
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
          '  userIdHash=${userIdHash ?? "<null>"}\n'
          '  powersyncEndpoint=${Env.powersyncUrl}\n'
          '  transaction.ops=${transaction.crud.length}\n'
          '$opContext\n'
          '  postgrest.code=${e.code ?? "<null>"}\n'
          '  postgrest.message=${e.message}\n'
          '  postgrest.details=${e.details ?? "<null>"}\n'
          '  postgrest.hint=${e.hint ?? "<null>"}',
        );
        _logSyncEvent(
          'sync.upload.fatal_remote_rejection',
          level: _SyncLogLevel.error,
          fields: <String, Object?>{
            'table': lastOp?.table,
            'row_id': lastOp?.id,
            'op': lastOp?.op.name,
            'remote_code': e.code,
            'remote_message': e.message,
            'remote_details': e.details,
            'remote_hint': e.hint,
            'transaction_ops': transaction.crud.length,
            'last_op_index': lastOpIndex,
          },
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
        final op = lastOp;
        _logSyncEvent(
          'sync.upload.retryable_error',
          level: _SyncLogLevel.warn,
          fields: <String, Object?>{
            'table': op?.table,
            'row_id': op?.id,
            'op': op?.op.name,
            'remote_code': e.code,
            'remote_message': e.message,
            'remote_details': e.details,
            'remote_hint': e.hint,
            'transaction_ops': transaction.crud.length,
            'last_op_index': lastOpIndex,
          },
        );
        talker.warning(
          '[powersync] Retryable upload error; transaction will be retried\n'
          '  table=${op?.table ?? "<null>"}\n'
          '  op=${op?.op.name ?? "<null>"}\n'
          '  id=${op?.id ?? "<null>"}\n'
          '  postgrest.code=${e.code ?? "<null>"}\n'
          '  postgrest.message=${e.message}',
        );
        rethrow;
      }
    } finally {
      _uploadInFlightCount = (_uploadInFlightCount - 1).clamp(0, 1 << 20);
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
      occurredAt: _clock.nowUtc(),
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

  String _buildCrudSignature(List<CrudEntry> crud) {
    final buffer = StringBuffer();
    for (final op in crud) {
      buffer
        ..write(op.table)
        ..write(':')
        ..write(op.op.name)
        ..write(':')
        ..write(op.id)
        ..write('|');
    }
    return buffer.toString();
  }

  void _recordUploadSignature(
    CrudTransaction transaction, {
    required String userIdHash,
  }) {
    if (transaction.crud.isEmpty) return;

    final signature = _buildCrudSignature(transaction.crud);
    final now = _clock.nowUtc();
    final lastSignature = _lastUploadSignature;
    final lastAt = _lastUploadSignatureAt;
    if (lastSignature == signature &&
        lastAt != null &&
        now.difference(lastAt) <= _uploadLoopWindow) {
      _repeatUploadCount++;
    } else {
      _repeatUploadCount = 1;
    }

    _lastUploadSignature = signature;
    _lastUploadSignatureAt = now;

    final shouldReport =
        _repeatUploadCount == _uploadLoopThreshold ||
        (_repeatUploadCount > _uploadLoopThreshold &&
            _repeatUploadCount % 10 == 0);

    if (!shouldReport) return;

    final tables = transaction.crud.map((op) => op.table).toSet().toList()
      ..sort();
    final op = transaction.crud.first;

    talker.warning(
      '[powersync] Possible upload loop detected\n'
      '  repeats=$_repeatUploadCount\n'
      '  windowMs=${_uploadLoopWindow.inMilliseconds}\n'
      '  queuedOps=${transaction.crud.length}\n'
      '  tables=$tables\n'
      '  userIdHash=$userIdHash',
    );
    _logSyncEvent(
      'sync.upload.loop_detected',
      level: _SyncLogLevel.warn,
      fields: <String, Object?>{
        'repeat_count': _repeatUploadCount,
        'window_ms': _uploadLoopWindow.inMilliseconds,
        'queued_ops': transaction.crud.length,
        'tables': tables.join(','),
        'user_id_hash': userIdHash,
      },
    );

    _emitAnomaly(
      kind: SyncAnomalyKind.syncPipelineIssue,
      reason: SyncAnomalyReason.uploadLoopDetected,
      op: op,
      details: <String, Object?>{
        'repeatCount': _repeatUploadCount,
        'windowMs': _uploadLoopWindow.inMilliseconds,
        'queuedOps': transaction.crud.length,
        'tables': tables,
        'user_id_hash': userIdHash,
      },
    );
  }

  Map<String, dynamic>? _decodeCrudMetadata(Object? metadata) {
    if (metadata is Map) {
      return Map<String, dynamic>.from(metadata);
    }
    if (metadata is String && metadata.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(metadata);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return null;
  }

  bool _hasOperationContext(Object? metadata) {
    final decoded = _decodeCrudMetadata(metadata);
    if (decoded == null) return false;
    final cid = decoded['cid'];
    if (cid is String && cid.trim().isNotEmpty) return true;
    return false;
  }

  Map<String, Object?> _syncContextFields() {
    final envConfig = Env.config;
    final configuredAppVersion = envConfig?.appVersion.trim() ?? '';
    final configuredBuildSha = envConfig?.buildSha.trim() ?? '';

    return <String, Object?>{
      'sync_session_id': syncSessionId,
      'client_id': clientId,
      'user_id_hash': userIdHash,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'env': envConfig?.name ?? 'unknown',
      'app_version': configuredAppVersion.isEmpty
          ? const String.fromEnvironment('APP_VERSION', defaultValue: 'unknown')
          : configuredAppVersion,
      'build_sha': configuredBuildSha.isEmpty
          ? const String.fromEnvironment('BUILD_SHA', defaultValue: 'unknown')
          : configuredBuildSha,
    };
  }

  void _logSyncEvent(
    String event, {
    _SyncLogLevel level = _SyncLogLevel.info,
    Map<String, Object?> fields = const <String, Object?>{},
  }) {
    final mergedFields = <String, Object?>{
      'event': event,
      ..._syncContextFields(),
      ...fields,
    };

    switch (level) {
      case _SyncLogLevel.routine:
        AppLog.routineStructured('sync', event, fields: mergedFields);
      case _SyncLogLevel.info:
        AppLog.infoStructured('sync', event, fields: mergedFields);
      case _SyncLogLevel.warn:
        AppLog.warnStructured('sync', event, fields: mergedFields);
      case _SyncLogLevel.error:
        AppLog.errorStructured('sync', event, fields: mergedFields);
    }
  }

  static String? _hashIdentifier(String? value) {
    return hashIdentifierForTelemetry(value);
  }
}

enum _SyncLogLevel { routine, info, warn, error }

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
Future<PowerSyncDatabase> openDatabase({
  String? pathOverride,
  Clock clock = systemClock,
}) async {
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
    sharedPowerSyncStatusStream(db).listen((status) {
      final now = clock.nowUtc();
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
