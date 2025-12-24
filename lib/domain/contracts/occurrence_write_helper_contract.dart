/// Contract for the occurrence write helper.
///
/// Handles all write operations for occurrence-specific mutations such as
/// completing, skipping, and rescheduling occurrences.
abstract class OccurrenceWriteHelperContract {
  // ===========================================================================
  // TASK OCCURRENCE WRITES
  // ===========================================================================

  /// Marks a task occurrence as complete.
  ///
  /// For repeating tasks, creates a completion record with the occurrence date.
  /// For non-repeating tasks, creates a completion record with null occurrence date.
  ///
  /// [taskId] - The task's unique identifier
  /// [occurrenceDate] - The occurrence date (null for non-repeating tasks)
  /// [originalOccurrenceDate] - The original RRULE date if rescheduled
  /// [notes] - Optional completion notes
  Future<void> completeTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  });

  /// Removes completion for a task occurrence.
  ///
  /// [taskId] - The task's unique identifier
  /// [occurrenceDate] - The occurrence date (null for non-repeating tasks)
  Future<void> uncompleteTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
  });

  /// Skips a task occurrence (will not appear in expansion).
  ///
  /// [taskId] - The task's unique identifier
  /// [originalDate] - The RRULE-generated date to skip
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
  });

  /// Reschedules a task occurrence to a new date.
  ///
  /// If [newDeadline] is not provided, the deadline will be calculated
  /// by applying the original start→deadline offset to [newDate].
  ///
  /// [taskId] - The task's unique identifier
  /// [originalDate] - The RRULE-generated date being rescheduled
  /// [newDate] - The target date for the rescheduled occurrence
  /// [newDeadline] - Optional explicit deadline override
  Future<void> rescheduleTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
  });

  /// Removes an exception (skip or reschedule) for a task occurrence.
  ///
  /// [taskId] - The task's unique identifier
  /// [originalDate] - The RRULE-generated date of the exception to remove
  Future<void> removeTaskException({
    required String taskId,
    required DateTime originalDate,
  });

  /// Stops generating future occurrences for a repeating task.
  /// Keeps all history intact.
  ///
  /// [taskId] - The task's unique identifier
  Future<void> stopTaskSeries(String taskId);

  /// Completes the task series: stops future occurrences and deletes
  /// future exceptions (past exceptions kept for reporting).
  ///
  /// [taskId] - The task's unique identifier
  Future<void> completeTaskSeries(String taskId);

  /// Converts a repeating task to a one-time task: stops future occurrences,
  /// deletes future exceptions, and clears the recurrence rule.
  ///
  /// [taskId] - The task's unique identifier
  Future<void> convertTaskToOneTime(String taskId);

  // ===========================================================================
  // PROJECT OCCURRENCE WRITES
  // ===========================================================================

  /// Marks a project occurrence as complete.
  ///
  /// For repeating projects, creates a completion record with the occurrence date.
  /// For non-repeating projects, creates a completion record with null occurrence date.
  ///
  /// [projectId] - The project's unique identifier
  /// [occurrenceDate] - The occurrence date (null for non-repeating projects)
  /// [originalOccurrenceDate] - The original RRULE date if rescheduled
  /// [notes] - Optional completion notes
  Future<void> completeProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  });

  /// Removes completion for a project occurrence.
  ///
  /// [projectId] - The project's unique identifier
  /// [occurrenceDate] - The occurrence date (null for non-repeating projects)
  Future<void> uncompleteProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
  });

  /// Skips a project occurrence (will not appear in expansion).
  ///
  /// [projectId] - The project's unique identifier
  /// [originalDate] - The RRULE-generated date to skip
  Future<void> skipProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
  });

  /// Reschedules a project occurrence to a new date.
  ///
  /// If [newDeadline] is not provided, the deadline will be calculated
  /// by applying the original start→deadline offset to [newDate].
  ///
  /// [projectId] - The project's unique identifier
  /// [originalDate] - The RRULE-generated date being rescheduled
  /// [newDate] - The target date for the rescheduled occurrence
  /// [newDeadline] - Optional explicit deadline override
  Future<void> rescheduleProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
  });

  /// Removes an exception (skip or reschedule) for a project occurrence.
  ///
  /// [projectId] - The project's unique identifier
  /// [originalDate] - The RRULE-generated date of the exception to remove
  Future<void> removeProjectException({
    required String projectId,
    required DateTime originalDate,
  });

  /// Stops generating future occurrences for a repeating project.
  /// Keeps all history intact.
  ///
  /// [projectId] - The project's unique identifier
  Future<void> stopProjectSeries(String projectId);

  /// Completes the project series: stops future occurrences and deletes
  /// future exceptions (past exceptions kept for reporting).
  ///
  /// [projectId] - The project's unique identifier
  Future<void> completeProjectSeries(String projectId);

  /// Converts a repeating project to a one-time project: stops future occurrences,
  /// deletes future exceptions, and clears the recurrence rule.
  ///
  /// [projectId] - The project's unique identifier
  Future<void> convertProjectToOneTime(String projectId);
}
