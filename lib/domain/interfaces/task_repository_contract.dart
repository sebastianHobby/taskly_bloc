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

  /// Get tasks with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all tasks with related entities.
  Future<List<Task>> getAll([TaskQuery? query]);

  /// Watch the count of tasks matching the optional [query].
  ///
  /// When [query] includes `occurrenceExpansion`, this counts expanded
  /// occurrences (virtual rows) instead of base task rows.
  Stream<int> watchAllCount([TaskQuery? query]);

  /// Get a single task by ID with related entities.
  Future<Task?> getById(String id);

  /// Watch a single task by ID with related entities.
  Stream<Task?> watchById(String id);

  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    List<String>? valueIds,
  });

  Future<void> update({
    required String id,
    required String name,
    required bool completed,
    String? description,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? valueIds,
    bool? isPinned,
  });

  /// Set the pinned status of a task.
  Future<void> setPinned({
    required String id,
    required bool isPinned,
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

  // =========================================================================
  // OCCURRENCE MUTATIONS
  // =========================================================================

  /// Mark a specific occurrence as complete.
  ///
  /// [taskId] - The task's unique identifier
  /// [occurrenceDate] - The occurrence date (null for non-repeating tasks)
  /// [originalOccurrenceDate] - For rescheduled occurrences, the original date
  /// [notes] - Optional completion notes
  Future<void> completeOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  });

  /// Remove completion for a specific occurrence.
  ///
  /// [taskId] - The task's unique identifier
  /// [occurrenceDate] - The occurrence date (null for non-repeating tasks)
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
  });

  /// Skip a specific occurrence (won't appear in expansion).
  ///
  /// [taskId] - The task's unique identifier
  /// [originalDate] - The RRULE-generated date to skip
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
  });

  /// Reschedule a specific occurrence to a new date.
  ///
  /// [taskId] - The task's unique identifier
  /// [originalDate] - The RRULE-generated date being rescheduled
  /// [newDate] - The new date for this occurrence
  Future<void> rescheduleOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
  });
}
