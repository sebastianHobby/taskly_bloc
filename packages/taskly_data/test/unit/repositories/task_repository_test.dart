@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:drift/drift.dart' as drift;
import 'package:matcher/matcher.dart' as matcher;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/task_repository.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('TaskRepository', () {
    testSafe('create normalizes projectId and writes task', () async {
      final db = createAutoClosingDb();
      final expander = _FakeOccurrenceExpander();
      final writeHelper = _FakeOccurrenceWriteHelper();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: expander,
        occurrenceWriteHelper: writeHelper,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task', projectId: '  ');

      final row = await db.select(db.taskTable).getSingle();
      expect(row.projectId, matcher.isNull);
      expect(row.overridePrimaryValueId, matcher.isNull);
      expect(row.overrideSecondaryValueId, matcher.isNull);
    });

    testSafe('create rejects values when projectId is missing', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Task', projectId: '  ', valueIds: ['v1']),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('create rejects duplicate override values', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Task', valueIds: ['v1', 'v1']),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('create rejects more than two override values', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Task', valueIds: ['v1', 'v2', 'v3']),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('update throws when task not found', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.update(id: 'missing', name: 'Task', completed: false),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    testSafe('update rejects duplicate override values', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task');
      final row = await db.select(db.taskTable).getSingle();

      expect(
        () => repo.update(
          id: row.id,
          name: 'Task',
          completed: false,
          valueIds: ['v1', 'v1'],
        ),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('setPinned updates pinned state', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task');
      final row = await db.select(db.taskTable).getSingle();

      await repo.setPinned(id: row.id, isPinned: true);

      final updated = await db.select(db.taskTable).getSingle();
      expect(updated.isPinned, isTrue);
    });

    testSafe('delete removes task', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Task');
      final row = await db.select(db.taskTable).getSingle();

      await repo.delete(row.id);

      final remaining = await db.select(db.taskTable).get();
      expect(remaining, isEmpty);
    });

    testSafe('watchAllCount respects filters', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'A',
              completed: const drift.Value(true),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t2'),
              name: 'B',
              completed: const drift.Value(false),
            ),
          );

      final query = TaskQuery(
        filter: const QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        ),
      );

      final count = await repo.watchAllCount(query).first;
      expect(count, equals(1));
    });

    testSafe('watchAll caches inbox/today/upcoming streams', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final inbox1 = repo.watchAll(TaskQuery.inbox());
      final inbox2 = repo.watchAll(TaskQuery.inbox());
      expect(identical(inbox1, inbox2), isTrue);

      final todayQuery = TaskQuery.today(now: DateTime.utc(2025, 1, 1));
      final today1 = repo.watchAll(todayQuery);
      final today2 = repo.watchAll(todayQuery);
      expect(identical(today1, today2), isTrue);

      final upcoming1 = repo.watchAll(TaskQuery.upcoming());
      final upcoming2 = repo.watchAll(TaskQuery.upcoming());
      expect(identical(upcoming1, upcoming2), isTrue);
    });

    testSafe('getAll applies sort criteria', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'B',
              completed: const drift.Value(false),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t2'),
              name: 'A',
              completed: const drift.Value(false),
            ),
          );

      final query = TaskQuery(
        sortCriteria: const [SortCriterion(field: SortField.name)],
      );
      final tasks = await repo.getAll(query);
      expect(tasks.map((t) => t.id).toList(), equals(['t2', 't1']));
    });

    testSafe('getByIds preserves order and omits missing', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'One',
              completed: const drift.Value(false),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t2'),
              name: 'Two',
              completed: const drift.Value(false),
            ),
          );

      final tasks = await repo.getByIds(['t2', 'missing', 't1']);
      expect(tasks.map((t) => t.id).toList(), equals(['t2', 't1']));
    });

    testSafe('recognizes inbox/today/upcoming queries', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(repo.isInboxQuery(TaskQuery.inbox()), isTrue);
      expect(
        repo.isTodayQuery(TaskQuery.today(now: DateTime.utc(2025, 1, 1))),
        isTrue,
      );
      expect(repo.isUpcomingQuery(TaskQuery.upcoming()), isTrue);
    });

    testSafe('removeDatePredicates strips date filters', () async {
      final db = createAutoClosingDb();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final filter = QueryFilter<TaskPredicate>(
        shared: [
          const TaskBoolPredicate(
            field: TaskBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
          TaskDatePredicate(
            field: TaskDateField.deadlineDate,
            operator: DateOperator.onOrBefore,
            date: DateTime.utc(2025, 1, 1),
          ),
        ],
      );

      final stripped = repo.removeDatePredicates(filter);
      expect(stripped.shared.length, equals(1));
      expect(stripped.shared.first, isA<TaskBoolPredicate>());
    });

    testSafe('getOccurrences delegates to expander', () async {
      final db = createAutoClosingDb();
      final expander = _FakeOccurrenceExpander();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: expander,
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'Task',
              completed: const drift.Value(false),
            ),
          );

      final rangeStart = DateTime.utc(2025, 1, 1);
      final rangeEnd = DateTime.utc(2025, 1, 2);

      final results = await repo.getOccurrences(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(results.length, equals(1));
      expect(expander.lastTaskRangeStart, equals(rangeStart));
      expect(expander.lastTaskRangeEnd, equals(rangeEnd));
    });

    testSafe('watchOccurrences caches streams by range', () async {
      final db = createAutoClosingDb();
      final expander = _FakeOccurrenceExpander();
      final repo = TaskRepository(
        driftDb: db,
        occurrenceExpander: expander,
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final rangeStart = DateTime.utc(2025, 1, 1);
      final rangeEnd = DateTime.utc(2025, 1, 2);

      final s1 = repo.watchOccurrences(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );
      final s2 = repo.watchOccurrences(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(identical(s1, s2), isTrue);
    });
  });
}

class _FakeOccurrenceExpander implements OccurrenceStreamExpanderContract {
  DateTime? lastTaskRangeStart;
  DateTime? lastTaskRangeEnd;
  DateTime? lastProjectRangeStart;
  DateTime? lastProjectRangeEnd;

  @override
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task p1)? postExpansionFilter,
  }) {
    lastTaskRangeStart = rangeStart;
    lastTaskRangeEnd = rangeEnd;
    return tasksStream;
  }

  @override
  List<Task> expandTaskOccurrencesSync({
    required List<Task> tasks,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task p1)? postExpansionFilter,
  }) {
    lastTaskRangeStart = rangeStart;
    lastTaskRangeEnd = rangeEnd;
    return tasks;
  }

  @override
  Stream<List<Project>> expandProjectOccurrences({
    required Stream<List<Project>> projectsStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project p1)? postExpansionFilter,
  }) {
    lastProjectRangeStart = rangeStart;
    lastProjectRangeEnd = rangeEnd;
    return projectsStream;
  }

  @override
  List<Project> expandProjectOccurrencesSync({
    required List<Project> projects,
    required List<CompletionHistoryData> completions,
    required List<RecurrenceExceptionData> exceptions,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Project p1)? postExpansionFilter,
  }) {
    lastProjectRangeStart = rangeStart;
    lastProjectRangeEnd = rangeEnd;
    return projects;
  }
}

class _FakeOccurrenceWriteHelper implements OccurrenceWriteHelperContract {
  final List<String> calls = [];

  void _record(String name) => calls.add(name);

  @override
  Future<void> completeTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    _record('completeTaskOccurrence');
  }

  @override
  Future<void> uncompleteTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    _record('uncompleteTaskOccurrence');
  }

  @override
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    _record('skipTaskOccurrence');
  }

  @override
  Future<void> rescheduleTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async {
    _record('rescheduleTaskOccurrence');
  }

  @override
  Future<void> removeTaskException({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    _record('removeTaskException');
  }

  @override
  Future<void> stopTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {
    _record('stopTaskSeries');
  }

  @override
  Future<void> completeTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {
    _record('completeTaskSeries');
  }

  @override
  Future<void> convertTaskToOneTime(
    String taskId, {
    OperationContext? context,
  }) async {
    _record('convertTaskToOneTime');
  }

  @override
  Future<void> completeProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {
    _record('completeProjectOccurrence');
  }

  @override
  Future<void> uncompleteProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {
    _record('uncompleteProjectOccurrence');
  }

  @override
  Future<void> skipProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    _record('skipProjectOccurrence');
  }

  @override
  Future<void> rescheduleProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async {
    _record('rescheduleProjectOccurrence');
  }

  @override
  Future<void> removeProjectException({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {
    _record('removeProjectException');
  }

  @override
  Future<void> stopProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {
    _record('stopProjectSeries');
  }

  @override
  Future<void> completeProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {
    _record('completeProjectSeries');
  }

  @override
  Future<void> convertProjectToOneTime(
    String projectId, {
    OperationContext? context,
  }) async {
    _record('convertProjectToOneTime');
  }
}
