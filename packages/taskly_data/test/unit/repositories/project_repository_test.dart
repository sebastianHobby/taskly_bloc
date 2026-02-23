@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import '../../helpers/test_db.dart';
import '../../helpers/fixed_clock.dart';

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

    testSafe('create writes primary value', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Project', valueIds: ['v1']);

      final row = await db.select(db.projectTable).getSingle();
      expect(row.primaryValueId, equals('v1'));
    });

    testSafe('create rejects more than one value', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      expect(
        () => repo.create(name: 'Project', valueIds: ['v1', 'v2']),
        throwsA(isA<InputValidationFailure>()),
      );
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

    testSafe('bulkRescheduleDeadlines returns count on no-op update', () async {
      final db = createAutoClosingDb();
      final fixedNow = DateTime.utc(2026, 2, 9, 12);
      final deadlineDay = DateTime.utc(2026, 2, 10);
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
        clock: FixedClock(fixedNow),
      );

      await repo.create(
        name: 'Project',
        valueIds: ['v1'],
        deadlineDate: deadlineDay,
      );
      final id = (await db.select(db.projectTable).getSingle()).id;

      final updated = await repo.bulkRescheduleDeadlines(
        projectIds: [id],
        deadlineDate: deadlineDay,
      );

      expect(updated, equals(1));
      final row = await db.select(db.projectTable).getSingle();
      expect(row.deadlineDate, equals(deadlineDay));
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

    testSafe('watchAll executes non-date query path', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final query = ProjectQuery(
        filter: const QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        ),
      );

      final s1 = repo.watchAll(query);
      final s2 = repo.watchAll(query);
      expect(await s1.first, isA<List<Project>>());
      expect(await s2.first, isA<List<Project>>());
    });

    testSafe('watchAll executes date-filter query path', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final query = ProjectQuery(
        filter: QueryFilter<ProjectPredicate>(
          shared: [
            ProjectDatePredicate(
              field: ProjectDateField.deadlineDate,
              operator: DateOperator.onOrAfter,
              date: DateTime.utc(2026, 1, 1),
            ),
          ],
        ),
      );

      final s1 = repo.watchAll(query);
      final s2 = repo.watchAll(query);
      expect(await s1.first, isA<List<Project>>());
      expect(await s2.first, isA<List<Project>>());
    });

    testSafe('watchAll/getAll/watchAllCount reject occurrence flags', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final query = ProjectQuery(
        occurrenceExpansion: OccurrenceExpansion(
          rangeStart: DateTime.utc(2026, 1, 1),
          rangeEnd: DateTime.utc(2026, 1, 2),
        ),
      );

      expect(() => repo.watchAll(query), throwsA(isA<UnsupportedError>()));
      expect(() => repo.getAll(query), throwsA(isA<UnsupportedError>()));
      expect(
        () => repo.watchAllCount(query),
        throwsA(isA<UnsupportedError>()),
      );
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

    testSafe('watchById emits null when project does not exist', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final project = await repo.watchById('missing').first;
      expect(project, isNull);
    });

    testSafe('getById returns null when project does not exist', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final project = await repo.getById('missing');
      expect(project, isNull);
    });

    testSafe(
      'update normalizes project task overrides on primary change',
      () async {
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
                overridePrimaryValueId: const drift.Value('v2'),
                overrideSecondaryValueId: const drift.Value('v3'),
              ),
            );

        await repo.update(
          id: 'p1',
          name: 'Project',
          completed: false,
          valueIds: ['v2'],
        );

        final task = await (db.select(
          db.taskTable,
        )..where((t) => t.id.equals('t1'))).getSingle();
        expect(task.overridePrimaryValueId, equals('v3'));
        expect(task.overrideSecondaryValueId, isNull);
      },
    );

    testSafe('update validates valueIds shape and series flags', () async {
      final db = createAutoClosingDb();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      await repo.create(name: 'Project', valueIds: ['v1']);
      final id = (await db.select(db.projectTable).getSingle()).id;

      await expectLater(
        () => repo.update(
          id: id,
          name: 'Project',
          completed: false,
          valueIds: const [],
        ),
        throwsA(isA<InputValidationFailure>()),
      );
      await expectLater(
        () => repo.update(
          id: id,
          name: 'Project',
          completed: false,
          valueIds: const ['v1', 'v2'],
        ),
        throwsA(isA<InputValidationFailure>()),
      );

      await repo.update(
        id: id,
        name: 'Project+',
        completed: false,
        repeatIcalRrule: 'FREQ=WEEKLY',
        repeatFromCompletion: true,
        seriesEnded: true,
      );
      final row = await db.select(db.projectTable).getSingle();
      expect(row.repeatIcalRrule, 'FREQ=WEEKLY');
      expect(row.repeatFromCompletion, isTrue);
      expect(row.seriesEnded, isTrue);
    });

    testSafe(
      'bulkRescheduleDeadlines throws when some project ids are missing',
      () async {
        final db = createAutoClosingDb();
        final repo = ProjectRepository(
          driftDb: db,
          occurrenceExpander: _FakeOccurrenceExpander(),
          occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
          idGenerator: IdGenerator.withUserId('user-1'),
        );

        await repo.create(name: 'Project', valueIds: ['v1']);
        final existingId = (await db.select(db.projectTable).getSingle()).id;

        await expectLater(
          () => repo.bulkRescheduleDeadlines(
            projectIds: [existingId, 'missing'],
            deadlineDate: DateTime.utc(2026, 2, 11),
          ),
          throwsA(isA<NotFoundFailure>()),
        );
      },
    );

    testSafe(
      'delete removes project and watch completion/exception mappings',
      () async {
        final db = createAutoClosingDb();
        final repo = ProjectRepository(
          driftDb: db,
          occurrenceExpander: _FakeOccurrenceExpander(),
          occurrenceWriteHelper: _FakeOccurrenceWriteHelper(),
          idGenerator: IdGenerator.withUserId('user-1'),
        );

        await repo.create(name: 'Project', valueIds: ['v1']);
        final projectId = (await db.select(db.projectTable).getSingle()).id;

        final day = DateTime.utc(2026, 1, 1);
        await db
            .into(db.projectCompletionHistoryTable)
            .insert(
              ProjectCompletionHistoryTableCompanion.insert(
                id: 'c1',
                projectId: projectId,
                occurrenceDate: drift.Value(day),
                completedAt: drift.Value(day),
              ),
            );
        await db
            .into(db.projectRecurrenceExceptionsTable)
            .insert(
              ProjectRecurrenceExceptionsTableCompanion.insert(
                id: 'e1',
                projectId: projectId,
                originalDate: day,
                exceptionType: ExceptionType.reschedule,
                newDate: drift.Value(day.add(const Duration(days: 1))),
              ),
            );

        final completions = await repo.watchCompletionHistory().first;
        final exceptions = await repo.watchRecurrenceExceptions().first;
        expect(completions.single.entityId, projectId);
        expect(
          exceptions.single.exceptionType,
          RecurrenceExceptionType.reschedule,
        );

        await repo.delete(projectId);
        final rows = await db.select(db.projectTable).get();
        expect(rows, isEmpty);
      },
    );

    testSafe(
      'getOccurrencesForProject filters project-specific rows',
      () async {
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
                name: 'Project 1',
                completed: false,
                primaryValueId: const drift.Value('v1'),
              ),
            );
        await db
            .into(db.projectTable)
            .insert(
              ProjectTableCompanion.insert(
                id: const drift.Value('p2'),
                name: 'Project 2',
                completed: false,
                primaryValueId: const drift.Value('v1'),
              ),
            );

        final out = await repo.getOccurrencesForProject(
          projectId: 'p1',
          rangeStart: DateTime.utc(2026, 1, 1),
          rangeEnd: DateTime.utc(2026, 1, 3),
        );
        expect(out.map((p) => p.id).toList(), ['p1']);
        expect(expander.lastProjectRangeStart, DateTime.utc(2026, 1, 1));
        expect(expander.lastProjectRangeEnd, DateTime.utc(2026, 1, 3));
      },
    );

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

    testSafe('watchOccurrences delegates to expander stream', () async {
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
      final projects = await repo
          .watchOccurrences(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          )
          .first;

      expect(projects, hasLength(1));
      expect(expander.lastProjectRangeStart, equals(rangeStart));
      expect(expander.lastProjectRangeEnd, equals(rangeEnd));
    });

    testSafe('project occurrence write helpers are delegated', () async {
      final db = createAutoClosingDb();
      final writeHelper = _FakeOccurrenceWriteHelper();
      final repo = ProjectRepository(
        driftDb: db,
        occurrenceExpander: _FakeOccurrenceExpander(),
        occurrenceWriteHelper: writeHelper,
        idGenerator: IdGenerator.withUserId('user-1'),
      );

      final day = DateTime.utc(2026, 1, 2);
      await repo.completeOccurrence(projectId: 'p1', occurrenceDate: day);
      await repo.uncompleteOccurrence(projectId: 'p1', occurrenceDate: day);
      await repo.skipOccurrence(projectId: 'p1', originalDate: day);
      await repo.rescheduleOccurrence(
        projectId: 'p1',
        originalDate: day,
        newDate: day.add(const Duration(days: 1)),
      );
      await repo.removeException(projectId: 'p1', originalDate: day);
      await repo.stopSeries('p1');
      await repo.completeSeries('p1');
      await repo.convertToOneTime('p1');

      expect(
        writeHelper.calls,
        equals([
          'completeProjectOccurrence',
          'uncompleteProjectOccurrence',
          'skipProjectOccurrence',
          'rescheduleProjectOccurrence',
          'removeProjectException',
          'stopProjectSeries',
          'completeProjectSeries',
          'convertProjectToOneTime',
        ]),
      );
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
  final List<String> calls = [];

  void _record(String name) => calls.add(name);

  @override
  Future<void> completeProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async => _record('completeProjectOccurrence');

  @override
  Future<void> completeProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async => _record('completeProjectSeries');

  @override
  Future<void> completeTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) async => _record('completeTaskOccurrence');

  @override
  Future<void> completeTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async => _record('completeTaskSeries');

  @override
  Future<void> convertProjectToOneTime(
    String projectId, {
    OperationContext? context,
  }) async => _record('convertProjectToOneTime');

  @override
  Future<void> convertTaskToOneTime(
    String taskId, {
    OperationContext? context,
  }) async => _record('convertTaskToOneTime');

  @override
  Future<void> removeProjectException({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async => _record('removeProjectException');

  @override
  Future<void> removeTaskException({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async => _record('removeTaskException');

  @override
  Future<void> rescheduleProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async => _record('rescheduleProjectOccurrence');

  @override
  Future<void> rescheduleTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) async => _record('rescheduleTaskOccurrence');

  @override
  Future<void> skipProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    OperationContext? context,
  }) async => _record('skipProjectOccurrence');

  @override
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) async => _record('skipTaskOccurrence');

  @override
  Future<void> stopProjectSeries(
    String projectId, {
    OperationContext? context,
  }) async => _record('stopProjectSeries');

  @override
  Future<void> stopTaskSeries(
    String taskId, {
    OperationContext? context,
  }) async => _record('stopTaskSeries');

  @override
  Future<void> uncompleteProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async => _record('uncompleteProjectOccurrence');

  @override
  Future<void> uncompleteTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    OperationContext? context,
  }) async => _record('uncompleteTaskOccurrence');
}
