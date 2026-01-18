import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/logging/talker_service.dart';
import 'package:taskly_bloc/domain/screens/runtime/agenda_scope.dart';
import 'package:taskly_domain/analytics.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';

/// Service for fetching and transforming data for the AgendaSection renderer.
///
/// Supports the Scheduled agenda (day cards feed) with:
/// - Date-grouped items with semantic labels
/// - Date tags (Starts/Ongoing/Due)
/// - Hybrid empty day handling (show near-term, skip distant empty days)
/// - On-demand loading for the loaded horizon
class AgendaSectionDataService {
  AgendaSectionDataService({
    required this.taskRepository,
    required this.projectRepository,
    required HomeDayKeyService dayKeyService,
    Clock clock = systemClock,
    this.nearTermDays = 7,
  }) : _dayKeyService = dayKeyService,
       _clock = clock,
       _loadedRangeEnd = dayKeyService
           .todayDayKeyUtc(nowUtc: clock.nowUtc())
           .add(const Duration(days: 30));

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;
  final HomeDayKeyService _dayKeyService;
  final Clock _clock;

  /// Number of days from today to show empty day placeholders.
  final int nearTermDays;

  /// Current loaded range end (for on-demand loading).
  DateTime _loadedRangeEnd;

  /// Watches agenda data reactively for a given range.
  ///
  /// This uses occurrence expansion streams for tasks/projects, so repeating
  /// entities update live when completions/exceptions change.
  Stream<AgendaData> watchAgendaData({
    required DateTime referenceDate,
    required DateTime focusDate,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    AgendaScope? scope,
    int? nearTermDaysOverride,
  }) {
    final watchStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
    final rangeDays = rangeEnd.difference(rangeStart).inDays;
    final logMsg =
        '🚀 Scheduled: Starting watchAgendaData (range: $rangeDays days)';
    if (kDebugMode) {
      developer.log(logMsg, name: 'perf.scheduled');
      talker.perf(logMsg, category: 'scheduled');

      developer.log(
        '🔍 Scheduled: Subscribing to repository streams...',
        name: 'perf.scheduled.query',
      );
    }

    final today = dateOnly(referenceDate);
    final effectiveNearTermDays = nearTermDaysOverride ?? nearTermDays;

    final overdueTasksQuery = _buildOverdueTasksQuery(today, scope);
    final overdueProjectsQuery = _buildOverdueProjectsQuery(today, scope);
    final scheduledTasksQuery = _buildScheduledTasksQuery(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      scope: scope,
    );
    final scheduledProjectsQuery = _buildScheduledProjectsQuery(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      scope: scope,
    );

    final overdueTasksStream = taskRepository.watchAll(overdueTasksQuery).map(
      (tasks) {
        if (kDebugMode) {
          developer.log(
            '📊 Scheduled: Overdue tasks fetched: ${tasks.length}',
            name: 'perf.scheduled.query',
          );
        }
        return tasks;
      },
    );
    final overdueProjectsStream = projectRepository
        .watchAll(overdueProjectsQuery)
        .map((projects) {
          if (kDebugMode) {
            developer.log(
              '📊 Scheduled: Overdue projects fetched: ${projects.length}',
              name: 'perf.scheduled.query',
            );
          }
          return projects;
        });

    // Use the Schedule queries (completed=false AND (start OR deadline in
    // range) + occurrence expansion). This keeps streaming behavior consistent
    // with getAgendaData() and ensures deadline-only tasks appear.
    final scheduledTasksStream = taskRepository
        .watchAll(
          scheduledTasksQuery,
        )
        .map((tasks) {
          final repeatingCount = tasks.where((t) => t.isRepeating).length;
          if (kDebugMode) {
            developer.log(
              '📊 Scheduled: Scheduled tasks fetched: ${tasks.length} (repeating: $repeatingCount)',
              name: 'perf.scheduled.query',
            );
          }
          return tasks;
        });
    final scheduledProjectsStream = projectRepository
        .watchAll(
          scheduledProjectsQuery,
        )
        .map((projects) {
          final repeatingCount = projects.where((p) => p.isRepeating).length;
          if (kDebugMode) {
            developer.log(
              '📊 Scheduled: Scheduled projects fetched: ${projects.length} (repeating: $repeatingCount)',
              name: 'perf.scheduled.query',
            );
          }
          return projects;
        });

    return Rx.combineLatest4<List<Task>, List<Project>, List<Task>, List<Project>, AgendaData>(
      overdueTasksStream,
      overdueProjectsStream,
      scheduledTasksStream,
      scheduledProjectsStream,
      (overdueTasks, overdueProjects, tasksWithDates, projectsWithDates) {
        final processingStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
        if (kDebugMode) {
          developer.log(
            '⚙️ Scheduled: Processing data - '
            'OD Tasks: ${overdueTasks.length}, OD Projects: ${overdueProjects.length}, '
            'Scheduled Tasks: ${tasksWithDates.length}, Scheduled Projects: ${projectsWithDates.length}',
            name: 'perf.scheduled.processing',
          );
        }

        // 1. Build overdue items list
        final overdueItems = [
          ...overdueTasks.map(
            (t) => _createAgendaItem(
              task: t,
              displayDate: today,
              tag: AgendaDateTag.due,
            ),
          ),
          ...overdueProjects.map(
            (p) => _createAgendaItem(
              project: p,
              displayDate: today,
              tag: AgendaDateTag.due,
            ),
          ),
        ];

        // 2. Expand items into per-day entries and group by date
        final itemsByDate = <DateTime, List<AgendaItem>>{};

        final expansionStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
        for (final task in tasksWithDates) {
          _addTaskToDateMap(task, itemsByDate, today, rangeEnd);
        }

        for (final project in projectsWithDates) {
          _addProjectToDateMap(project, itemsByDate, today, rangeEnd);
        }
        final expansionMs = kDebugMode
            ? expansionStopwatch?.elapsedMilliseconds
            : null;

        final totalAgendaItems = itemsByDate.values.fold<int>(
          0,
          (sum, items) => sum + items.length,
        );

        final groupingStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
        final groups = _generateDateGroups(
          itemsByDate: itemsByDate,
          today: today,
          nearTermDays: effectiveNearTermDays,
          horizonEnd: rangeEnd,
        );
        final groupingMs = kDebugMode
            ? groupingStopwatch?.elapsedMilliseconds
            : null;

        if (kDebugMode &&
            watchStopwatch != null &&
            processingStopwatch != null &&
            expansionMs != null &&
            groupingMs != null) {
          final processingMs = processingStopwatch.elapsedMilliseconds;
          final totalMs = watchStopwatch.elapsedMilliseconds;

          final completionMsg =
              '✅ Scheduled: Complete - '
              'Total: ${totalMs}ms (processing: ${processingMs}ms, expansion: ${expansionMs}ms, grouping: ${groupingMs}ms) | '
              'Groups: ${groups.length}, Total Items: $totalAgendaItems, Overdue: ${overdueItems.length}';
          developer.log(
            completionMsg,
            name: 'perf.scheduled',
            level: totalMs > 500 ? 900 : 800,
          );

          if (totalMs > 500) {
            talker.perf(
              'Scheduled screen slow: ${totalMs}ms',
              category: 'scheduled',
            );
          } else if (totalMs > 300) {
            talker.perf(completionMsg, category: 'scheduled');
          }
        }

        return AgendaData(
          groups: groups,
          focusDate: focusDate,
          overdueItems: overdueItems,
          loadedHorizonEnd: rangeEnd,
        );
      },
    ).debounceTime(const Duration(milliseconds: 50));
  }

  /// Fetches agenda data for the Scheduled view.
  ///
  /// Returns grouped items with date tags and semantic labels.
  Future<AgendaData> getAgendaData({
    required DateTime referenceDate,
    required DateTime focusDate,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    AgendaScope? scope,
    int? nearTermDaysOverride,
  }) async {
    final fetchStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
    final rangeDays = rangeEnd.difference(rangeStart).inDays;
    if (kDebugMode) {
      developer.log(
        '🚀 Scheduled: Starting getAgendaData (range: $rangeDays days)',
        name: 'perf.scheduled.fetch',
      );
      talker.perf(
        'Scheduled: start getAgendaData (rangeDays=$rangeDays)',
        category: 'scheduled',
      );
    }

    final effectiveNearTermDays = nearTermDaysOverride ?? nearTermDays;
    final today = dateOnly(referenceDate);
    final horizonEnd = rangeEnd;

    // 1. Fetch overdue items
    final overdueStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
    final overdueTasks = await _getOverdueTasks(today, scope: scope);
    final overdueProjects = await _getOverdueProjects(today, scope: scope);
    final overdueMs = kDebugMode ? overdueStopwatch?.elapsedMilliseconds : null;

    // 2. Fetch items with dates within horizon
    final scheduledStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
    final tasksWithDates = await _getTasksWithDates(
      rangeStart,
      horizonEnd,
      scope: scope,
    );
    final projectsWithDates = await _getProjectsWithDates(
      rangeStart,
      horizonEnd,
      scope: scope,
    );
    final scheduledMs = kDebugMode
        ? scheduledStopwatch?.elapsedMilliseconds
        : null;

    if (kDebugMode && overdueMs != null && scheduledMs != null) {
      developer.log(
        '📊 Scheduled: Queries complete - '
        'Overdue: ${overdueMs}ms (T:${overdueTasks.length} P:${overdueProjects.length}), '
        'Scheduled: ${scheduledMs}ms (T:${tasksWithDates.length} P:${projectsWithDates.length})',
        name: 'perf.scheduled.fetch',
      );
      talker.perf(
        'Scheduled: queries complete (overdue=${overdueMs}ms, scheduled=${scheduledMs}ms)',
        category: 'scheduled',
      );
    }

    // 3. Build overdue items list
    final overdueItems = [
      ...overdueTasks.map(
        (t) => _createAgendaItem(
          task: t,
          displayDate: today,
          tag: AgendaDateTag.due,
        ),
      ),
      ...overdueProjects.map(
        (p) => _createAgendaItem(
          project: p,
          displayDate: today,
          tag: AgendaDateTag.due,
        ),
      ),
    ];

    // 4. Expand repeating items and group by date
    final itemsByDate = <DateTime, List<AgendaItem>>{};

    for (final task in tasksWithDates) {
      _addTaskToDateMap(task, itemsByDate, today, horizonEnd);
    }

    for (final project in projectsWithDates) {
      _addProjectToDateMap(project, itemsByDate, today, horizonEnd);
    }

    // 5. Generate date groups with empty day handling
    final groupingStopwatch = kDebugMode ? (Stopwatch()..start()) : null;
    final groups = _generateDateGroups(
      itemsByDate: itemsByDate,
      today: today,
      nearTermDays: effectiveNearTermDays,
      horizonEnd: horizonEnd,
    );
    final groupingMs = kDebugMode
        ? groupingStopwatch?.elapsedMilliseconds
        : null;

    final totalAgendaItems = itemsByDate.values.fold<int>(
      0,
      (sum, items) => sum + items.length,
    );
    final totalMs = kDebugMode ? fetchStopwatch?.elapsedMilliseconds : null;

    if (kDebugMode && totalMs != null && groupingMs != null) {
      final fetchCompleteMsg =
          '✅ Scheduled: Fetch complete - '
          'Total: ${totalMs}ms (grouping: ${groupingMs}ms) | '
          'Groups: ${groups.length}, Total Items: $totalAgendaItems, Overdue: ${overdueItems.length}';
      developer.log(
        fetchCompleteMsg,
        name: 'perf.scheduled.fetch',
        level: totalMs > 500 ? 900 : 800,
      );

      if (totalMs > 500) {
        talker.perf(
          'Scheduled fetch slow: ${totalMs}ms',
          category: 'scheduled',
        );
      } else if (totalMs > 300) {
        talker.perf(fetchCompleteMsg, category: 'scheduled');
      }
    }

    return AgendaData(
      groups: groups,
      focusDate: focusDate,
      overdueItems: overdueItems,
      loadedHorizonEnd: horizonEnd,
    );
  }

  /// Loads initial data (today + 1 month).
  Future<AgendaData> loadInitial() {
    final today = _dayKeyService.todayDayKeyUtc(nowUtc: _clock.nowUtc());
    final rangeStart = today;
    _loadedRangeEnd = today.add(const Duration(days: 30));
    return getAgendaData(
      referenceDate: today,
      focusDate: today,
      rangeStart: rangeStart,
      rangeEnd: _loadedRangeEnd,
    );
  }

  /// Loads more data when user scrolls past current horizon.
  Future<AgendaData> loadMore(DateTime newHorizonEnd) {
    _loadedRangeEnd = newHorizonEnd;
    final today = _dayKeyService.todayDayKeyUtc(nowUtc: _clock.nowUtc());
    final rangeStart = today;
    return getAgendaData(
      referenceDate: today,
      focusDate: today,
      rangeStart: rangeStart,
      rangeEnd: _loadedRangeEnd,
    );
  }

  /// Jumps to a specific date (from calendar modal).
  Future<AgendaData> jumpToDate(DateTime targetDate) {
    final targetDay = dateOnly(targetDate);

    // Load 1 month after target date (1 week before is in near-term range)
    _loadedRangeEnd = targetDay.add(const Duration(days: 30));
    final rangeStart = targetDay;
    return getAgendaData(
      referenceDate: _dayKeyService.todayDayKeyUtc(nowUtc: _clock.nowUtc()),
      focusDate: targetDay,
      rangeStart: rangeStart,
      rangeEnd: _loadedRangeEnd,
    );
  }

  // ===========================================================================
  // Private helpers
  // ===========================================================================

  List<TaskPredicate> _taskScopePredicates(AgendaScope? scope) {
    return switch (scope) {
      null => const <TaskPredicate>[],
      ProjectAgendaScope(:final projectId) => <TaskPredicate>[
        TaskProjectPredicate(
          operator: ProjectOperator.matches,
          projectId: projectId,
        ),
      ],
      ValueAgendaScope(:final valueId) => <TaskPredicate>[
        TaskValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: <String>[valueId],
          includeInherited: false,
        ),
      ],
    };
  }

  List<ProjectPredicate> _projectScopePredicates(AgendaScope? scope) {
    return switch (scope) {
      null => const <ProjectPredicate>[],
      ProjectAgendaScope(:final projectId) => <ProjectPredicate>[
        ProjectIdPredicate(id: projectId),
      ],
      ValueAgendaScope(:final valueId) => <ProjectPredicate>[
        ProjectValuePredicate(
          operator: ValueOperator.hasAll,
          valueIds: <String>[valueId],
        ),
      ],
    };
  }

  TaskQuery _buildOverdueTasksQuery(DateTime today, AgendaScope? scope) {
    final startOfDay = dateOnly(today);
    return TaskQuery(
      filter: QueryFilter<TaskPredicate>(
        shared: <TaskPredicate>[
          TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.before,
            date: startOfDay,
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

  ProjectQuery _buildOverdueProjectsQuery(DateTime today, AgendaScope? scope) {
    final startOfDay = dateOnly(today);
    return ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: <ProjectPredicate>[
          ProjectDatePredicate(
            field: ProjectDateField.deadlineDate,
            operator: DateOperator.before,
            date: startOfDay,
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
    required AgendaScope? scope,
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
      occurrenceExpansion: OccurrenceExpansion(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }

  ProjectQuery _buildScheduledProjectsQuery({
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required AgendaScope? scope,
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
      occurrenceExpansion: OccurrenceExpansion(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      ),
    );
  }

  Future<List<Task>> _getOverdueTasks(
    DateTime today, {
    required AgendaScope? scope,
  }) async {
    final query = _buildOverdueTasksQuery(today, scope);
    return taskRepository.getAll(query);
  }

  Future<List<Project>> _getOverdueProjects(
    DateTime today, {
    required AgendaScope? scope,
  }) async {
    final query = _buildOverdueProjectsQuery(today, scope);
    return projectRepository.getAll(query);
  }

  Future<List<Task>> _getTasksWithDates(
    DateTime fromDate,
    DateTime toDate, {
    required AgendaScope? scope,
  }) async {
    final query = _buildScheduledTasksQuery(
      rangeStart: fromDate,
      rangeEnd: toDate,
      scope: scope,
    );
    return taskRepository.getAll(query);
  }

  Future<List<Project>> _getProjectsWithDates(
    DateTime fromDate,
    DateTime toDate, {
    required AgendaScope? scope,
  }) async {
    final query = _buildScheduledProjectsQuery(
      rangeStart: fromDate,
      rangeEnd: toDate,
      scope: scope,
    );
    return projectRepository.getAll(query);
  }

  void _addTaskToDateMap(
    Task task,
    Map<DateTime, List<AgendaItem>> itemsByDate,
    DateTime today,
    DateTime horizonEnd,
  ) {
    final dates = _getTaskDisplayDates(task, today, horizonEnd);

    if (kDebugMode && dates.length > 10) {
      final expansionMsg =
          '⚠️ Scheduled: Task "${task.name}" expanding to ${dates.length} dates';
      developer.log(
        expansionMsg,
        name: 'perf.scheduled.expansion',
        level: 900,
      );
      talker.perf(expansionMsg, category: 'scheduled');
    }

    for (final entry in dates.entries) {
      final date = entry.key;
      final tag = entry.value;

      itemsByDate.putIfAbsent(date, () => []);
      itemsByDate[date]!.add(
        _createAgendaItem(
          task: task,
          displayDate: date,
          tag: tag,
        ),
      );
    }
  }

  void _addProjectToDateMap(
    Project project,
    Map<DateTime, List<AgendaItem>> itemsByDate,
    DateTime today,
    DateTime horizonEnd,
  ) {
    final dates = _getProjectDisplayDates(project, today, horizonEnd);

    for (final entry in dates.entries) {
      final date = entry.key;
      final tag = entry.value;

      itemsByDate.putIfAbsent(date, () => []);
      itemsByDate[date]!.add(
        _createAgendaItem(
          project: project,
          displayDate: date,
          tag: tag,
        ),
      );
    }
  }

  /// Returns dates where this task should appear with appropriate tags.
  Map<DateTime, AgendaDateTag> _getTaskDisplayDates(
    Task task,
    DateTime today,
    DateTime horizonEnd,
  ) {
    final dates = <DateTime, AgendaDateTag>{};
    final start = task.startDate;
    final deadline = task.deadlineDate;

    final hasSameStartAndDeadline =
        start != null &&
        deadline != null &&
        _normalizeDate(start) == _normalizeDate(deadline);

    // Handle repeating items
    if (task.isRepeating) {
      if (task.repeatFromCompletion) {
        // After-completion: show only next occurrence
        if (start != null && _isInRange(start, today, horizonEnd)) {
          dates[_normalizeDate(start)] = AgendaDateTag.starts;
        }
        if (deadline != null && _isInRange(deadline, today, horizonEnd)) {
          dates[_normalizeDate(deadline)] = AgendaDateTag.due;
        }
      } else {
        // Fixed interval: occurrences already expanded by TaskQuery.schedule()
        // Each occurrence is received as a separate Task with its own dates
        if (start != null && _isInRange(start, today, horizonEnd)) {
          dates[_normalizeDate(start)] = AgendaDateTag.starts;
        }
        if (deadline != null && _isInRange(deadline, today, horizonEnd)) {
          dates[_normalizeDate(deadline)] = AgendaDateTag.due;
        }
      }
      return dates;
    }

    // Non-repeating item
    if (deadline != null && _isInRange(deadline, today, horizonEnd)) {
      dates[_normalizeDate(deadline)] = AgendaDateTag.due;
    }

    // Only add a separate start tag when it differs from deadline.
    if (!hasSameStartAndDeadline &&
        start != null &&
        _isInRange(start, today, horizonEnd)) {
      // Avoid overwriting a due tag on the same day.
      dates.putIfAbsent(_normalizeDate(start), () => AgendaDateTag.starts);
    }

    // Add "Ongoing" entries for days between start and deadline
    if (!hasSameStartAndDeadline && start != null && deadline != null) {
      var current = start.add(const Duration(days: 1));
      while (current.isBefore(deadline)) {
        if (_isInRange(current, today, horizonEnd)) {
          dates[_normalizeDate(current)] = AgendaDateTag.inProgress;
        }
        current = current.add(const Duration(days: 1));
      }
    }

    return dates;
  }

  /// Returns dates where this project should appear with appropriate tags.
  Map<DateTime, AgendaDateTag> _getProjectDisplayDates(
    Project project,
    DateTime today,
    DateTime horizonEnd,
  ) {
    final dates = <DateTime, AgendaDateTag>{};
    final start = project.startDate;
    final deadline = project.deadlineDate;

    final hasSameStartAndDeadline =
        start != null &&
        deadline != null &&
        _normalizeDate(start) == _normalizeDate(deadline);

    // Handle repeating items
    if (project.isRepeating) {
      if (project.repeatFromCompletion) {
        // After-completion: show only next occurrence
        if (start != null && _isInRange(start, today, horizonEnd)) {
          dates[_normalizeDate(start)] = AgendaDateTag.starts;
        }
        if (deadline != null && _isInRange(deadline, today, horizonEnd)) {
          dates[_normalizeDate(deadline)] = AgendaDateTag.due;
        }
      } else {
        // Fixed interval: occurrences already expanded by ProjectQuery.schedule()
        // Each occurrence is received as a separate Project with its own dates
        if (start != null && _isInRange(start, today, horizonEnd)) {
          dates[_normalizeDate(start)] = AgendaDateTag.starts;
        }
        if (deadline != null && _isInRange(deadline, today, horizonEnd)) {
          dates[_normalizeDate(deadline)] = AgendaDateTag.due;
        }
      }
      return dates;
    }

    // Non-repeating item
    if (deadline != null && _isInRange(deadline, today, horizonEnd)) {
      dates[_normalizeDate(deadline)] = AgendaDateTag.due;
    }

    // Only add a separate start tag when it differs from deadline.
    if (!hasSameStartAndDeadline &&
        start != null &&
        _isInRange(start, today, horizonEnd)) {
      dates.putIfAbsent(_normalizeDate(start), () => AgendaDateTag.starts);
    }

    // Add "Ongoing" entries for days between start and deadline
    if (!hasSameStartAndDeadline && start != null && deadline != null) {
      var current = start.add(const Duration(days: 1));
      while (current.isBefore(deadline)) {
        if (_isInRange(current, today, horizonEnd)) {
          dates[_normalizeDate(current)] = AgendaDateTag.inProgress;
        }
        current = current.add(const Duration(days: 1));
      }
    }

    return dates;
  }

  AgendaItem _createAgendaItem({
    required DateTime displayDate,
    required AgendaDateTag tag,
    Task? task,
    Project? project,
  }) {
    assert(
      task != null || project != null,
      'Either task or project must be provided',
    );

    final isCondensed = tag == AgendaDateTag.inProgress;
    final isAfterCompletionRepeat =
        ((task?.isRepeating ?? false) &&
            (task?.repeatFromCompletion ?? false)) ||
        ((project?.isRepeating ?? false) &&
            (project?.repeatFromCompletion ?? false));

    if (task != null) {
      final safeName = task.name.trim().isEmpty ? 'Untitled task' : task.name;
      return AgendaItem(
        entityType: EntityType.task,
        entityId: task.id,
        name: safeName,
        tag: tag,
        tileCapabilities: EntityTileCapabilitiesResolver.forTask(task),
        task: task,
        isCondensed: isCondensed,
        isAfterCompletionRepeat: isAfterCompletionRepeat,
      );
    }

    final safeName = project!.name.trim().isEmpty
        ? 'Untitled project'
        : project.name;

    return AgendaItem(
      entityType: EntityType.project,
      entityId: project.id,
      name: safeName,
      tag: tag,
      tileCapabilities: EntityTileCapabilitiesResolver.forProject(project),
      project: project,
      isCondensed: isCondensed,
      isAfterCompletionRepeat: isAfterCompletionRepeat,
    );
  }

  List<AgendaDateGroup> _generateDateGroups({
    required Map<DateTime, List<AgendaItem>> itemsByDate,
    required DateTime today,
    required int nearTermDays,
    required DateTime horizonEnd,
  }) {
    final groups = <AgendaDateGroup>[];

    // Near-term: Generate all dates including empty ones
    for (var i = 0; i <= nearTermDays; i++) {
      final date = today.add(Duration(days: i));
      final items = itemsByDate[_normalizeDate(date)] ?? [];
      groups.add(
        AgendaDateGroup(
          date: date,
          semanticLabel: _getSemanticLabel(date, today),
          formattedHeader: _formatHeader(date),
          items: items,
          isEmpty: items.isEmpty,
        ),
      );
    }

    // Beyond near-term: Only dates with items
    final futureDates =
        itemsByDate.keys
            .where((d) => d.isAfter(today.add(Duration(days: nearTermDays))))
            .toList()
          ..sort();

    for (final date in futureDates) {
      groups.add(
        AgendaDateGroup(
          date: date,
          semanticLabel: _getSemanticLabel(date, today),
          formattedHeader: _formatHeader(date),
          items: itemsByDate[date]!,
          isEmpty: false,
        ),
      );
    }

    return groups;
  }

  String _getSemanticLabel(DateTime date, DateTime today) {
    final diff = _normalizeDate(date).difference(_normalizeDate(today)).inDays;

    if (diff < 0) return 'Overdue';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';

    // Calculate days until end of this week (Saturday)
    final daysUntilEndOfWeek = 6 - today.weekday; // Saturday = 6
    if (diff <= daysUntilEndOfWeek && daysUntilEndOfWeek >= 0) {
      return 'This Week';
    }

    // Calculate days until end of next week
    final daysUntilEndOfNextWeek = daysUntilEndOfWeek + 7;
    if (diff <= daysUntilEndOfNextWeek) return 'Next Week';

    return 'Later';
  }

  String _formatHeader(DateTime date) {
    // Format: "Mon, Jan 15"
    return DateFormat('E, MMM d').format(date);
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isInRange(DateTime date, DateTime start, DateTime end) {
    final normalized = _normalizeDate(date);
    return !normalized.isBefore(_normalizeDate(start)) &&
        !normalized.isAfter(_normalizeDate(end));
  }
}
