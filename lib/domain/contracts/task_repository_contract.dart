import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';

abstract class TaskRepositoryContract {
  /// Watch tasks with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all tasks with related entities.
  /// Query configuration determines:
  /// - Which tasks to include (via rules)
  /// - How to sort results (via sortCriteria)
  /// - Whether to expand repeating tasks into occurrences (via occurrenceExpansion)
  ///
  /// All filtering happens at the database level for optimal performance.
  Stream<List<Task>> watchAll([TaskQuery? query]);

  /// Count tasks matching the optional [query].
  ///
  /// When [query] includes `occurrenceExpansion`, this counts expanded
  /// occurrences (virtual rows) instead of base task rows.
  Future<int> count([TaskQuery? query]);

  /// Watch the count of tasks matching the optional [query].
  ///
  /// When [query] includes `occurrenceExpansion`, this counts expanded
  /// occurrences (virtual rows) instead of base task rows.
  Stream<int> watchCount([TaskQuery? query]);

  /// Get a single task by ID with related entities.
  Future<Task?> getById(String id);

  /// Watch a single task by ID with related entities.
  Stream<Task?> watchById(String id);

  /// Watch task counts for all projects.
  /// Returns a stream of maps where keys are project IDs.
  Stream<Map<String, ProjectTaskCounts>> watchTaskCountsByProject();

  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    List<String>? labelIds,
  });

  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? labelIds,
  });

  Future<void> delete(String id);

  // =========================================================================
  // OCCURRENCE METHODS
  // =========================================================================

  /// Get task occurrences for a specific date range.
  ///
  /// Returns [Task] instances with the [Task.occurrence] field populated.
  /// For repeating tasks, this expands the RRULE pattern and applies any
  /// exceptions (skip/reschedule). For non-repeating tasks, returns a single
  /// occurrence if the task's date falls within the range.
  Future<List<Task>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  /// Watch task occurrences for a specific date range.
  ///
  /// Returns a stream of [Task] instances with [Task.occurrence] populated.
  /// Emits a new list whenever tasks, completions, or exceptions change.
  Stream<List<Task>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  /// Complete a specific task occurrence.
  ///
  /// For repeating tasks, [occurrenceDate] and [originalOccurrenceDate] must
  /// be provided. For non-repeating tasks, both can be null.
  Future<void> completeOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  });

  /// Uncomplete a specific task occurrence.
  ///
  /// Removes the completion record for the given occurrence.
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
  });

  /// Skip a specific occurrence of a repeating task.
  ///
  /// Creates an exception that removes this occurrence from the series.
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
  });

  /// Reschedule a specific occurrence of a repeating task.
  ///
  /// Creates an exception that moves this occurrence to a new date.
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
  });

  /// Remove an exception for a task occurrence.
  ///
  /// This restores the occurrence to its original RRULE-generated state.
  Future<void> removeException({
    required String taskId,
    required DateTime originalDate,
  });

  /// Stop a repeating task series.
  ///
  /// Sets the seriesEnded flag to true, preventing future occurrences from
  /// being generated. Keeps all history intact.
  Future<void> stopSeries(String taskId);

  /// Complete a repeating task series.
  ///
  /// Sets the seriesEnded flag and deletes future exceptions.
  /// Past exceptions are kept for reporting.
  Future<void> completeSeries(String taskId);

  /// Convert a repeating task to a one-time task.
  ///
  /// Sets the seriesEnded flag, deletes future exceptions, and clears
  /// the recurrence rule.
  Future<void> convertToOneTime(String taskId);
}
