import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

abstract class ProjectRepositoryContract {
  Stream<List<Project>> watchAll({bool withRelated = false});
  Future<List<Project>> getAll({bool withRelated = false});
  Stream<Project?> watch(String id, {bool withRelated = false});
  Future<Project?> get(String id, {bool withRelated = false});

  /// Watch projects matching a [query].
  ///
  /// This mirrors `TaskRepositoryContract.watchAll([TaskQuery?])` and enables
  /// list retrieval for features that need SQL-level filtering.
  Stream<List<Project>> watchAllByQuery(
    ProjectQuery query, {
    bool withRelated = false,
  });

  /// Get projects matching a [query].
  Future<List<Project>> getAllByQuery(
    ProjectQuery query, {
    bool withRelated = false,
  });

  /// Count projects matching the optional [query].
  ///
  /// When [query] includes `occurrenceExpansion`, this counts expanded
  /// occurrences (virtual rows) instead of base project rows.
  Future<int> count([ProjectQuery? query]);

  /// Watch the count of projects matching the optional [query].
  ///
  /// When [query] includes `occurrenceExpansion`, this counts expanded
  /// occurrences (virtual rows) instead of base project rows.
  Stream<int> watchCount([ProjectQuery? query]);

  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
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
    String? repeatIcalRrule,
    bool? repeatFromCompletion,
    List<String>? labelIds,
  });
  Future<void> delete(String id);

  // =========================================================================
  // OCCURRENCE METHODS
  // =========================================================================

  /// Get project occurrences for a specific date range.
  ///
  /// Returns [Project] instances with the [Project.occurrence] field populated.
  /// For repeating projects, this expands the RRULE pattern and applies any
  /// exceptions (skip/reschedule). For non-repeating projects, returns a
  /// single occurrence if the project's date falls within the range.
  Future<List<Project>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  /// Watch project occurrences for a specific date range.
  ///
  /// Returns a stream of [Project] instances with [Project.occurrence] populated.
  /// Emits a new list whenever projects, completions, or exceptions change.
  Stream<List<Project>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  /// Complete a specific project occurrence.
  ///
  /// For repeating projects, [occurrenceDate] and [originalOccurrenceDate]
  /// must be provided. For non-repeating projects, both can be null.
  Future<void> completeOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  });

  /// Uncomplete a specific project occurrence.
  ///
  /// Removes the completion record for the given occurrence.
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
  });

  /// Skip a specific occurrence of a repeating project.
  ///
  /// Creates an exception that removes this occurrence from the series.
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
  });

  /// Reschedule a specific occurrence of a repeating project.
  ///
  /// Creates an exception that moves this occurrence to a new date.
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
  });

  /// Remove an exception for a project occurrence.
  ///
  /// This restores the occurrence to its original RRULE-generated state.
  Future<void> removeException({
    required String projectId,
    required DateTime originalDate,
  });

  /// Stop a repeating project series.
  ///
  /// Sets the seriesEnded flag to true, preventing future occurrences from
  /// being generated. Keeps all history intact.
  Future<void> stopSeries(String projectId);

  /// Complete a repeating project series.
  ///
  /// Sets the seriesEnded flag and deletes future exceptions.
  /// Past exceptions are kept for reporting.
  Future<void> completeSeries(String projectId);

  /// Convert a repeating project to a one-time project.
  ///
  /// Sets the seriesEnded flag, deletes future exceptions, and clears
  /// the recurrence rule.
  Future<void> convertToOneTime(String projectId);
}
