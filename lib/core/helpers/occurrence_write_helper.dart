import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/domain/contracts/occurrence_write_helper_contract.dart';

/// Implementation of [OccurrenceWriteHelperContract].
///
/// Handles all write operations for occurrence-specific mutations.
/// Generates UUIDs internally for new records.
class OccurrenceWriteHelper implements OccurrenceWriteHelperContract {
  OccurrenceWriteHelper({required this.driftDb});

  final AppDatabase driftDb;

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
    final now = DateTime.now();
    await driftDb
        .into(driftDb.taskCompletionHistoryTable)
        .insert(
          TaskCompletionHistoryTableCompanion.insert(
            id: Value(uuid.v4()),
            taskId: taskId,
            occurrenceDate: Value(occurrenceDate),
            originalOccurrenceDate: Value(
              originalOccurrenceDate ?? occurrenceDate,
            ),
            completedAt: Value(now),
            notes: Value(notes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
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
  }

  @override
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
  }) async {
    final now = DateTime.now();
    await driftDb
        .into(driftDb.taskRecurrenceExceptionsTable)
        .insert(
          TaskRecurrenceExceptionsTableCompanion.insert(
            id: Value(uuid.v4()),
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
    await driftDb
        .into(driftDb.taskRecurrenceExceptionsTable)
        .insert(
          TaskRecurrenceExceptionsTableCompanion.insert(
            id: Value(uuid.v4()),
            taskId: taskId,
            originalDate: _normalizeDate(originalDate),
            exceptionType: ExceptionType.reschedule,
            newDate: Value(_normalizeDate(newDate)),
            newDeadline: Value(newDeadline),
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
    final now = DateTime.now();
    await driftDb
        .into(driftDb.projectCompletionHistoryTable)
        .insert(
          ProjectCompletionHistoryTableCompanion.insert(
            id: Value(uuid.v4()),
            projectId: projectId,
            occurrenceDate: Value(occurrenceDate),
            originalOccurrenceDate: Value(
              originalOccurrenceDate ?? occurrenceDate,
            ),
            completedAt: Value(now),
            notes: Value(notes),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
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
  }

  @override
  Future<void> skipProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
  }) async {
    final now = DateTime.now();
    await driftDb
        .into(driftDb.projectRecurrenceExceptionsTable)
        .insert(
          ProjectRecurrenceExceptionsTableCompanion.insert(
            id: Value(uuid.v4()),
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
    await driftDb
        .into(driftDb.projectRecurrenceExceptionsTable)
        .insert(
          ProjectRecurrenceExceptionsTableCompanion.insert(
            id: Value(uuid.v4()),
            projectId: projectId,
            originalDate: _normalizeDate(originalDate),
            exceptionType: ExceptionType.reschedule,
            newDate: Value(_normalizeDate(newDate)),
            newDeadline: Value(newDeadline),
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
    return DateTime(date.year, date.month, date.day);
  }
}
