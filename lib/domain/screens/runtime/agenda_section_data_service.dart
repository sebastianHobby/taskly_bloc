import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:taskly_bloc/core/utils/date_only.dart';
import 'package:taskly_bloc/domain/interfaces/task_repository_contract.dart';
import 'package:taskly_bloc/domain/interfaces/project_repository_contract.dart';
import 'package:taskly_bloc/domain/screens/language/models/agenda_data.dart';
import 'package:taskly_bloc/domain/models/task.dart';
import 'package:taskly_bloc/domain/models/project.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

/// Service for fetching and transforming data for the AgendaSection renderer.
///
/// Supports the Scheduled view's timeline display with:
/// - Date-grouped items with semantic labels
/// - Date tags (Starts/In Progress/Due)
/// - Hybrid empty day handling (show near-term, skip distant empty days)
/// - Bidirectional date picker sync
/// - On-demand loading for infinite scroll
class AgendaSectionDataService {
  AgendaSectionDataService({
    required this.taskRepository,
    required this.projectRepository,
    this.nearTermDays = 7,
  });

  final TaskRepositoryContract taskRepository;
  final ProjectRepositoryContract projectRepository;

  /// Number of days from today to show empty day placeholders.
  final int nearTermDays;

  /// Current loaded range end (for on-demand loading).
  DateTime _loadedRangeEnd = DateTime.now().add(const Duration(days: 30));

  /// Watches agenda data reactively for a given range.
  ///
  /// This uses occurrence expansion streams for tasks/projects, so repeating
  /// entities update live when completions/exceptions change.
  Stream<AgendaData> watchAgendaData({
    required DateTime referenceDate,
    required DateTime focusDate,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    int? nearTermDaysOverride,
  }) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final effectiveNearTermDays = nearTermDaysOverride ?? nearTermDays;

    final overdueTasksStream = taskRepository.watchAll(TaskQuery.overdue());
    final overdueProjectsStream = projectRepository.watchAll(
      ProjectQuery(
        filter: QueryFilter<ProjectPredicate>(
          shared: [
            ProjectDatePredicate(
              field: ProjectDateField.deadlineDate,
              operator: DateOperator.before,
              date: dateOnly(today),
            ),
            const ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        ),
      ),
    );

    // Use the Schedule queries (completed=false AND (start OR deadline in
    // range) + occurrence expansion). This keeps streaming behavior consistent
    // with getAgendaData() and ensures deadline-only tasks appear.
    final scheduledTasksStream = taskRepository.watchAll(
      TaskQuery.schedule(rangeStart: rangeStart, rangeEnd: rangeEnd),
    );
    final scheduledProjectsStream = projectRepository.watchAll(
      ProjectQuery.schedule(rangeStart: rangeStart, rangeEnd: rangeEnd),
    );

    return Rx.combineLatest4<
          List<Task>,
          List<Project>,
          List<Task>,
          List<Project>,
          AgendaData
        >(
          overdueTasksStream,
          overdueProjectsStream,
          scheduledTasksStream,
          scheduledProjectsStream,
          (overdueTasks, overdueProjects, tasksWithDates, projectsWithDates) {
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

            for (final task in tasksWithDates) {
              _addTaskToDateMap(task, itemsByDate, today, rangeEnd);
            }

            for (final project in projectsWithDates) {
              _addProjectToDateMap(project, itemsByDate, today, rangeEnd);
            }

            final groups = _generateDateGroups(
              itemsByDate: itemsByDate,
              today: today,
              nearTermDays: effectiveNearTermDays,
              horizonEnd: rangeEnd,
            );

            return AgendaData(
              groups: groups,
              focusDate: focusDate,
              overdueItems: overdueItems,
              loadedHorizonEnd: rangeEnd,
            );
          },
        )
        .debounceTime(const Duration(milliseconds: 50));
  }

  /// Fetches agenda data for the Scheduled view.
  ///
  /// Returns grouped items with date tags and semantic labels.
  Future<AgendaData> getAgendaData({
    required DateTime referenceDate,
    required DateTime focusDate,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    int? nearTermDaysOverride,
  }) async {
    final effectiveNearTermDays = nearTermDaysOverride ?? nearTermDays;
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final horizonEnd = rangeEnd;

    // 1. Fetch overdue items
    final overdueTasks = await _getOverdueTasks(today);
    final overdueProjects = await _getOverdueProjects(today);

    // 2. Fetch items with dates within horizon
    final tasksWithDates = await _getTasksWithDates(rangeStart, horizonEnd);
    final projectsWithDates = await _getProjectsWithDates(
      rangeStart,
      horizonEnd,
    );

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
    final groups = _generateDateGroups(
      itemsByDate: itemsByDate,
      today: today,
      nearTermDays: effectiveNearTermDays,
      horizonEnd: horizonEnd,
    );

    return AgendaData(
      groups: groups,
      focusDate: focusDate,
      overdueItems: overdueItems,
      loadedHorizonEnd: horizonEnd,
    );
  }

  /// Loads initial data (today + 1 month).
  Future<AgendaData> loadInitial() {
    final today = DateTime.now();
    final rangeStart = DateTime(today.year, today.month, today.day);
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
    final now = DateTime.now();
    final rangeStart = DateTime(now.year, now.month, now.day);
    return getAgendaData(
      referenceDate: now,
      focusDate: now,
      rangeStart: rangeStart,
      rangeEnd: _loadedRangeEnd,
    );
  }

  /// Jumps to a specific date (from calendar modal).
  Future<AgendaData> jumpToDate(DateTime targetDate) {
    // Load 1 month after target date (1 week before is in near-term range)
    _loadedRangeEnd = targetDate.add(const Duration(days: 30));
    final rangeStart = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
    );
    return getAgendaData(
      referenceDate: DateTime.now(),
      focusDate: targetDate,
      rangeStart: rangeStart,
      rangeEnd: _loadedRangeEnd,
    );
  }

  // ===========================================================================
  // Private helpers
  // ===========================================================================

  Future<List<Task>> _getOverdueTasks(DateTime today) async {
    // Use built-in overdue query: deadline < today AND completed = false
    final query = TaskQuery.overdue();
    return taskRepository.getAll(query);
  }

  Future<List<Project>> _getOverdueProjects(DateTime today) async {
    // Query: deadline < today AND completed = false
    final startOfDay = dateOnly(today);
    final query = ProjectQuery(
      filter: QueryFilter<ProjectPredicate>(
        shared: [
          ProjectDatePredicate(
            field: ProjectDateField.deadlineDate,
            operator: DateOperator.before,
            date: startOfDay,
          ),
          const ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      ),
    );
    return projectRepository.getAll(query);
  }

  Future<List<Task>> _getTasksWithDates(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    // Use schedule query with occurrence expansion for repeating tasks
    final query = TaskQuery.schedule(
      rangeStart: fromDate,
      rangeEnd: toDate,
    );
    return taskRepository.getAll(query);
  }

  Future<List<Project>> _getProjectsWithDates(
    DateTime fromDate,
    DateTime toDate,
  ) async {
    // Use schedule query with occurrence expansion for repeating projects
    final query = ProjectQuery.schedule(
      rangeStart: fromDate,
      rangeEnd: toDate,
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

    // Add "In Progress" entries for days between start and deadline
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

    // Add "In Progress" entries for days between start and deadline
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
      return AgendaItem(
        entityType: 'task',
        entityId: task.id,
        name: task.name,
        tag: tag,
        task: task,
        isCondensed: isCondensed,
        isAfterCompletionRepeat: isAfterCompletionRepeat,
      );
    }

    return AgendaItem(
      entityType: 'project',
      entityId: project!.id,
      name: project.name,
      tag: tag,
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
