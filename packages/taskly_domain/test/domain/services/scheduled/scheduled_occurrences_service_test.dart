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
  _StreamTaskRepo(this._controller);

  final StreamController<List<Task>> _controller;

  TaskQuery? lastWatchAllQuery;

  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) {
    lastWatchAllQuery = query;
    return _controller.stream;
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
  _StreamProjectRepo(this._controller);

  final StreamController<List<Project>> _controller;

  ProjectQuery? lastWatchAllQuery;

  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) {
    lastWatchAllQuery = query;
    return _controller.stream;
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

      addTearDown(overdueTasksController.close);
      addTearDown(overdueProjectsController.close);
      addTearDown(scheduledTasksController.close);
      addTearDown(scheduledProjectsController.close);

      final taskRepo = _StreamTaskRepo(overdueTasksController);
      final projectRepo = _StreamProjectRepo(overdueProjectsController);
      final occurrenceService = _CapturingOccurrenceService(
        scheduledTasksController,
        scheduledProjectsController,
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
      final repeatingTask = buildTask(
        id: 't-repeat',
        name: 'Repeat',
        start: rangeStart,
        deadline: rangeEnd,
        repeatRrule: 'RRULE:FREQ=DAILY',
        repeatFromCompletion: true,
      );
      final occurrenceTask = buildTask(
        id: 't-occurrence',
        name: 'Occurrence',
        start: DateTime.utc(2026, 1, 1),
        deadline: DateTime.utc(2026, 1, 2),
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

      final resultFuture = service
          .watchScheduledOccurrences(
            rangeStartDay: rangeStart,
            rangeEndDay: rangeEnd,
            todayDayKeyUtc: today,
          )
          .first;

      overdueTasksController.add([overdueTask]);
      overdueProjectsController.add([overdueProject]);
      scheduledTasksController.add(
        [scheduledSameDay, repeatingTask, occurrenceTask],
      );
      scheduledProjectsController.add([scheduledProject]);

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
          .where((o) => o.entityId == 't-repeat')
          .toList(growable: false);
      expect(
        repeating.map((o) => o.tag),
        containsAll([ScheduledDateTag.starts, ScheduledDateTag.due]),
      );

      final occurrenceRow = result.occurrences
          .where((o) => o.entityId == 't-occurrence')
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

      addTearDown(overdueTasksController.close);
      addTearDown(overdueProjectsController.close);
      addTearDown(scheduledTasksController.close);
      addTearDown(scheduledProjectsController.close);

      final taskRepo = _StreamTaskRepo(overdueTasksController);
      final projectRepo = _StreamProjectRepo(overdueProjectsController);
      final occurrenceService = _CapturingOccurrenceService(
        scheduledTasksController,
        scheduledProjectsController,
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
      await resultFuture;

      final taskPredicates = taskRepo.lastWatchAllQuery?.filter.shared ?? [];
      expect(
        taskPredicates.any((p) => p is TaskValuePredicate),
        isTrue,
      );

      final projectPredicates =
          projectRepo.lastWatchAllQuery?.filter.shared ?? [];
      expect(
        projectPredicates.any((p) => p is ProjectValuePredicate),
        isTrue,
      );

      final scheduledTaskPredicates =
          occurrenceService.lastTaskQuery?.filter.shared ?? [];
      expect(
        scheduledTaskPredicates.any((p) => p is TaskValuePredicate),
        isTrue,
      );

      final scheduledProjectPredicates =
          occurrenceService.lastProjectQuery?.filter.shared ?? [];
      expect(
        scheduledProjectPredicates.any((p) => p is ProjectValuePredicate),
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

      addTearDown(overdueTasksController.close);
      addTearDown(overdueProjectsController.close);
      addTearDown(scheduledTasksController.close);
      addTearDown(scheduledProjectsController.close);

      final taskRepo = _StreamTaskRepo(overdueTasksController);
      final projectRepo = _StreamProjectRepo(overdueProjectsController);
      final occurrenceService = _CapturingOccurrenceService(
        scheduledTasksController,
        scheduledProjectsController,
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
      await resultFuture;

      final taskPredicates = taskRepo.lastWatchAllQuery?.filter.shared ?? [];
      expect(
        taskPredicates.any((p) => p is TaskProjectPredicate),
        isTrue,
      );

      final projectPredicates =
          projectRepo.lastWatchAllQuery?.filter.shared ?? [];
      expect(
        projectPredicates.any((p) => p is ProjectIdPredicate),
        isTrue,
      );
    },
  );
}
