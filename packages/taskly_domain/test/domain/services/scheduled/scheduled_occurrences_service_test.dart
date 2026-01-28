@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/time.dart';

class _StreamTaskRepo extends Fake implements TaskRepositoryContract {
  _StreamTaskRepo(this._overdueController, this._scheduledController);

  final StreamController<List<Task>> _overdueController;
  final StreamController<List<Task>> _scheduledController;

  TaskQuery? lastOverdueQuery;
  TaskQuery? lastScheduledQuery;

  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) {
    if (_isScheduledNonRecurringTaskQuery(query)) {
      lastScheduledQuery = query;
      return _scheduledController.stream;
    }
    lastOverdueQuery = query;
    return _overdueController.stream;
  }

  @override
  Future<Map<String, TaskSnoozeStats>> getSnoozeStats({
    required DateTime sinceUtc,
    required DateTime untilUtc,
  }) async {
    return const <String, TaskSnoozeStats>{};
  }
}

class _StreamProjectRepo extends Fake implements ProjectRepositoryContract {
  _StreamProjectRepo(this._overdueController, this._scheduledController);

  final StreamController<List<Project>> _overdueController;
  final StreamController<List<Project>> _scheduledController;

  ProjectQuery? lastOverdueQuery;
  ProjectQuery? lastScheduledQuery;

  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) {
    if (_isScheduledNonRecurringProjectQuery(query)) {
      lastScheduledQuery = query;
      return _scheduledController.stream;
    }
    lastOverdueQuery = query;
    return _overdueController.stream;
  }
}

class _CapturingOccurrenceService extends Fake
    implements OccurrenceReadService {
  _CapturingOccurrenceService(
    this._tasksController,
    this._projectsController,
  );

  final StreamController<List<Task>> _tasksController;
  final StreamController<List<Project>> _projectsController;

  TaskQuery? lastTaskQuery;
  ProjectQuery? lastProjectQuery;

  DateTime? lastTaskRangeStart;
  DateTime? lastTaskRangeEnd;
  DateTime? lastTaskToday;

  DateTime? lastProjectRangeStart;
  DateTime? lastProjectRangeEnd;
  DateTime? lastProjectToday;

  @override
  Stream<List<Task>> watchTaskOccurrences({
    required TaskQuery query,
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
    DateTime? todayDayKeyUtc,
  }) {
    lastTaskQuery = query;
    lastTaskRangeStart = rangeStartDay;
    lastTaskRangeEnd = rangeEndDay;
    lastTaskToday = todayDayKeyUtc;
    return _tasksController.stream;
  }

  @override
  Stream<List<Project>> watchProjectOccurrences({
    required ProjectQuery query,
    required DateTime rangeStartDay,
    required DateTime rangeEndDay,
    DateTime? todayDayKeyUtc,
  }) {
    lastProjectQuery = query;
    lastProjectRangeStart = rangeStartDay;
    lastProjectRangeEnd = rangeEndDay;
    lastProjectToday = todayDayKeyUtc;
    return _projectsController.stream;
  }
}

bool _isScheduledNonRecurringTaskQuery(TaskQuery? query) {
  if (query == null) return false;
  final shared = query.filter.shared;
  return shared.any(
    (p) =>
        p is TaskBoolPredicate &&
        p.field == TaskBoolField.repeating &&
        p.operator == BoolOperator.isFalse,
  );
}

bool _isScheduledNonRecurringProjectQuery(ProjectQuery? query) {
  if (query == null) return false;
  final shared = query.filter.shared;
  return shared.any(
    (p) =>
        p is ProjectBoolPredicate &&
        p.field == ProjectBoolField.repeating &&
        p.operator == BoolOperator.isFalse,
  );
}

void main() {
  Task buildTask({
    required String id,
    required String name,
    DateTime? start,
    DateTime? deadline,
    bool completed = false,
    String? repeatRrule,
    bool repeatFromCompletion = false,
    OccurrenceData? occurrence,
  }) {
    return Task(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: name,
      completed: completed,
      startDate: start,
      deadlineDate: deadline,
      repeatIcalRrule: repeatRrule,
      repeatFromCompletion: repeatFromCompletion,
      occurrence: occurrence,
    );
  }

  Project buildProject({
    required String id,
    required String name,
    DateTime? start,
    DateTime? deadline,
    bool completed = false,
    String? repeatRrule,
    bool repeatFromCompletion = false,
    OccurrenceData? occurrence,
  }) {
    return Project(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: name,
      completed: completed,
      startDate: start,
      deadlineDate: deadline,
      repeatIcalRrule: repeatRrule,
      repeatFromCompletion: repeatFromCompletion,
      occurrence: occurrence,
    );
  }

  testSafe(
    'watchScheduledOccurrences merges overdue and scheduled rows',
    () async {
      final overdueTasksController = StreamController<List<Task>>.broadcast();
      final overdueProjectsController =
          StreamController<List<Project>>.broadcast();
      final scheduledTasksController = StreamController<List<Task>>.broadcast();
      final scheduledProjectsController =
          StreamController<List<Project>>.broadcast();
      final recurringTasksController = StreamController<List<Task>>.broadcast();
      final recurringProjectsController =
          StreamController<List<Project>>.broadcast();

      addTearDown(overdueTasksController.close);
      addTearDown(overdueProjectsController.close);
      addTearDown(scheduledTasksController.close);
      addTearDown(scheduledProjectsController.close);
      addTearDown(recurringTasksController.close);
      addTearDown(recurringProjectsController.close);

      final taskRepo = _StreamTaskRepo(
        overdueTasksController,
        scheduledTasksController,
      );
      final projectRepo = _StreamProjectRepo(
        overdueProjectsController,
        scheduledProjectsController,
      );
      final occurrenceService = _CapturingOccurrenceService(
        recurringTasksController,
        recurringProjectsController,
      );

      final service = ScheduledOccurrencesService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        occurrenceReadService: occurrenceService,
      );

      final today = DateTime.utc(2026, 1, 10);
      final rangeStart = DateTime.utc(2026, 1, 9);
      final rangeEnd = DateTime.utc(2026, 1, 11);

      final overdueTask = buildTask(
        id: 't-overdue',
        name: '  ',
        deadline: DateTime.utc(2026, 1, 9),
      );
      final overdueProject = buildProject(
        id: 'p-overdue',
        name: '',
        deadline: DateTime.utc(2026, 1, 9),
      );

      final scheduledSameDay = buildTask(
        id: 't-same',
        name: 'Meeting',
        start: today,
        deadline: today,
      );
      final repeatingOccurrence = buildTask(
        id: 't-repeat-occurrence',
        name: 'Repeat',
        start: rangeStart,
        deadline: rangeEnd,
        repeatRrule: 'RRULE:FREQ=DAILY',
        repeatFromCompletion: true,
        occurrence: OccurrenceData(
          date: today,
          isRescheduled: false,
        ),
      );

      final scheduledProject = buildProject(
        id: 'p-schedule',
        name: 'Launch',
        start: rangeStart,
        deadline: rangeStart,
      );
      final repeatingProject = buildProject(
        id: 'p-repeat',
        name: 'Recurring',
        start: rangeStart,
        deadline: rangeEnd,
        repeatRrule: 'RRULE:FREQ=DAILY',
        repeatFromCompletion: true,
        occurrence: OccurrenceData(
          date: today,
          isRescheduled: false,
        ),
      );

      final resultFuture = service
          .watchScheduledOccurrences(
            rangeStartDay: rangeStart,
            rangeEndDay: rangeEnd,
            todayDayKeyUtc: today,
          )
          .first;

      overdueTasksController.add([overdueTask]);
      overdueProjectsController.add([overdueProject]);
      scheduledTasksController.add([scheduledSameDay]);
      scheduledProjectsController.add([scheduledProject]);
      recurringTasksController.add([repeatingOccurrence]);
      recurringProjectsController.add([repeatingProject]);

      final result = await resultFuture;

      expect(result.overdue, hasLength(2));
      expect(
        result.overdue.map((o) => o.name),
        containsAll(['Untitled task', 'Untitled project']),
      );

      final sameDay = result.occurrences
          .where((o) => o.entityId == 't-same')
          .toList(growable: false);
      expect(sameDay, hasLength(1));
      expect(sameDay.single.tag, ScheduledDateTag.due);

      final repeating = result.occurrences
          .where((o) => o.entityId == 't-repeat-occurrence')
          .toList(growable: false);
      expect(
        repeating.map((o) => o.tag),
        containsAll([ScheduledDateTag.starts, ScheduledDateTag.due]),
      );

      final occurrenceRow = result.occurrences
          .where((o) => o.entityId == 't-repeat-occurrence')
          .single;
      expect(occurrenceRow.localDay, dateOnly(today));

      final projectRows = result.occurrences
          .where((o) => o.entityId == 'p-schedule')
          .toList(growable: false);
      expect(projectRows, hasLength(1));
      expect(projectRows.single.tag, ScheduledDateTag.due);
    },
  );

  testSafe(
    'watchScheduledOccurrences applies value scope predicates',
    () async {
      final overdueTasksController = StreamController<List<Task>>.broadcast();
      final overdueProjectsController =
          StreamController<List<Project>>.broadcast();
      final scheduledTasksController = StreamController<List<Task>>.broadcast();
      final scheduledProjectsController =
          StreamController<List<Project>>.broadcast();
      final recurringTasksController = StreamController<List<Task>>.broadcast();
      final recurringProjectsController =
          StreamController<List<Project>>.broadcast();

      addTearDown(overdueTasksController.close);
      addTearDown(overdueProjectsController.close);
      addTearDown(scheduledTasksController.close);
      addTearDown(scheduledProjectsController.close);
      addTearDown(recurringTasksController.close);
      addTearDown(recurringProjectsController.close);

      final taskRepo = _StreamTaskRepo(
        overdueTasksController,
        scheduledTasksController,
      );
      final projectRepo = _StreamProjectRepo(
        overdueProjectsController,
        scheduledProjectsController,
      );
      final occurrenceService = _CapturingOccurrenceService(
        recurringTasksController,
        recurringProjectsController,
      );

      final service = ScheduledOccurrencesService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        occurrenceReadService: occurrenceService,
      );

      final rangeStart = DateTime.utc(2026, 1, 10);
      final rangeEnd = DateTime.utc(2026, 1, 12);

      final resultFuture = service
          .watchScheduledOccurrences(
            rangeStartDay: rangeStart,
            rangeEndDay: rangeEnd,
            todayDayKeyUtc: rangeStart,
            scope: const ValueScheduledScope(valueId: 'v1'),
          )
          .first;

      overdueTasksController.add(const <Task>[]);
      overdueProjectsController.add(const <Project>[]);
      scheduledTasksController.add(const <Task>[]);
      scheduledProjectsController.add(const <Project>[]);
      recurringTasksController.add(const <Task>[]);
      recurringProjectsController.add(const <Project>[]);
      await resultFuture;

      final taskPredicates = taskRepo.lastScheduledQuery?.filter.shared ?? [];
      expect(
        taskPredicates.any((p) => p is TaskValuePredicate),
        isTrue,
      );
      expect(
        taskPredicates.any(
          (p) =>
              p is TaskBoolPredicate &&
              p.field == TaskBoolField.repeating &&
              p.operator == BoolOperator.isFalse,
        ),
        isTrue,
      );

      final projectPredicates =
          projectRepo.lastScheduledQuery?.filter.shared ?? [];
      expect(
        projectPredicates.any((p) => p is ProjectValuePredicate),
        isTrue,
      );
      expect(
        projectPredicates.any(
          (p) =>
              p is ProjectBoolPredicate &&
              p.field == ProjectBoolField.repeating &&
              p.operator == BoolOperator.isFalse,
        ),
        isTrue,
      );

      final scheduledTaskPredicates =
          occurrenceService.lastTaskQuery?.filter.shared ?? [];
      expect(
        scheduledTaskPredicates.any((p) => p is TaskValuePredicate),
        isTrue,
      );
      expect(
        scheduledTaskPredicates.any(
          (p) =>
              p is TaskBoolPredicate &&
              p.field == TaskBoolField.repeating &&
              p.operator == BoolOperator.isTrue,
        ),
        isTrue,
      );

      final scheduledProjectPredicates =
          occurrenceService.lastProjectQuery?.filter.shared ?? [];
      expect(
        scheduledProjectPredicates.any((p) => p is ProjectValuePredicate),
        isTrue,
      );
      expect(
        scheduledProjectPredicates.any(
          (p) =>
              p is ProjectBoolPredicate &&
              p.field == ProjectBoolField.repeating &&
              p.operator == BoolOperator.isTrue,
        ),
        isTrue,
      );
    },
  );

  testSafe(
    'watchScheduledOccurrences applies project scope predicates',
    () async {
      final overdueTasksController = StreamController<List<Task>>.broadcast();
      final overdueProjectsController =
          StreamController<List<Project>>.broadcast();
      final scheduledTasksController = StreamController<List<Task>>.broadcast();
      final scheduledProjectsController =
          StreamController<List<Project>>.broadcast();
      final recurringTasksController = StreamController<List<Task>>.broadcast();
      final recurringProjectsController =
          StreamController<List<Project>>.broadcast();

      addTearDown(overdueTasksController.close);
      addTearDown(overdueProjectsController.close);
      addTearDown(scheduledTasksController.close);
      addTearDown(scheduledProjectsController.close);
      addTearDown(recurringTasksController.close);
      addTearDown(recurringProjectsController.close);

      final taskRepo = _StreamTaskRepo(
        overdueTasksController,
        scheduledTasksController,
      );
      final projectRepo = _StreamProjectRepo(
        overdueProjectsController,
        scheduledProjectsController,
      );
      final occurrenceService = _CapturingOccurrenceService(
        recurringTasksController,
        recurringProjectsController,
      );

      final service = ScheduledOccurrencesService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        occurrenceReadService: occurrenceService,
      );

      final rangeStart = DateTime.utc(2026, 1, 10);
      final rangeEnd = DateTime.utc(2026, 1, 12);

      final resultFuture = service
          .watchScheduledOccurrences(
            rangeStartDay: rangeStart,
            rangeEndDay: rangeEnd,
            todayDayKeyUtc: rangeStart,
            scope: const ProjectScheduledScope(projectId: 'p1'),
          )
          .first;

      overdueTasksController.add(const <Task>[]);
      overdueProjectsController.add(const <Project>[]);
      scheduledTasksController.add(const <Task>[]);
      scheduledProjectsController.add(const <Project>[]);
      recurringTasksController.add(const <Task>[]);
      recurringProjectsController.add(const <Project>[]);
      await resultFuture;

      final taskPredicates = taskRepo.lastScheduledQuery?.filter.shared ?? [];
      expect(
        taskPredicates.any((p) => p is TaskProjectPredicate),
        isTrue,
      );

      final projectPredicates =
          projectRepo.lastScheduledQuery?.filter.shared ?? [];
      expect(
        projectPredicates.any((p) => p is ProjectIdPredicate),
        isTrue,
      );
    },
  );
}
