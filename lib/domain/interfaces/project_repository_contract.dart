import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

abstract class ProjectRepositoryContract {
  Stream<List<Project>> watchAll({bool withRelated = false});
  Future<List<Project>> getAll({bool withRelated = false});
  Stream<Project?> watchById(String id, {bool withRelated = false});
  Future<Project?> getById(String id, {bool withRelated = false});

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
    int? priority,
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
    int? priority,
  });

  Future<void> delete(String id);

  /// Update the lastReviewedAt timestamp for a project.
  /// Used by workflow completion to track when entities were last reviewed.
  Future<void> updateLastReviewedAt({
    required String id,
    required DateTime reviewedAt,
  });

  // =========================================================================
  // OCCURRENCE METHODS
  // =========================================================================

  /// Get project occurrences for a specific date range.
  Future<List<Project>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  /// Watch project occurrences for a specific date range.
  Stream<List<Project>> watchOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  // =========================================================================
  // OCCURRENCE MUTATIONS
  // =========================================================================

  /// Mark a specific occurrence as complete.
  Future<void> completeOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
  });

  /// Remove completion for a specific occurrence.
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
  });

  /// Skip a specific occurrence.
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
  });

  /// Reschedule a specific occurrence.
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
  });
}
