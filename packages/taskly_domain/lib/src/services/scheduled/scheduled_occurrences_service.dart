import 'package:rxdart/rxdart.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/time.dart';

import 'package:taskly_domain/src/services/occurrence/occurrence_policy.dart';
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
    final scheduledNonRecurringTasksQuery =
        _buildScheduledNonRecurringTasksQuery(
          rangeStart: startDay,
          rangeEnd: endDay,
          scope: effectiveScope,
        );
    final scheduledNonRecurringProjectsQuery =
        _buildScheduledNonRecurringProjectsQuery(
          rangeStart: startDay,
          rangeEnd: endDay,
          scope: effectiveScope,
        );
    final scheduledRecurringTasksQuery = _buildScheduledRecurringTasksQuery(
      scope: effectiveScope,
    );
    final scheduledRecurringProjectsQuery =
        _buildScheduledRecurringProjectsQuery(scope: effectiveScope);

    final overdueTasksStream = _taskRepository.watchAll(overdueTasksQuery);
    final overdueProjectsStream = _projectRepository.watchAll(
      overdueProjectsQuery,
    );
    final scheduledNonRecurringTasksStream = _taskRepository.watchAll(
      scheduledNonRecurringTasksQuery,
    );
    final scheduledNonRecurringProjectsStream = _projectRepository.watchAll(
      scheduledNonRecurringProjectsQuery,
    );
    final scheduledRecurringTasksStream = _occurrenceReadService
        .watchTaskOccurrences(
          query: scheduledRecurringTasksQuery,
          rangeStartDay: startDay,
          rangeEndDay: endDay,
          todayDayKeyUtc: today,
        );
    final scheduledRecurringProjectsStream = _occurrenceReadService
        .watchProjectOccurrences(
          query: scheduledRecurringProjectsQuery,
          rangeStartDay: startDay,
          rangeEndDay: endDay,
          todayDayKeyUtc: today,
        );

    return Rx.combineLatest6(
      overdueTasksStream,
      overdueProjectsStream,
      scheduledNonRecurringTasksStream,
      scheduledNonRecurringProjectsStream,
      scheduledRecurringTasksStream,
      scheduledRecurringProjectsStream,
      (
        overdueTasks,
        overdueProjects,
        scheduledNonRecurringTasks,
        scheduledNonRecurringProjects,
        scheduledRecurringTasks,
        scheduledRecurringProjects,
      ) {
        final recurringTasksForDisplay = _applyTaskRecurringDisplayPolicy(
          scheduledRecurringTasks,
          rangeStart: startDay,
          rangeEnd: endDay,
        );
        final recurringProjectsForDisplay = _applyProjectRecurringDisplayPolicy(
          scheduledRecurringProjects,
          rangeStart: startDay,
          rangeEnd: endDay,
        );

        final overdue = <ScheduledOccurrence>[
          ...overdueTasks.map((t) => _overdueTask(t, today: today)),
          ...overdueProjects.map((p) => _overdueProject(p, today: today)),
        ];

        final occurrences = <ScheduledOccurrence>[];

        for (final task in scheduledNonRecurringTasks) {
          occurrences.addAll(
            _expandTask(
              task,
              rangeStart: startDay,
              rangeEnd: endDay,
            ),
          );
        }

        for (final task in recurringTasksForDisplay) {
          occurrences.addAll(
            _expandTask(
              task,
              rangeStart: startDay,
              rangeEnd: endDay,
            ),
          );
        }

        for (final project in scheduledNonRecurringProjects) {
          occurrences.addAll(
            _expandProject(
              project,
              rangeStart: startDay,
              rangeEnd: endDay,
            ),
          );
        }

        for (final project in recurringProjectsForDisplay) {
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
      // Recurring row date-tags are built from the selected occurrence
      // instance:
      // - after-completion series are pre-collapsed to the next occurrence
      // - schedule-anchored series keep all in-window occurrences
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

  List<Task> _applyTaskRecurringDisplayPolicy(
    List<Task> recurringTasks, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final retained = <Task>[];
    final afterCompletionById = <String, List<Task>>{};

    for (final task in recurringTasks) {
      if (OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.scheduled,
        repeatFromCompletion: task.repeatFromCompletion,
      )) {
        afterCompletionById.putIfAbsent(task.id, () => <Task>[]).add(task);
      } else {
        retained.add(task);
      }
    }

    for (final candidates in afterCompletionById.values) {
      final next = _selectNextTaskOccurrence(
        candidates,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      if (next != null) {
        retained.add(next);
      }
    }

    return retained;
  }

  List<Project> _applyProjectRecurringDisplayPolicy(
    List<Project> recurringProjects, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final retained = <Project>[];
    final afterCompletionById = <String, List<Project>>{};

    for (final project in recurringProjects) {
      if (OccurrencePolicy.showsSingleNextOnly(
        surface: RecurrenceDisplaySurface.scheduled,
        repeatFromCompletion: project.repeatFromCompletion,
      )) {
        afterCompletionById
            .putIfAbsent(project.id, () => <Project>[])
            .add(
              project,
            );
      } else {
        retained.add(project);
      }
    }

    for (final candidates in afterCompletionById.values) {
      final next = _selectNextProjectOccurrence(
        candidates,
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      if (next != null) {
        retained.add(next);
      }
    }

    return retained;
  }

  Task? _selectNextTaskOccurrence(
    List<Task> candidates, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (candidates.isEmpty) return null;
    final sorted = candidates.toList(growable: false)
      ..sort((a, b) {
        final aKey = _taskOccurrenceSortKey(a);
        final bKey = _taskOccurrenceSortKey(b);
        if (aKey == null && bKey == null) return 0;
        if (aKey == null) return 1;
        if (bKey == null) return -1;
        return aKey.compareTo(bKey);
      });

    for (final task in sorted) {
      final key = _taskOccurrenceSortKey(task);
      if (key == null) continue;
      if (_isInRange(key, rangeStart, rangeEnd)) return task;
    }
    return sorted.first;
  }

  Project? _selectNextProjectOccurrence(
    List<Project> candidates, {
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    if (candidates.isEmpty) return null;
    final sorted = candidates.toList(growable: false)
      ..sort((a, b) {
        final aKey = _projectOccurrenceSortKey(a);
        final bKey = _projectOccurrenceSortKey(b);
        if (aKey == null && bKey == null) return 0;
        if (aKey == null) return 1;
        if (bKey == null) return -1;
        return aKey.compareTo(bKey);
      });

    for (final project in sorted) {
      final key = _projectOccurrenceSortKey(project);
      if (key == null) continue;
      if (_isInRange(key, rangeStart, rangeEnd)) return project;
    }
    return sorted.first;
  }

  DateTime? _taskOccurrenceSortKey(Task task) {
    final start = task.occurrence?.date ?? task.startDate;
    if (start != null) return dateOnly(start);
    final deadline = task.occurrence?.deadline ?? task.deadlineDate;
    return deadline == null ? null : dateOnly(deadline);
  }

  DateTime? _projectOccurrenceSortKey(Project project) {
    final start = project.occurrence?.date ?? project.startDate;
    if (start != null) return dateOnly(start);
    final deadline = project.occurrence?.deadline ?? project.deadlineDate;
    return deadline == null ? null : dateOnly(deadline);
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

  TaskQuery _buildScheduledNonRecurringTasksQuery({
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
          const TaskBoolPredicate(
            field: TaskBoolField.repeating,
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

  TaskQuery _buildScheduledRecurringTasksQuery({
    required ScheduledScope? scope,
  }) {
    return TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: <TaskPredicate>[
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          const TaskBoolPredicate(
            field: TaskBoolField.repeating,
            operator: BoolOperator.isTrue,
          ),
          ..._taskScopePredicates(scope),
        ],
      ),
    );
  }

  ProjectQuery _buildScheduledNonRecurringProjectsQuery({
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
          const ProjectBoolPredicate(
            field: ProjectBoolField.repeating,
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

  ProjectQuery _buildScheduledRecurringProjectsQuery({
    required ScheduledScope? scope,
  }) {
    return ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: <ProjectPredicate>[
          const ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          const ProjectBoolPredicate(
            field: ProjectBoolField.repeating,
            operator: BoolOperator.isTrue,
          ),
          ..._projectScopePredicates(scope),
        ],
      ),
    );
  }
}
