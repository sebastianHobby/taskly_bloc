import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

import 'package:taskly_domain/src/filtering/evaluation_context.dart';
import 'package:taskly_domain/src/queries/project_filter_evaluator.dart';
import 'package:taskly_domain/src/queries/task_filter_evaluator.dart';

/// Domain read-service that owns occurrence-aware query orchestration.
///
/// This is the single place that implements:
/// - two-phase filtering for occurrence expansion (SQL candidate set +
///   post-expansion filter on occurrence dates)
/// - next-occurrence preview decoration (Projects-style single next occurrence)
final class OccurrenceReadService {
  OccurrenceReadService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required HomeDayKeyService dayKeyService,
    OccurrenceStreamExpanderContract? occurrenceExpander,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _dayKeyService = dayKeyService,
       _occurrenceExpander = occurrenceExpander ?? OccurrenceStreamExpander(),
       _taskFilterEvaluator = const TaskFilterEvaluator(),
       _projectFilterEvaluator = const ProjectFilterEvaluator();

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;
  final HomeDayKeyService _dayKeyService;
  final OccurrenceStreamExpanderContract _occurrenceExpander;

  final TaskFilterEvaluator _taskFilterEvaluator;
  final ProjectFilterEvaluator _projectFilterEvaluator;

  /// Watches tasks and decorates repeating tasks with a single “next” occurrence
  /// based on [preview].
  Stream<List<Task>> watchTasksWithOccurrencePreview({
    required TaskQuery query,
    required OccurrencePreview preview,
  }) {
    final baseQuery = query.copyWith(
      clearOccurrenceExpansion: true,
      clearOccurrencePreview: true,
    );

    final baseTasksStream = _taskRepository.watchAll(baseQuery);

    final range = OccurrencePolicy.previewRange(preview);
    final asOfDayKey = range.asOfDayKey;

    final nextOccurrenceByTaskIdStream = _occurrenceExpander
        .expandTaskOccurrences(
          tasksStream: baseTasksStream,
          completionsStream: _taskRepository.watchCompletionHistory(),
          exceptionsStream: _taskRepository.watchRecurrenceExceptions(),
          rangeStart: range.rangeStart,
          rangeEnd: range.rangeEnd,
        )
        .map(
          (expandedTasks) =>
              NextOccurrenceSelector.nextUncompletedTaskOccurrenceByTaskId(
                expandedTasks: expandedTasks,
                asOfDay: asOfDayKey,
              ),
        )
        // Ensure base tasks can render immediately; previews will fill in on the
        // next emission after expansion debounce.
        .startWith(const <String, OccurrenceData>{});

    return Rx.combineLatest2(
      baseTasksStream,
      nextOccurrenceByTaskIdStream,
      (List<Task> tasks, Map<String, OccurrenceData> nextById) {
        return tasks
            .map((task) {
              if (!task.isRepeating || task.seriesEnded) return task;

              final next = nextById[task.id];
              if (next == null) return task;

              return task.copyWith(occurrence: next);
            })
            .toList(growable: false);
      },
    );
  }

  /// Watches task occurrences in the inclusive date window.
  ///
  /// This applies two-phase filtering:
  /// - Candidate set: SQL-level filtering with date predicates removed.
  /// - Post-expansion: full filter evaluated against occurrence-aware dates.
  Stream<List<Task>> watchTaskOccurrences({
    required TaskQuery query,
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
    DateTime? todayDayKeyUtc,
  }) {
    final rangeStart = dateOnly(rangeStartDay);
    final rangeEnd = dateOnly(rangeEndDay);

    final candidateQuery = query
        .copyWith(
          clearOccurrenceExpansion: true,
          clearOccurrencePreview: true,
        )
        .copyWith(filter: _removeTaskDatePredicates(query.filter));

    final ctx = EvaluationContext(
      today: todayDayKeyUtc ?? _dayKeyService.todayDayKeyUtc(),
    );

    bool postExpansionFilter(Task task) {
      return _taskFilterEvaluator.matches(task, query.filter, ctx);
    }

    return _occurrenceExpander.expandTaskOccurrences(
      tasksStream: _taskRepository.watchAll(candidateQuery),
      completionsStream: _taskRepository.watchCompletionHistory(),
      exceptionsStream: _taskRepository.watchRecurrenceExceptions(),
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      postExpansionFilter: postExpansionFilter,
    );
  }

  /// Watches project occurrences in the inclusive date window.
  Stream<List<Project>> watchProjectOccurrences({
    required ProjectQuery query,
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
    DateTime? todayDayKeyUtc,
  }) {
    final rangeStart = dateOnly(rangeStartDay);
    final rangeEnd = dateOnly(rangeEndDay);

    final candidateQuery = query
        .copyWith(
          clearOccurrenceExpansion: true,
          clearOccurrencePreview: true,
        )
        .copyWith(filter: _removeProjectDatePredicates(query.filter));

    final ctx = EvaluationContext(
      today: todayDayKeyUtc ?? _dayKeyService.todayDayKeyUtc(),
    );

    bool postExpansionFilter(Project project) {
      return _projectFilterEvaluator.matches(project, query.filter, ctx);
    }

    return _occurrenceExpander.expandProjectOccurrences(
      projectsStream: _projectRepository.watchAll(candidateQuery),
      completionsStream: _projectRepository.watchCompletionHistory(),
      exceptionsStream: _projectRepository.watchRecurrenceExceptions(),
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      postExpansionFilter: postExpansionFilter,
    );
  }

  QueryFilter<TaskPredicate> _removeTaskDatePredicates(
    QueryFilter<TaskPredicate> filter,
  ) {
    final shared = filter.shared
        .where((p) => p is! TaskDatePredicate)
        .toList(growable: false);

    final orGroups = filter.orGroups
        .map(
          (group) => group
              .where((p) => p is! TaskDatePredicate)
              .toList(growable: false),
        )
        .toList(growable: false);

    return QueryFilter<TaskPredicate>(shared: shared, orGroups: orGroups);
  }

  QueryFilter<ProjectPredicate> _removeProjectDatePredicates(
    QueryFilter<ProjectPredicate> filter,
  ) {
    final shared = filter.shared
        .where((p) => p is! ProjectDatePredicate)
        .toList(growable: false);

    final orGroups = filter.orGroups
        .map(
          (group) => group
              .where((p) => p is! ProjectDatePredicate)
              .toList(growable: false),
        )
        .toList(growable: false);

    return QueryFilter<ProjectPredicate>(shared: shared, orGroups: orGroups);
  }
}
