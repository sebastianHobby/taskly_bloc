import 'package:taskly_domain/src/core/model/project.dart';
import 'package:taskly_domain/src/core/model/task.dart';

/// Contract for the occurrence stream expander.
///
/// Provides stream extension capabilities for transforming raw database
/// streams into expanded occurrence streams.
abstract class OccurrenceStreamExpanderContract {
  /// Expands a stream of tasks with their completion and exception data
  /// into a stream of tasks with populated occurrence data.
  ///
  /// The returned stream applies a 50ms debounce to prevent rapid re-expansions
  /// when multiple underlying tables update in quick succession.
  ///
  /// [postExpansionFilter] optionally applies filtering to expanded occurrences
  /// AFTER expansion. This enables two-phase filtering where date rules are
  /// applied to virtual occurrence dates rather than base task dates.
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  });

  /// Expands a stream of projects with their completion and exception data
  /// into a stream of projects with populated occurrence data.
  ///
  /// The returned stream applies a 50ms debounce to prevent rapid re-expansions
  /// when multiple underlying tables update in quick succession.
  Stream<List<Project>> expandProjectOccurrences({
    required Stream<List<Project>> projectsStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  });

  /// Synchronously expands tasks for a given date range.
  /// Useful for one-off fetches rather than streams.
  ///
  /// [postExpansionFilter] optionally applies filtering to expanded occurrences
  /// AFTER expansion. This enables two-phase filtering where date rules are
  /// applied to virtual occurrence dates rather than base task dates.
  List<Task> expandTaskOccurrencesSync({
    required List<Task> tasks,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  });

  /// Synchronously expands projects for a given date range.
  /// Useful for one-off fetches rather than streams.
  List<Project> expandProjectOccurrencesSync({
    required List<Project> projects,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  });
}

/// Data transfer object for completion history records.
/// Used to pass completion data from DB to the expander.
class CompletionHistoryData {
  const CompletionHistoryData({
    required this.id,
    required this.entityId,
    required this.completedAt,
    this.occurrenceDate,
    this.originalOccurrenceDate,
    this.notes,
  });

  /// The completion record's unique ID.
  final String id;

  /// The task or project ID this completion belongs to.
  final String entityId;

  /// The scheduled date of the occurrence. NULL for non-repeating entities.
  final DateTime? occurrenceDate;

  /// Original RRULE-generated date. For rescheduled entities, this differs
  /// from [occurrenceDate]. Used for on-time reporting.
  final DateTime? originalOccurrenceDate;

  /// When the occurrence was completed.
  final DateTime completedAt;

  /// Optional notes added when completing.
  final String? notes;
}

/// Data transfer object for recurrence exception records.
/// Used to pass exception data from DB to the expander.
class RecurrenceExceptionData {
  const RecurrenceExceptionData({
    required this.id,
    required this.entityId,
    required this.originalDate,
    required this.exceptionType,
    this.newDate,
    this.newDeadline,
  });

  /// The exception record's unique ID.
  final String id;

  /// The task or project ID this exception belongs to.
  final String entityId;

  /// The original RRULE-generated date being modified.
  final DateTime originalDate;

  /// The type of exception: skip or reschedule.
  final RecurrenceExceptionType exceptionType;

  /// Target date for reschedule (NULL if skip).
  final DateTime? newDate;

  /// Override deadline for rescheduled occurrence (NULL = inherit offset).
  final DateTime? newDeadline;
}

/// Exception types for recurrence modifications.
enum RecurrenceExceptionType {
  /// Skip this occurrence entirely.
  skip,

  /// Reschedule to a different date.
  reschedule,
}
