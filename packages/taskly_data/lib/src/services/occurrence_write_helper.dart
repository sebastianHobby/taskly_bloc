import 'package:drift/drift.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/errors.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

/// Implementation of [OccurrenceWriteHelperContract].
///
/// Handles all write operations for occurrence-specific mutations.
/// Uses IdGenerator for deterministic v5 IDs.
class OccurrenceWriteHelper implements OccurrenceWriteHelperContract {
  OccurrenceWriteHelper({
    required this.driftDb,
    required this.idGenerator,
    Clock clock = systemClock,
  }) : _clock = clock;

  final AppDatabase driftDb;
  final IdGenerator idGenerator;
  final Clock _clock;

  Future<T> _runGuarded<T>(
    String operation,
    OperationContext? context,
    Future<T> Function() body,
  ) async {
    try {
      return await body();
    } catch (error, stackTrace) {
      if (error is AppFailure) rethrow;

      final fields = context?.toLogFields() ?? const <String, Object?>{};
      AppLog.handleStructured(
        'data.occurrence_write',
        operation,
        error,
        stackTrace,
        fields,
      );

      if (_isSqliteException(error)) {
        throw StorageFailure(message: _extractMessage(error), cause: error);
      }

      throw UnknownFailure(cause: error);
    }
  }

  bool _isSqliteException(Object error) {
    return error.runtimeType.toString() == 'SqliteException';
  }

  String _extractMessage(Object error) {
    try {
      final dynamicError = error as dynamic;
      final message = dynamicError.message;
      if (message is String && message.isNotEmpty) return message;
    } catch (_) {
      // Ignore: best-effort extraction without importing platform-only types.
    }

    return error.toString();
  }

  // ===========================================================================
  // TASK OCCURRENCE WRITES
  // ===========================================================================

  @override
  Future<void> completeTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    await _runGuarded('completeTaskOccurrence', context, () async {
      final now = _clock.nowLocal();
      final fields = <String, Object?>{
        ...?context?.toLogFields(),
        'taskId': taskId,
        'occurrenceDate': occurrenceDate?.toIso8601String(),
      };
      AppLog.routineStructured(
        'data.occurrence_write',
        'completeTaskOccurrence',
        fields: fields,
      );

      final normalizedOccurrenceDate = occurrenceDate != null
          ? _normalizeDate(occurrenceDate)
          : null;
      final normalizedOriginalDate = originalOccurrenceDate ?? occurrenceDate;
      final normalizedOriginalOccurrenceDate = normalizedOriginalDate != null
          ? _normalizeDate(normalizedOriginalDate)
          : null;

      // Generate deterministic v5 ID
      final id = idGenerator.taskCompletionId(
        taskId: taskId,
        occurrenceDate: normalizedOccurrenceDate,
      );

      // Check if completion record already exists (PowerSync views don't support UPSERT)
      final existing = await (driftDb.select(
        driftDb.taskCompletionHistoryTable,
      )..where((t) => t.id.equals(id))).getSingleOrNull();

      if (existing != null) {
        // Update existing record
        await (driftDb.update(
          driftDb.taskCompletionHistoryTable,
        )..where((t) => t.id.equals(id))).write(
          TaskCompletionHistoryTableCompanion(
            completedAt: Value(now),
            notes: Value(notes),
            updatedAt: Value(now),
          ),
        );
      } else {
        // Insert new record
        await driftDb
            .into(driftDb.taskCompletionHistoryTable)
            .insert(
              TaskCompletionHistoryTableCompanion.insert(
                id: id,
                taskId: taskId,
                occurrenceDate: Value(normalizedOccurrenceDate),
                originalOccurrenceDate: Value(normalizedOriginalOccurrenceDate),
                completedAt: Value(now),
                notes: Value(notes),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }

      // For non-repeating tasks, also update the completed flag on the task itself
      // This ensures queries filtering by tasks.completed work correctly
      final task = await (driftDb.select(
        driftDb.taskTable,
      )..where((t) => t.id.equals(taskId))).getSingleOrNull();

      final isRepeating = task?.repeatIcalRrule?.isNotEmpty ?? false;
      if (!isRepeating) {
        await (driftDb.update(
          driftDb.taskTable,
        )..where((t) => t.id.equals(taskId))).write(
          TaskTableCompanion(
            completed: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  @override
  Future<void> uncompleteTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    await _runGuarded('uncompleteTaskOccurrence', context, () async {
      final query = driftDb.delete(driftDb.taskCompletionHistoryTable)
        ..where((t) => t.taskId.equals(taskId));

      if (occurrenceDate != null) {
        final normalized = _normalizeDate(occurrenceDate);
        query.where((t) => t.occurrenceDate.equals(normalized));
      } else {
        query.where((t) => t.occurrenceDate.isNull());
      }

      await query.go();

      // For non-repeating tasks, also update the completed flag on the task itself
      final task = await (driftDb.select(
        driftDb.taskTable,
      )..where((t) => t.id.equals(taskId))).getSingleOrNull();

      final isRepeating = task?.repeatIcalRrule?.isNotEmpty ?? false;
      if (!isRepeating) {
        await (driftDb.update(
          driftDb.taskTable,
        )..where((t) => t.id.equals(taskId))).write(
          TaskTableCompanion(
            completed: const Value(false),
            updatedAt: Value(_clock.nowLocal()),
          ),
        );
      }
    });
  }

  @override
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    await _runGuarded('skipTaskOccurrence', context, () async {
      final now = _clock.nowLocal();

      // Generate deterministic v5 ID
      final id = idGenerator.taskRecurrenceExceptionId(
        taskId: taskId,
        originalDate: _normalizeDate(originalDate),
      );

      await driftDb
          .into(driftDb.taskRecurrenceExceptionsTable)
          .insert(
            TaskRecurrenceExceptionsTableCompanion.insert(
              id: id,
              taskId: taskId,
              originalDate: _normalizeDate(originalDate),
              exceptionType: ExceptionType.skip,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  @override
  Future<void> rescheduleTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async {
    await _runGuarded('rescheduleTaskOccurrence', context, () async {
      final now = _clock.nowLocal();

      // Generate deterministic v5 ID
      final id = idGenerator.taskRecurrenceExceptionId(
        taskId: taskId,
        originalDate: _normalizeDate(originalDate),
      );

      await driftDb
          .into(driftDb.taskRecurrenceExceptionsTable)
          .insert(
            TaskRecurrenceExceptionsTableCompanion.insert(
              id: id,
              taskId: taskId,
              originalDate: _normalizeDate(originalDate),
              exceptionType: ExceptionType.reschedule,
              newDate: Value(_normalizeDate(newDate)),
              newDeadline: Value(
                newDeadline == null ? null : _normalizeDate(newDeadline),
              ),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  @override
  Future<void> removeTaskException({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    await _runGuarded('removeTaskException', context, () async {
      await (driftDb.delete(driftDb.taskRecurrenceExceptionsTable)
            ..where((t) => t.taskId.equals(taskId))
            ..where(
              (t) => t.originalDate.equals(_normalizeDate(originalDate)),
            ))
          .go();
    });
  }

  @override
  Future<void> stopTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {
    await _runGuarded('stopTaskSeries', context, () async {
      await (driftDb.update(
        driftDb.taskTable,
      )..where((t) => t.id.equals(taskId))).write(
        TaskTableCompanion(
          seriesEnded: const Value(true),
          updatedAt: Value(_clock.nowLocal()),
        ),
      );
    });
  }

  @override
  Future<void> completeTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {
    await _runGuarded('completeTaskSeries', context, () async {
      // Set seriesEnded flag
      await stopTaskSeries(taskId, context: context);

      // Delete future exceptions (keep past ones for reporting)
      final today = _normalizeDate(_clock.nowLocal());
      await (driftDb.delete(driftDb.taskRecurrenceExceptionsTable)
            ..where((t) => t.taskId.equals(taskId))
            ..where((t) => t.originalDate.isBiggerOrEqualValue(today)))
          .go();
    });
  }

  @override
  Future<void> convertTaskToOneTime(
    String taskId, {
    OperationContext? context,
  }) async {
    await _runGuarded('convertTaskToOneTime', context, () async {
      // Complete the series (sets flag + deletes future exceptions)
      await completeTaskSeries(taskId, context: context);

      // Clear the recurrence rule
      await (driftDb.update(
        driftDb.taskTable,
      )..where((t) => t.id.equals(taskId))).write(
        TaskTableCompanion(
          repeatIcalRrule: const Value(null),
          repeatFromCompletion: const Value(false),
          updatedAt: Value(_clock.nowLocal()),
        ),
      );
    });
  }

  // ===========================================================================
  // PROJECT OCCURRENCE WRITES
  // ===========================================================================

  @override
  Future<void> completeProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    await _runGuarded('completeProjectOccurrence', context, () async {
      final normalizedOccurrenceDate = occurrenceDate != null
          ? _normalizeDate(occurrenceDate)
          : null;
      final normalizedOriginalDate = originalOccurrenceDate ?? occurrenceDate;
      final normalizedOriginalOccurrenceDate = normalizedOriginalDate != null
          ? _normalizeDate(normalizedOriginalDate)
          : null;
      final now = _clock.nowLocal();

      // Generate deterministic v5 ID
      final id = idGenerator.projectCompletionId(
        projectId: projectId,
        occurrenceDate: normalizedOccurrenceDate,
      );

      // Check if completion record already exists (PowerSync views don't support UPSERT)
      final existing = await (driftDb.select(
        driftDb.projectCompletionHistoryTable,
      )..where((p) => p.id.equals(id))).getSingleOrNull();

      if (existing != null) {
        // Update existing record
        await (driftDb.update(
          driftDb.projectCompletionHistoryTable,
        )..where((p) => p.id.equals(id))).write(
          ProjectCompletionHistoryTableCompanion(
            completedAt: Value(now),
            notes: Value(notes),
            updatedAt: Value(now),
          ),
        );
      } else {
        // Insert new record
        await driftDb
            .into(driftDb.projectCompletionHistoryTable)
            .insert(
              ProjectCompletionHistoryTableCompanion.insert(
                id: id,
                projectId: projectId,
                occurrenceDate: Value(normalizedOccurrenceDate),
                originalOccurrenceDate: Value(normalizedOriginalOccurrenceDate),
                completedAt: Value(now),
                notes: Value(notes),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );
      }

      // For non-repeating projects, also update the completed flag on the project itself
      // This ensures queries filtering by projects.completed work correctly
      final project = await (driftDb.select(
        driftDb.projectTable,
      )..where((p) => p.id.equals(projectId))).getSingleOrNull();

      final isRepeating = project?.repeatIcalRrule?.isNotEmpty ?? false;
      if (!isRepeating) {
        await (driftDb.update(
          driftDb.projectTable,
        )..where((p) => p.id.equals(projectId))).write(
          ProjectTableCompanion(
            completed: const Value(true),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  @override
  Future<void> uncompleteProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    await _runGuarded('uncompleteProjectOccurrence', context, () async {
      final query = driftDb.delete(driftDb.projectCompletionHistoryTable)
        ..where((p) => p.projectId.equals(projectId));

      if (occurrenceDate != null) {
        final normalized = _normalizeDate(occurrenceDate);
        query.where((p) => p.occurrenceDate.equals(normalized));
      } else {
        query.where((p) => p.occurrenceDate.isNull());
      }

      await query.go();

      // For non-repeating projects, also update the completed flag on the project itself
      final project = await (driftDb.select(
        driftDb.projectTable,
      )..where((p) => p.id.equals(projectId))).getSingleOrNull();

      final isRepeating = project?.repeatIcalRrule?.isNotEmpty ?? false;
      if (!isRepeating) {
        await (driftDb.update(
          driftDb.projectTable,
        )..where((p) => p.id.equals(projectId))).write(
          ProjectTableCompanion(
            completed: const Value(false),
            updatedAt: Value(_clock.nowLocal()),
          ),
        );
      }
    });
  }

  @override
  Future<void> skipProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    await _runGuarded('skipProjectOccurrence', context, () async {
      final now = _clock.nowLocal();

      // Generate deterministic v5 ID
      final id = idGenerator.projectRecurrenceExceptionId(
        projectId: projectId,
        originalDate: _normalizeDate(originalDate),
      );

      await driftDb
          .into(driftDb.projectRecurrenceExceptionsTable)
          .insert(
            ProjectRecurrenceExceptionsTableCompanion.insert(
              id: id,
              projectId: projectId,
              originalDate: _normalizeDate(originalDate),
              exceptionType: ExceptionType.skip,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  @override
  Future<void> rescheduleProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async {
    await _runGuarded('rescheduleProjectOccurrence', context, () async {
      final now = _clock.nowLocal();

      // Generate deterministic v5 ID
      final id = idGenerator.projectRecurrenceExceptionId(
        projectId: projectId,
        originalDate: _normalizeDate(originalDate),
      );

      await driftDb
          .into(driftDb.projectRecurrenceExceptionsTable)
          .insert(
            ProjectRecurrenceExceptionsTableCompanion.insert(
              id: id,
              projectId: projectId,
              originalDate: _normalizeDate(originalDate),
              exceptionType: ExceptionType.reschedule,
              newDate: Value(_normalizeDate(newDate)),
              newDeadline: Value(
                newDeadline == null ? null : _normalizeDate(newDeadline),
              ),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    });
  }

  @override
  Future<void> removeProjectException({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    await _runGuarded('removeProjectException', context, () async {
      await (driftDb.delete(driftDb.projectRecurrenceExceptionsTable)
            ..where((p) => p.projectId.equals(projectId))
            ..where(
              (p) => p.originalDate.equals(_normalizeDate(originalDate)),
            ))
          .go();
    });
  }

  @override
  Future<void> stopProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {
    await _runGuarded('stopProjectSeries', context, () async {
      await (driftDb.update(
        driftDb.projectTable,
      )..where((p) => p.id.equals(projectId))).write(
        ProjectTableCompanion(
          seriesEnded: const Value(true),
          updatedAt: Value(_clock.nowLocal()),
        ),
      );
    });
  }

  @override
  Future<void> completeProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {
    await _runGuarded('completeProjectSeries', context, () async {
      // Set seriesEnded flag
      await stopProjectSeries(projectId, context: context);

      // Delete future exceptions (keep past ones for reporting)
      final today = _normalizeDate(_clock.nowLocal());
      await (driftDb.delete(driftDb.projectRecurrenceExceptionsTable)
            ..where((p) => p.projectId.equals(projectId))
            ..where((p) => p.originalDate.isBiggerOrEqualValue(today)))
          .go();
    });
  }

  @override
  Future<void> convertProjectToOneTime(
    String projectId, {
    OperationContext? context,
  }) async {
    await _runGuarded('convertProjectToOneTime', context, () async {
      // Complete the series (sets flag + deletes future exceptions)
      await completeProjectSeries(projectId, context: context);

      // Clear the recurrence rule
      await (driftDb.update(
        driftDb.projectTable,
      )..where((p) => p.id.equals(projectId))).write(
        ProjectTableCompanion(
          repeatIcalRrule: const Value(null),
          repeatFromCompletion: const Value(false),
          updatedAt: Value(_clock.nowLocal()),
        ),
      );
    });
  }

  // ===========================================================================
  // PRIVATE: Helper Methods
  // ===========================================================================

  /// Normalize date to midnight (date-only).
  DateTime _normalizeDate(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }
}
