@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';

import 'package:drift/drift.dart' as drift;
import 'package:matcher/matcher.dart' as matcher;
import 'package:taskly_data/db.dart';
import 'package:taskly_data/id.dart';
import 'package:taskly_data/src/repositories/project_repository.dart';
import 'package:taskly_domain/taskly_domain.dart' hide Value;

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('ProjectRepository', () {
    testSafe('create requires at least one value', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Project'),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('create rejects duplicate values', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Project', valueIds: ['v1', 'v1']),
        throwsA(isA<InputValidationFailure>()),
      );
    });

    testSafe('create writes primary/secondary values', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Project', valueIds: ['v1', 'v2']);

      final row = await db.select(db.projectTable).getSingle();
      expect(row.primaryValueId, equals('v1'));
      expect(row.secondaryValueId, equals('v2'));
    });

    testSafe('update throws when project not found', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.update(id: 'missing', name: 'Project', completed: false),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    testSafe('setPinned updates pinned state', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Project', valueIds: ['v1']);
      final row = await db.select(db.projectTable).getSingle();

      await repo.setPinned(id: row.id, isPinned: true);

      final updated = await db.select(db.projectTable).getSingle();
      expect(updated.isPinned, isTrue);
    });

    testSafe('watchAllCount respects filters', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const drift.Value('p1'),
              name: 'A',
              completed: false,
              primaryValueId: const drift.Value('v1'),
            ),
          );
      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const drift.Value('p2'),
              name: 'B',
              completed: true,
              primaryValueId: const drift.Value('v1'),
            ),
          );

      final query = ProjectQuery(
        filter: const QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        ),
      );

      final count = await repo.watchAllCount(query).first;
      expect(count, equals(1));
    });

    testSafe('watchAll returns distinct stream wrappers', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final s1 = repo.watchAll();
      final s2 = repo.watchAll();
      expect(identical(s1, s2), isFalse);
    });

    testSafe('getAll returns projects ordered by name', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const drift.Value('p1'),
              name: 'B',
              completed: false,
              primaryValueId: const drift.Value('v1'),
            ),
          );
      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const drift.Value('p2'),
              name: 'A',
              completed: false,
              primaryValueId: const drift.Value('v1'),
            ),
          );

      final projects = await repo.getAll();
      expect(projects.map((p) => p.id).toList(), equals(['p2', 'p1']));
    });

    testSafe('getById includes task counts', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const drift.Value('p1'),
              name: 'Project',
              completed: false,
              primaryValueId: const drift.Value('v1'),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'Task',
              completed: const drift.Value(false),
              projectId: const drift.Value('p1'),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t2'),
              name: 'Task',
              completed: const drift.Value(true),
              projectId: const drift.Value('p1'),
            ),
          );

      final project = await repo.getById('p1');
      expect(project, matcher.isNotNull);
      expect(project!.taskCount, equals(2));
      expect(project.completedTaskCount, equals(1));
    });

    testSafe('watchById merges task counts', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const drift.Value('p1'),
              name: 'Project',
              completed: false,
              primaryValueId: const drift.Value('v1'),
            ),
          );
      await db
          .into(db.taskTable)
          .insert(
            TaskTableCompanion.insert(
              id: const drift.Value('t1'),
              name: 'Task',
              completed: const drift.Value(false),
              projectId: const drift.Value('p1'),
            ),
          );

      final project = await repo.watchById('p1').first;
      expect(project, matcher.isNotNull);
      expect(project!.taskCount, equals(1));
      expect(project.completedTaskCount, equals(0));
    });

    testSafe('getOccurrences delegates to expander', () async {
      final db = createAutoClosingDb();
      final expander = _FakeOccurrenceExpander();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: expander,
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await db
          .into(db.projectTable)
          .insert(
            ProjectTableCompanion.insert(
              id: const drift.Value('p1'),
              name: 'Project',
              completed: false,
              primaryValueId: const drift.Value('v1'),
            ),
          );

      final rangeStart = DateTime.utc(2025, 1, 1);
      final rangeEnd = DateTime.utc(2025, 1, 2);

      final results = await repo.getOccurrences(
        rangeStart: rangeStart,
        rangeEnd: rangeEnd,
      );

      expect(results.length, equals(1));
      expect(expander.lastProjectRangeStart, equals(rangeStart));
      expect(expander.lastProjectRangeEnd, equals(rangeEnd));
    });
  });
}

class _FakeOccurrenceExpander implements OccurrenceStreamExpanderContract {
  DateTime? lastProjectRangeStart;
  DateTime? lastProjectRangeEnd;

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

  @override
  Stream<List<Task>> expandTaskOccurrences({
    required Stream<List<Task>> tasksStream,
    required Stream<List<CompletionHistoryData>> completionsStream,
    required Stream<List<RecurrenceExceptionData>> exceptionsStream,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    bool Function(Task p1)? postExpansionFilter,
  }) {
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
    return tasks;
  }
}

class _FakeOccurrenceWriteHelper implements OccurrenceWriteHelperContract {
  @override
  Future<void> completeProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {}

  @override
  Future<void> completeProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {}

  @override
  Future<void> completeTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async {}

  @override
  Future<void> completeTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {}

  @override
  Future<void> convertProjectToOneTime(
    String projectId, {
    OperationContext? context,
  }) async {}

  @override
  Future<void> convertTaskToOneTime(
    String taskId, {
    OperationContext? context,
  }) async {}

  @override
  Future<void> removeProjectException({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> removeTaskException({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> rescheduleProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async {}

  @override
  Future<void> rescheduleTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async {}

  @override
  Future<void> skipProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> stopProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async {}

  @override
  Future<void> stopTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async {}

  @override
  Future<void> uncompleteProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {}

  @override
  Future<void> uncompleteTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async {}
}
