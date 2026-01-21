import 'package:taskly_domain/src/domain.dart';
import 'package:taskly_domain/src/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_domain/src/queries/project_query.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

abstract class ProjectRepositoryContract {
  /// Watches completion history records for projects.
  Stream<List<CompletionHistoryData>> watchCompletionHistory();

  /// Watches recurrence exception records for projects.
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions();

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
  ///
  /// Stream contract:
  /// - broadcast: do not assume (implementations may return shared streams for
  ///   performance; consumers must not rely on multi-listen)
  /// - replay: none unless otherwise documented
  /// - cold/hot: typically hot
  ///
  /// Implementation rule: if an implementation caches streams, the cached
  /// stream must be broadcast/shared (do not cache raw single-sub streams).
  Stream<List<Project>> watchAll([ProjectQuery? query]);

  /// Watch the count of projects matching the optional [query].
  ///
  /// When [query] includes `occurrenceExpansion`, this counts expanded
  /// occurrences (virtual rows) instead of base project rows.
  ///
  /// Stream contract: same as [watchAll].
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
  ///
  /// Stream contract: same as [watchAll].
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
    OperationContext? context,
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
    OperationContext? context,
  });

  /// Set the pinned status of a project.
  Future<void> setPinned({
    required String id,
    required bool isPinned,
    OperationContext? context,
  });

  Future<void> delete(String id, {OperationContext? context});

  // =========================================================================
  // OCCURRENCE METHODS
  // =========================================================================

  /// Get project occurrences for a specific date range.
  Future<List<Project>> getOccurrences({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  });

  /// Get occurrences for a single project within a specific date range.
  ///
  /// Prefer this over [getOccurrences] when you only need occurrences for a
  /// single project, to avoid expanding all projects.
  Future<List<Project>> getOccurrencesForProject({
    required String projectId,
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
    OperationContext? context,
  });

  /// Remove completion for a specific occurrence.
  Future<void> uncompleteOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  });

  /// Skip a specific occurrence.
  Future<void> skipOccurrence({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  });

  /// Reschedule a specific occurrence.
  Future<void> rescheduleOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    OperationContext? context,
  });
}
