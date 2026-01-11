import 'package:drift/drift.dart';
import 'package:taskly_bloc/shared/logging/app_log.dart';
import 'package:taskly_bloc/domain/time/date_only.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/interfaces/occurrence_write_helper_contract.dart';

/// Implementation of [OccurrenceWriteHelperContract].
///
/// Handles all write operations for occurrence-specific mutations.
/// Uses IdGenerator for deterministic v5 IDs.
class OccurrenceWriteHelper implements OccurrenceWriteHelperContract {
  OccurrenceWriteHelper({
    required this.driftDb,
    required this.idGenerator,
  });

  final AppDatabase driftDb;
  final IdGenerator idGenerator;

  // ===========================================================================
  // TASK OCCURRENCE WRITES
  // ===========================================================================

  @override
  Future<void> completeTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  }) async {
    AppLog.routine(
      'data.occurrence_write',
      'completeTaskOccurrence called: taskId=$taskId, '
          'occurrenceDate=$occurrenceDate',
    );
    final normalizedOccurrenceDate = occurrenceDate != null
        ? _normalizeDate(occurrenceDate)
        : null;
    final normalizedOriginalDate = originalOccurrenceDate ?? occurrenceDate;
    final normalizedOriginalOccurrenceDate = normalizedOriginalDate != null
        ? _normalizeDate(normalizedOriginalDate)
        : null;
    final now = DateTime.now();

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
      AppLog.routine(
        'data.occurrence_write',
        'Completion record exists, updating: id=$id',
      );
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
      AppLog.routine(
        'data.occurrence_write',
        'Inserting new completion record: id=$id',
      );
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
    AppLog.routine(
      'data.occurrence_write',
      'Task lookup: found=${task != null}, isRepeating=$isRepeating, '
          'rrule=${task?.repeatIcalRrule}',
    );
    if (!isRepeating) {
      AppLog.routine(
        'data.occurrence_write',
        'Updating tasks.completed=true for taskId=$taskId',
      );
      await (driftDb.update(
        driftDb.taskTable,
      )..where((t) => t.id.equals(taskId))).write(
        TaskTableCompanion(
          completed: const Value(true),
          updatedAt: Value(now),
        ),
      );
      AppLog.routine(
        'data.occurrence_write',
        'Update complete for taskId=$taskId',
      );
    } else {
      AppLog.routine(
        'data.occurrence_write',
        'Skipping completed flag update (repeating task)',
      );
    }
  }

  @override
  Future<void> uncompleteTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
  }) async {
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
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  @override
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
  }) async {
    final now = DateTime.now();

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
  }

  @override
  Future<void> rescheduleTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
  }) async {
    final now = DateTime.now();

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
  }

  @override
  Future<void> removeTaskException({
    required String taskId,
    required DateTime originalDate,
  }) async {
    await (driftDb.delete(driftDb.taskRecurrenceExceptionsTable)
          ..where((t) => t.taskId.equals(taskId))
          ..where((t) => t.originalDate.equals(_normalizeDate(originalDate))))
        .go();
  }

  @override
  Future<void> stopTaskSeries(String taskId) async {
    await (driftDb.update(
      driftDb.taskTable,
    )..where((t) => t.id.equals(taskId))).write(
      TaskTableCompanion(
        seriesEnded: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> completeTaskSeries(String taskId) async {
    // Set seriesEnded flag
    await stopTaskSeries(taskId);

    // Delete future exceptions (keep past ones for reporting)
    final today = _normalizeDate(DateTime.now());
    await (driftDb.delete(driftDb.taskRecurrenceExceptionsTable)
          ..where((t) => t.taskId.equals(taskId))
          ..where((t) => t.originalDate.isBiggerOrEqualValue(today)))
        .go();
  }

  @override
  Future<void> convertTaskToOneTime(String taskId) async {
    // Complete the series (sets flag + deletes future exceptions)
    await completeTaskSeries(taskId);

    // Clear the recurrence rule
    await (driftDb.update(
      driftDb.taskTable,
    )..where((t) => t.id.equals(taskId))).write(
      TaskTableCompanion(
        repeatIcalRrule: const Value(null),
        repeatFromCompletion: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
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
  }) async {
    final normalizedOccurrenceDate = occurrenceDate != null
        ? _normalizeDate(occurrenceDate)
        : null;
    final normalizedOriginalDate = originalOccurrenceDate ?? occurrenceDate;
    final normalizedOriginalOccurrenceDate = normalizedOriginalDate != null
        ? _normalizeDate(normalizedOriginalDate)
        : null;
    final now = DateTime.now();

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
  }

  @override
  Future<void> uncompleteProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
  }) async {
    final query = driftDb.delete(driftDb.projectCompletionHistoryTable)
      ..where((t) => t.projectId.equals(projectId));

    if (occurrenceDate != null) {
      final normalized = _normalizeDate(occurrenceDate);
      query.where((t) => t.occurrenceDate.equals(normalized));
    } else {
      query.where((t) => t.occurrenceDate.isNull());
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
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  @override
  Future<void> skipProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
  }) async {
    final now = DateTime.now();

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
  }

  @override
  Future<void> rescheduleProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
  }) async {
    final now = DateTime.now();

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
  }

  @override
  Future<void> removeProjectException({
    required String projectId,
    required DateTime originalDate,
  }) async {
    await (driftDb.delete(driftDb.projectRecurrenceExceptionsTable)
          ..where((t) => t.projectId.equals(projectId))
          ..where((t) => t.originalDate.equals(_normalizeDate(originalDate))))
        .go();
  }

  @override
  Future<void> stopProjectSeries(String projectId) async {
    await (driftDb.update(
      driftDb.projectTable,
    )..where((t) => t.id.equals(projectId))).write(
      ProjectTableCompanion(
        seriesEnded: const Value(true),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> completeProjectSeries(String projectId) async {
    // Set seriesEnded flag
    await stopProjectSeries(projectId);

    // Delete future exceptions (keep past ones for reporting)
    final today = _normalizeDate(DateTime.now());
    await (driftDb.delete(driftDb.projectRecurrenceExceptionsTable)
          ..where((t) => t.projectId.equals(projectId))
          ..where((t) => t.originalDate.isBiggerOrEqualValue(today)))
        .go();
  }

  @override
  Future<void> convertProjectToOneTime(String projectId) async {
    // Complete the series (sets flag + deletes future exceptions)
    await completeProjectSeries(projectId);

    // Clear the recurrence rule
    await (driftDb.update(
      driftDb.projectTable,
    )..where((t) => t.id.equals(projectId))).write(
      ProjectTableCompanion(
        repeatIcalRrule: const Value(null),
        repeatFromCompletion: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ===========================================================================
  // UTILITIES
  // ===========================================================================

  /// Normalizes a DateTime to midnight (date only, no time component).
  DateTime _normalizeDate(DateTime date) {
    return dateOnly(date);
  }
}
