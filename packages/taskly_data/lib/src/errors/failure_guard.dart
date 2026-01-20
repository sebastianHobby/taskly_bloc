import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/telemetry.dart';

import 'package:taskly_data/src/errors/app_failure_mapper.dart';

bool _isDebugBuild() {
  var debug = false;
  assert(() {
    debug = true;
    return true;
  }(), 'Debug build check');
  return debug;
}

bool _looksLikeSqliteBusy(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('database is locked') ||
      text.contains('sqlite_busy') ||
      text.contains('sqlite_busy_snapshot') ||
      text.contains('sqlite_busy_timeout') ||
      text.contains('sqliteexception(5)') ||
      text.contains('code 5');
}

bool _shouldLogOperationSpan({required String area, required String opName}) {
  // Keep span logs opt-in for release builds.
  // Default behavior: enabled in debug builds.
  const envEnabled = bool.fromEnvironment('DB_LOCK_DIAGNOSTICS');
  if (!envEnabled && !_isDebugBuild()) return false;

  // Focus on write-like operations to avoid noise.
  final normalizedOp = opName.toLowerCase();
  const writeOps = <String>{
    'create',
    'update',
    'delete',
    'save',
    'upsert',
    'write',
    'clear',
    'seed',
    'reset',
    'mutate',
  };

  if (writeOps.contains(normalizedOp)) return true;

  // Some call sites use more descriptive names like "createTask".
  if (normalizedOp.contains('create') ||
      normalizedOp.contains('update') ||
      normalizedOp.contains('delete') ||
      normalizedOp.contains('save') ||
      normalizedOp.contains('seed') ||
      normalizedOp.contains('clear') ||
      normalizedOp.contains('write')) {
    return true;
  }

  // As a fallback, only span log for known data-layer areas.
  return area.startsWith('data.');
}

/// Runs an operation and ensures any thrown error is converted into an
/// [AppFailure] via [AppFailureMapper].
///
/// This prevents raw implementation exceptions from leaking into presentation.
abstract final class FailureGuard {
  static Future<T> run<T>(
    Future<T> Function() operation, {
    required String area,
    required String opName,
    OperationContext? context,
  }) async {
    final spanEnabled = _shouldLogOperationSpan(area: area, opName: opName);
    final stopwatch = spanEnabled ? (Stopwatch()..start()) : null;
    final baseFields = context?.toLogFields() ?? const <String, Object?>{};

    try {
      final result = await operation();
      if (stopwatch != null) {
        stopwatch.stop();
        AppLog.routineStructured(
          area,
          '$opName succeeded',
          fields: <String, Object?>{
            ...baseFields,
            'durationMs': stopwatch.elapsedMilliseconds,
          },
        );
      }
      return result;
    } catch (e, st) {
      stopwatch?.stop();
      final failure = AppFailureMapper.fromException(e);

      final isBusy = _looksLikeSqliteBusy(e) || _looksLikeSqliteBusy(failure);
      final fields = <String, Object?>{
        ...baseFields,
        'mappedFailure': failure.toString(),
        if (stopwatch != null) 'durationMs': stopwatch.elapsedMilliseconds,
      };

      if (isBusy) {
        AppLog.warnStructured(
          area,
          '$opName failed (SQLITE_BUSY)',
          fields: <String, Object?>{
            ...fields,
            'cause': e.toString(),
            'hint':
                'database is locked; likely concurrent writer (PowerSync vs app) or busy_timeout too low',
          },
        );
      }

      AppLog.handleStructured(area, '$opName failed', failure, st, fields);
      throw failure;
    }
  }
}
