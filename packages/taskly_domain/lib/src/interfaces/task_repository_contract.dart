import 'package:taskly_domain/src/domain.dart';
import 'package:taskly_domain/src/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_domain/src/queries/task_query.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class TaskRepositoryContract {
  /// Watches completion history records for tasks.
  ///
  /// This is used by occurrence-aware read services to merge completion state
  /// into expanded occurrences.
  Stream<List<CompletionHistoryData>> watchCompletionHistory();

  /// Watches recurrence exception records for tasks.
  ///
  /// This is used by occurrence-aware read services to apply skips/reschedules
  /// during occurrence expansion.
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions();

  /// Watch tasks with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all tasks with related entities.
  ///
  /// Hydration contract:
  /// - [Task.project] is populated when [Task.projectId] is non-null.
  /// - [Task.values] contains the task's explicitly assigned values.
  /// - When [Task.project] is populated, it includes its values so callers can
  ///   reliably compute effective values via `Task.effectiveValues`.
  /// Query configuration determines:
  /// - Which tasks to include (via rules)
  /// - How to sort results (via sortCriteria)
  /// - Whether to expand repeating tasks into occurrences (via occurrenceExpansion)
  ///
  /// All filtering happens at the database level for optimal performance.
  ///
  /// Stream contract:
  /// - broadcast: do not assume (implementations may return shared streams for
  ///   performance; consumers must not rely on multi-listen)
  /// - replay: none unless otherwise documented
  /// - cold/hot: typically hot
  ///
  /// Implementation rule: if an implementation caches streams, the cached
  /// stream must be broadcast/shared (do not cache raw single-sub streams).
  Stream<List<Task>> watchAll([TaskQuery? query]);

  /// Get tasks with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all tasks with related entities.
  ///
  /// See [watchAll] for the hydration contract.
  Future<List<Task>> getAll([TaskQuery? query]);

  /// Watch the count of tasks matching the optional [query].
  ///
  /// When [query] includes `occurrenceExpansion`, this counts expanded
  /// occurrences (virtual rows) instead of base task rows.
  ///
  /// Stream contract: same as [watchAll].
  Stream<int> watchAllCount([TaskQuery? query]);

  /// Get a single task by ID with related entities.
  ///
  /// See [watchAll] for the hydration contract.
  Future<Task?> getById(String id);

  /// Get multiple tasks by ID with related entities.
  ///
  /// The returned list preserves the order of [ids]. Missing tasks are omitted.
  ///
  /// See [watchAll] for the hydration contract.
  Future<List<Task>> getByIds(Iterable<String> ids);

  /// Watch a single task by ID with related entities.
  ///
  /// See [watchAll] for the hydration contract.
  ///
  /// Stream contract: same as [watchAll].
  Stream<Task?> watchById(String id);

  /// Watch multiple tasks by ID with related entities.
  ///
  /// The emitted list preserves the order of [ids]. Missing tasks are omitted.
  ///
  /// See [watchAll] for the hydration contract.
  ///
  /// Stream contract: same as [watchAll].
  Stream<List<Task>> watchByIds(Iterable<String> ids);

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
    bool seriesEnded = false,
    List<String>? valueIds,
    List<String> checklistTitles = const <String>[],
    OperationContext? context,
  });

  Future<String> createReturningId({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? projectId,
    int? priority,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<String>? valueIds,
    List<String> checklistTitles = const <String>[],
    OperationContext? context,
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
    bool? seriesEnded,
    List<String>? valueIds,
    bool? isPinned,
    List<String> checklistTitles = const <String>[],
    OperationContext? context,
  });

  /// Bulk update task deadlines.
  ///
  /// This operation is atomic: either all tasks are updated or the call fails.
  /// Returns the number of updated tasks.
  Future<int> bulkRescheduleDeadlines({
    required Iterable<String> taskIds,
    required DateTime deadlineDate,
    OperationContext? context,
  });

  /// Bulk update task start dates.
  ///
  /// This operation is atomic: either all tasks are updated or the call fails.
  /// Returns the number of updated tasks.
  Future<int> bulkRescheduleStarts({
    required Iterable<String> taskIds,
    required DateTime startDate,
    OperationContext? context,
  });

  /// Set the pinned status of a task.
  Future<void> setPinned({
    required String id,
    required bool isPinned,
    OperationContext? context,
  });

  /// Sets (or clears) the My Day snooze-until timestamp for a task.
  ///
  /// When [untilUtc] is non-null and in the future, My Day surfaces should
  /// suppress this task until that time.
  Future<void> setMyDaySnoozedUntil({
    required String id,
    required DateTime? untilUtc,
    OperationContext? context,
  });

  /// Returns snooze statistics for tasks in the given UTC window.
  ///
  /// The returned map is keyed by task ID.
  Future<Map<String, TaskSnoozeStats>> getSnoozeStats({
    required DateTime sinceUtc,
    required DateTime untilUtc,
  });

  Future<void> delete(String id, {OperationContext? context});

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

  /// Get occurrences for a single task within a specific date range.
  ///
  /// Prefer this over [getOccurrences] when you only need occurrences for a
  /// single task, to avoid expanding all tasks.
  Future<List<Task>> getOccurrencesForTask({
    required String taskId,
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
    OperationContext? context,
  });

  /// Remove completion for a specific occurrence.
  ///
  /// [taskId] - The task's unique identifier
  /// [occurrenceDate] - The occurrence date (null for non-repeating tasks)
  Future<void> uncompleteOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  });

  /// Skip a specific occurrence (won't appear in expansion).
  ///
  /// [taskId] - The task's unique identifier
  /// [originalDate] - The RRULE-generated date to skip
  Future<void> skipOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
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
    OperationContext? context,
  });
}
