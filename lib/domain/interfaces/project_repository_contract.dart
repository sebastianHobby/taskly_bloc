import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

abstract class ProjectRepositoryContract {
  /// Watch projects with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all projects with related labels.
  ///
  /// Hydration contract:
  /// - [Project.values] is populated for all returned projects.
  /// - [Project.primaryValueId] is present when set.
  /// Query configuration determines:
  /// - Which projects to include (via filter)
  /// - How to sort results (via sortCriteria)
  /// - Whether to expand repeating projects into occurrences (via occurrenceExpansion)
  Stream<List<Project>> watchAll([ProjectQuery? query]);

  /// Watch the count of projects matching the optional [query].
  ///
  /// When [query] includes `occurrenceExpansion`, this counts expanded
  /// occurrences (virtual rows) instead of base project rows.
  Stream<int> watchAllCount([ProjectQuery? query]);

  /// Get projects with optional filtering, sorting, and occurrence expansion.
  ///
  /// If [query] is null, returns all projects with related labels.
  ///
  /// See [watchAll] for the hydration contract.
  Future<List<Project>> getAll([ProjectQuery? query]);

  /// Watch a project by ID with its related labels.
  ///
  /// See [watchAll] for the hydration contract.
  Stream<Project?> watchById(String id);

  /// Get a project by ID with its related labels.
  ///
  /// See [watchAll] for the hydration contract.
  Future<Project?> getById(String id);

  Future<void> create({
    required String name,
    String? description,
    bool completed = false,
    DateTime? startDate,
    DateTime? deadlineDate,
    String? repeatIcalRrule,
    bool repeatFromCompletion = false,
    bool seriesEnded = false,
    List<String>? valueIds,
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
    bool? seriesEnded,
    List<String>? valueIds,
    int? priority,
    bool? isPinned,
  });

  /// Set the pinned status of a project.
  Future<void> setPinned({
    required String id,
    required bool isPinned,
  });

  Future<void> delete(String id);

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
