import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/time.dart';

import 'package:taskly_domain/src/services/occurrence/occurrence_read_service.dart';

import 'package:taskly_domain/src/models/scheduled/scheduled_date_tag.dart';
import 'package:taskly_domain/src/models/scheduled/scheduled_occurrence.dart';
import 'package:taskly_domain/src/models/scheduled/scheduled_occurrence_ref.dart';
import 'package:taskly_domain/src/models/scheduled/scheduled_scope.dart';
import 'package:taskly_domain/src/services/scheduled/scheduled_occurrences_result.dart';

/// Domain contract for the Scheduled range query (DEC-253A).
///
/// Produces occurrence-aware, date-tagged rows for a date window.
final class ScheduledOccurrencesService {
  ScheduledOccurrencesService({
    required TaskRepositoryContract taskRepository,
    required ProjectRepositoryContract projectRepository,
    required OccurrenceReadService occurrenceReadService,
  }) : _taskRepository = taskRepository,
       _projectRepository = projectRepository,
       _occurrenceReadService = occurrenceReadService;

  final OccurrenceReadService _occurrenceReadService;

  final TaskRepositoryContract _taskRepository;
  final ProjectRepositoryContract _projectRepository;

  /// Watch all scheduled occurrences in the inclusive day-key window.
  ///
  /// The date inputs are home-day keys (UTC midnight) and are treated as keys,
  /// not instants.
  Stream<ScheduledOccurrencesResult> watchScheduledOccurrences({
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
    required DateTime todayDayKeyUtc,
    ScheduledScope scope = const GlobalScheduledScope(),
  }) {
    final startDay = dateOnly(rangeStartDay);
    final endDay = dateOnly(rangeEndDay);
    final today = dateOnly(todayDayKeyUtc);

    final effectiveScope = switch (scope) {
      GlobalScheduledScope() => null,
      _ => scope,
    };

    final overdueTasksQuery = _buildOverdueTasksQuery(today, effectiveScope);
    final overdueProjectsQuery = _buildOverdueProjectsQuery(
      today,
      effectiveScope,
    );
    final scheduledTasksQuery = _buildScheduledTasksQuery(
      rangeStart: startDay,
      rangeEnd: endDay,
      scope: effectiveScope,
    );
    final scheduledProjectsQuery = _buildScheduledProjectsQuery(
      rangeStart: startDay,
      rangeEnd: endDay,
      scope: effectiveScope,
    );

    final overdueTasksStream = _taskRepository.watchAll(overdueTasksQuery);
    final overdueProjectsStream = _projectRepository.watchAll(
      overdueProjectsQuery,
    );
    final scheduledTasksStream = _occurrenceReadService.watchTaskOccurrences(
      query: scheduledTasksQuery,
      rangeStartDay: startDay,
      rangeEndDay: endDay,
      todayDayKeyUtc: today,
    );
    final scheduledProjectsStream = _occurrenceReadService
        .watchProjectOccurrences(
          query: scheduledProjectsQuery,
          rangeStartDay: startDay,
          rangeEndDay: endDay,
          todayDayKeyUtc: today,
        );

    return Rx.combineLatest4(
      overdueTasksStream,
      overdueProjectsStream,
      scheduledTasksStream,
      scheduledProjectsStream,
      (overdueTasks, overdueProjects, scheduledTasks, scheduledProjects) {
        final overdue = <ScheduledOccurrence>[
          ...overdueTasks.map((t) => _overdueTask(t, today: today)),
          ...overdueProjects.map((p) => _overdueProject(p, today: today)),
        ];

        final occurrences = <ScheduledOccurrence>[];

        for (final task in scheduledTasks) {
          occurrences.addAll(
            _expandTask(
              task,
              rangeStart: startDay,
              rangeEnd: endDay,
            ),
          );
        }

        for (final project in scheduledProjects) {
          occurrences.addAll(
            _expandProject(
              project,
              rangeStart: startDay,
              rangeEnd: endDay,
            ),
          );
        }

        return ScheduledOccurrencesResult(
          rangeStartDay: startDay,
          rangeEndDay: endDay,
          overdue: overdue,
          occurrences: occurrences,
        );
      },
    ).debounceTime(const Duration(milliseconds: 50));
  }

  ScheduledOccurrence _overdueTask(Task task, {required DateTime today}) {
    final name = task.name.trim().isEmpty ? 'Untitled task' : task.name;

    return ScheduledOccurrence.forTask(
      ref: ScheduledOccurrenceRef(
        entityType: EntityType.task,
        entityId: task.id,
        localDay: today,
        tag: ScheduledDateTag.due,
      ),
      name: name,
      task: task,
      isAfterCompletionRepeat: task.isRepeating && task.repeatFromCompletion,
    );
  }

  ScheduledOccurrence _overdueProject(
    Project project, {
    required DateTime today,
  }) {
    final name = project.name.trim().isEmpty
        ? 'Untitled project'
        : project.name;

    return ScheduledOccurrence.forProject(
      ref: ScheduledOccurrenceRef(
        entityType: EntityType.project,
        entityId: project.id,
        localDay: today,
        tag: ScheduledDateTag.due,
      ),
      name: name,
      project: project,
      isAfterCompletionRepeat:
          project.isRepeating && project.repeatFromCompletion,
    );
  }

  Iterable<ScheduledOccurrence> _expandTask(
    Task task, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) sync* {
    final name = task.name.trim().isEmpty ? 'Untitled task' : task.name;

    final occurrenceStart = task.occurrence?.date ?? task.startDate;
    final occurrenceDeadline = task.occurrence?.deadline ?? task.deadlineDate;

    final dates = _getDisplayDates(
      start: occurrenceStart,
      deadline: occurrenceDeadline,
      isRepeating: task.isRepeating,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    final isAfterCompletionRepeat =
        task.isRepeating && task.repeatFromCompletion;

    for (final entry in dates.entries) {
      yield ScheduledOccurrence.forTask(
        ref: ScheduledOccurrenceRef(
          entityType: EntityType.task,
          entityId: task.id,
          localDay: entry.key,
          tag: entry.value,
        ),
        name: name,
        task: task,
        isAfterCompletionRepeat: isAfterCompletionRepeat,
      );
    }
  }

  Iterable<ScheduledOccurrence> _expandProject(
    Project project, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) sync* {
    final name = project.name.trim().isEmpty
        ? 'Untitled project'
        : project.name;

    final occurrenceStart = project.occurrence?.date ?? project.startDate;
    final occurrenceDeadline =
        project.occurrence?.deadline ?? project.deadlineDate;

    final dates = _getDisplayDates(
      start: occurrenceStart,
      deadline: occurrenceDeadline,
      isRepeating: project.isRepeating,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    final isAfterCompletionRepeat =
        project.isRepeating && project.repeatFromCompletion;

    for (final entry in dates.entries) {
      yield ScheduledOccurrence.forProject(
        ref: ScheduledOccurrenceRef(
          entityType: EntityType.project,
          entityId: project.id,
          localDay: entry.key,
          tag: entry.value,
        ),
        name: name,
        project: project,
        isAfterCompletionRepeat: isAfterCompletionRepeat,
      );
    }
  }

  Map<DateTime, ScheduledDateTag> _getDisplayDates({
    required DateTime? start,
    required DateTime? deadline,
    required bool isRepeating,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final dates = <DateTime, ScheduledDateTag>{};

    final startDay = start == null ? null : dateOnly(start);
    final deadlineDay = deadline == null ? null : dateOnly(deadline);

    final hasSameStartAndDeadline =
        startDay != null && deadlineDay != null && startDay == deadlineDay;

    if (isRepeating) {
      // Keep parity with the existing Scheduled feed:
      // - after-completion: show only the next start/deadline
      // - fixed interval: each expanded occurrence is its own entity instance
      if (startDay != null && _isInRange(startDay, rangeStart, rangeEnd)) {
        dates[startDay] = ScheduledDateTag.starts;
      }
      if (deadlineDay != null &&
          _isInRange(deadlineDay, rangeStart, rangeEnd)) {
        dates[deadlineDay] = ScheduledDateTag.due;
      }

      return dates;
    }

    if (deadlineDay != null && _isInRange(deadlineDay, rangeStart, rangeEnd)) {
      dates[deadlineDay] = ScheduledDateTag.due;
    }

    if (!hasSameStartAndDeadline &&
        startDay != null &&
        _isInRange(startDay, rangeStart, rangeEnd)) {
      dates.putIfAbsent(startDay, () => ScheduledDateTag.starts);
    }

    if (!hasSameStartAndDeadline && startDay != null && deadlineDay != null) {
      // Intentionally do not add intermediate “ongoing” days.
      // Scheduled should show only explicit start and due days.
    }

    return dates;
  }

  bool _isInRange(DateTime day, DateTime start, DateTime end) {
    final d = dateOnly(day);
    return !d.isBefore(dateOnly(start)) && !d.isAfter(dateOnly(end));
  }

  List<TaskPredicate> _taskScopePredicates(ScheduledScope? scope) {
    return switch (scope) {
      null => const <TaskPredicate>[],
      ProjectScheduledScope(:final projectId) => <TaskPredicate>[
        TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: projectId,
        ),
      ],
      ValueScheduledScope(:final valueId) => <TaskPredicate>[
        TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: <String>[valueId],
          includeInherited: false,
        ),
      ],
      GlobalScheduledScope() => const <TaskPredicate>[],
    };
  }

  List<ProjectPredicate> _projectScopePredicates(ScheduledScope? scope) {
    return switch (scope) {
      null => const <ProjectPredicate>[],
      ProjectScheduledScope(:final projectId) => <ProjectPredicate>[
        ProjectIdPredicate(id: projectId),
      ],
      ValueScheduledScope(:final valueId) => <ProjectPredicate>[
        ProjectValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: <String>[valueId],
        ),
      ],
      GlobalScheduledScope() => const <ProjectPredicate>[],
    };
  }

  TaskQuery _buildOverdueTasksQuery(DateTime today, ScheduledScope? scope) {
    return TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: <TaskPredicate>[
          TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.before,
            date: today,
          ),
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          ..._taskScopePredicates(scope),
        ],
      ),
    );
  }

  ProjectQuery _buildOverdueProjectsQuery(
    DateTime today,
    ScheduledScope? scope,
  ) {
    return ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: <ProjectPredicate>[
          ProjectDatePredicate(
            field: ProjectDateField.deadlineDate,
            operator: DateOperator.before,
            date: today,
          ),
          const ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          ..._projectScopePredicates(scope),
        ],
      ),
    );
  }

  TaskQuery _buildScheduledTasksQuery({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ScheduledScope? scope,
  }) {
    return TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: <TaskPredicate>[
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          ..._taskScopePredicates(scope),
        ],
        orGroups: <List<TaskPredicate>>[
          <TaskPredicate>[
            TaskDatePredicate(
              field: TaskDateField.startDate,
              operator: DateOperator.between,
              startDate: rangeStart,
              endDate: rangeEnd,
            ),
          ],
          <TaskPredicate>[
            TaskDatePredicate(
              field: TaskDateField.deadlineDate,
              operator: DateOperator.between,
              startDate: rangeStart,
              endDate: rangeEnd,
            ),
          ],
        ],
      ),
    );
  }

  ProjectQuery _buildScheduledProjectsQuery({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required ScheduledScope? scope,
  }) {
    return ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: <ProjectPredicate>[
          const ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          ..._projectScopePredicates(scope),
        ],
        orGroups: <List<ProjectPredicate>>[
          <ProjectPredicate>[
            ProjectDatePredicate(
              field: ProjectDateField.startDate,
              operator: DateOperator.between,
              startDate: rangeStart,
              endDate: rangeEnd,
            ),
          ],
          <ProjectPredicate>[
            ProjectDatePredicate(
              field: ProjectDateField.deadlineDate,
              operator: DateOperator.between,
              startDate: rangeStart,
              endDate: rangeEnd,
            ),
          ],
        ],
      ),
    );
  }
}
