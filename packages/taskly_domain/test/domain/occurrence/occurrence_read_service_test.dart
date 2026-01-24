@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/preferences.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/src/interfaces/occurrence_stream_expander_contract.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

class _CapturingTaskRepo extends Fake implements TaskRepositoryContract {
  _CapturingTaskRepo(this._tasksController);

  final StreamController<List<Task>> _tasksController;

  TaskQuery? lastWatchAllQuery;

  @override
  Stream<List<Task>> watchAll([TaskQuery? query]) {
    lastWatchAllQuery = query;
    return _tasksController.stream;
  }

  @override
  Stream<List<CompletionHistoryData>> watchCompletionHistory() =>
      const Stream<List<CompletionHistoryData>>.empty();

  @override
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions() =>
      const Stream<List<RecurrenceExceptionData>>.empty();

  @override
  Future<Map<String, TaskSnoozeStats>> getSnoozeStats({
    required DateTime sinceUtc,
    required DateTime untilUtc,
  }) async {
    return const <String, TaskSnoozeStats>{};
  }
}

class _CapturingProjectRepo extends Fake implements ProjectRepositoryContract {
  _CapturingProjectRepo(this._projectsController);

  final StreamController<List<Project>> _projectsController;

  ProjectQuery? lastWatchAllQuery;

  @override
  Stream<List<Project>> watchAll([ProjectQuery? query]) {
    lastWatchAllQuery = query;
    return _projectsController.stream;
  }

  @override
  Stream<List<CompletionHistoryData>> watchCompletionHistory() =>
      const Stream<List<CompletionHistoryData>>.empty();

  @override
  Stream<List<RecurrenceExceptionData>> watchRecurrenceExceptions() =>
      const Stream<List<RecurrenceExceptionData>>.empty();
}

class _CapturingOccurrenceExpander implements OccurrenceStreamExpanderContract {
  DateTime? lastTaskRangeStart;
  DateTime? lastTaskRangeEnd;
  bool Function(Task)? lastTaskPostExpansionFilter;

  DateTime? lastProjectRangeStart;
  DateTime? lastProjectRangeEnd;
  bool Function(Project)? lastProjectPostExpansionFilter;

  @override
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  }) {
    lastTaskRangeStart = rangeStart;
    lastTaskRangeEnd = rangeEnd;
    lastTaskPostExpansionFilter = postExpansionFilter;

    return tasksStream.map((tasks) {
      final expanded = tasks
          .expand((t) {
            if (!t.isRepeating || t.seriesEnded) return <Task>[t];
            return <Task>[
              t.copyWith(
                occurrence: OccurrenceData(
                  date: DateTime.utc(2026, 1, 12),
                  isRescheduled: false,
                ),
              ),
            ];
          })
          .toList(growable: false);

      if (postExpansionFilter == null) return expanded;
      return expanded.where(postExpansionFilter).toList(growable: false);
    });
  }

  @override
  Stream<List<Project>> expandProjectOccurrences({
    required Stream<List<Project>> projectsStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  }) {
    lastProjectRangeStart = rangeStart;
    lastProjectRangeEnd = rangeEnd;
    lastProjectPostExpansionFilter = postExpansionFilter;

    return projectsStream.map((projects) {
      if (postExpansionFilter == null) return projects;
      return projects.where(postExpansionFilter).toList(growable: false);
    });
  }

  @override
  List<Task> expandTaskOccurrencesSync({
    required List<Task> tasks,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task)? postExpansionFilter,
  }) {
    throw UnimplementedError();
  }

  @override
  List<Project> expandProjectOccurrencesSync({
    required List<Project> projects,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project)? postExpansionFilter,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  Task repeatingTask({required String id, bool seriesEnded = false}) {
    return Task(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Task $id',
      completed: false,
      repeatIcalRrule: 'RRULE:FREQ=DAILY',
      seriesEnded: seriesEnded,
    );
  }

  testSafe(
    'watchTasksWithOccurrencePreview clears expansion/preview and decorates next occurrence',
    () async {
      final taskController = StreamController<List<Task>>.broadcast();
      addTearDown(taskController.close);

      final projectController = StreamController<List<Project>>.broadcast();
      addTearDown(projectController.close);

      final taskRepo = _CapturingTaskRepo(taskController);
      final projectRepo = _CapturingProjectRepo(projectController);
      final dayKeyService = HomeDayKeyService(
        settingsRepository: _NoopSettingsRepo(),
      );
      final expander = _CapturingOccurrenceExpander();

      final service = OccurrenceReadService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: dayKeyService,
        occurrenceExpander: expander,
      );

      final query = TaskQuery.all().withOccurrencePreview(
        OccurrencePolicy.anytimePreview(asOfDayKey: DateTime.utc(2026, 1, 10)),
      );

      final stream = service.watchTasksWithOccurrencePreview(
        query: query,
        preview: OccurrencePolicy.anytimePreview(
          asOfDayKey: DateTime.utc(2026, 1, 10),
        ),
      );

      final resultsFuture = stream.take(2).toList();

      taskController.add([repeatingTask(id: 't1')]);

      final results = await resultsFuture;
      expect(results, hasLength(2));

      expect(results[0].single.occurrence, isNull);
      expect(results[1].single.occurrence?.date, DateTime.utc(2026, 1, 12));

      expect(taskRepo.lastWatchAllQuery?.shouldExpandOccurrences, isFalse);
      expect(taskRepo.lastWatchAllQuery?.hasOccurrencePreview, isFalse);
    },
  );

  testSafe(
    'watchTaskOccurrences strips date predicates for candidate query',
    () async {
      final taskController = StreamController<List<Task>>.broadcast();
      addTearDown(taskController.close);

      final projectController = StreamController<List<Project>>.broadcast();
      addTearDown(projectController.close);

      final taskRepo = _CapturingTaskRepo(taskController);
      final projectRepo = _CapturingProjectRepo(projectController);
      final expander = _CapturingOccurrenceExpander();

      final service = OccurrenceReadService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: HomeDayKeyService(
          settingsRepository: _NoopSettingsRepo(),
        ),
        occurrenceExpander: expander,
      );

      final rangeStart = DateTime.utc(2026, 1, 1);
      final rangeEnd = DateTime.utc(2026, 1, 3);

      final query = TaskQuery.schedule(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      final stream = service.watchTaskOccurrences(
        query: query,
        rangeStartDay: rangeStart,
        rangeEndDay: rangeEnd,
        todayDayKeyUtc: DateTime.utc(2026, 1, 2),
      );

      final resultsFuture = stream.take(1).toList();
      taskController.add(const <Task>[]);
      await resultsFuture;

      final candidateQuery = taskRepo.lastWatchAllQuery;
      expect(candidateQuery, isNotNull);
      expect(candidateQuery!.hasDateFilter, isFalse);
      expect(candidateQuery.shouldExpandOccurrences, isFalse);
      expect(candidateQuery.hasOccurrencePreview, isFalse);

      expect(expander.lastTaskRangeStart, rangeStart);
      expect(expander.lastTaskRangeEnd, rangeEnd);
      expect(expander.lastTaskPostExpansionFilter, isNotNull);
    },
  );

  testSafe(
    'watchProjectOccurrences strips date predicates for candidate query',
    () async {
      final taskController = StreamController<List<Task>>.broadcast();
      addTearDown(taskController.close);

      final projectController = StreamController<List<Project>>.broadcast();
      addTearDown(projectController.close);

      final taskRepo = _CapturingTaskRepo(taskController);
      final projectRepo = _CapturingProjectRepo(projectController);
      final expander = _CapturingOccurrenceExpander();

      final service = OccurrenceReadService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        dayKeyService: HomeDayKeyService(
          settingsRepository: _NoopSettingsRepo(),
        ),
        occurrenceExpander: expander,
      );

      final rangeStart = DateTime.utc(2026, 1, 1);
      final rangeEnd = DateTime.utc(2026, 1, 3);

      final query = ProjectQuery.schedule(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      final stream = service.watchProjectOccurrences(
        query: query,
        rangeStartDay: rangeStart,
        rangeEndDay: rangeEnd,
        todayDayKeyUtc: DateTime.utc(2026, 1, 2),
      );

      final resultsFuture = stream.take(1).toList();
      projectController.add(const <Project>[]);
      await resultsFuture;

      final candidateQuery = projectRepo.lastWatchAllQuery;
      expect(candidateQuery, isNotNull);
      expect(candidateQuery!.hasDateFilter, isFalse);
      expect(candidateQuery.shouldExpandOccurrences, isFalse);
      expect(candidateQuery.hasOccurrencePreview, isFalse);

      expect(expander.lastProjectRangeStart, rangeStart);
      expect(expander.lastProjectRangeEnd, rangeEnd);
      expect(expander.lastProjectPostExpansionFilter, isNotNull);
    },
  );
}

class _NoopSettingsRepo extends Fake implements SettingsRepositoryContract {
  @override
  Future<T> load<T>(SettingsKey<T> key) async {
    if (key == SettingsKey.global) {
      return const GlobalSettings(homeTimeZoneOffsetMinutes: 0) as T;
    }
    throw UnsupportedError('Unsupported key: $key');
  }

  @override
  Stream<T> watch<T>(SettingsKey<T> key) {
    if (key == SettingsKey.global) {
      return const Stream<GlobalSettings>.empty() as Stream<T>;
    }
    throw UnsupportedError('Unsupported key: $key');
  }

  @override
  Future<void> save<T>(
    SettingsKey<T> key,
    T value, {
    OperationContext? context,
  }) async {
    throw UnimplementedError();
  }
}
