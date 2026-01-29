@Tags(['integration'])
library;

import 'package:taskly_data/db.dart';
import 'package:taskly_data/repositories.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/telemetry.dart';
import 'package:taskly_domain/time.dart';

import '../helpers/test_imports.dart';
import '../helpers/test_db.dart';
import '../mocks/fake_id_generator.dart';
import '../mocks/repository_mocks.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  testSafe('task occurrence writes persist and forward OperationContext', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');
    final expander = MockOccurrenceStreamExpanderContract();
    final helper = RecordingOccurrenceWriteHelper(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );

    final taskRepository = TaskRepository(
      driftDb: db,
      occurrenceExpander: expander,
      occurrenceWriteHelper: helper,
      idGenerator: idGenerator,
      clock: clock,
    );

    await taskRepository.create(name: 'Task A', completed: false);
    final taskRow = await db.select(db.taskTable).getSingle();

    final contextFactory = TestOperationContextFactory();
    final completeContext = contextFactory.create(
      feature: 'tasks',
      intent: 'test',
      operation: 'tasks.complete_occurrence',
    );

    await taskRepository.completeOccurrence(
      taskId: taskRow.id,
      occurrenceDate: DateTime.utc(2025, 1, 15),
      context: completeContext,
    );

    final completionRow = await db
        .select(db.taskCompletionHistoryTable)
        .getSingle();
    expect(completionRow.taskId, taskRow.id);
    expectOperationContextForwarded(
      created: completeContext,
      forwarded: helper.contextByOp['completeTaskOccurrence'],
    );

    final skipContext = contextFactory.create(
      feature: 'tasks',
      intent: 'test',
      operation: 'tasks.skip_occurrence',
    );
    final originalDate = DateTime.utc(2025, 1, 10);
    await taskRepository.skipOccurrence(
      taskId: taskRow.id,
      originalDate: originalDate,
      context: skipContext,
    );

    final exceptionRow = await db
        .select(db.taskRecurrenceExceptionsTable)
        .getSingle();
    expect(exceptionRow.exceptionType, ExceptionType.skip);
    expectOperationContextForwarded(
      created: skipContext,
      forwarded: helper.contextByOp['skipTaskOccurrence'],
    );

    await taskRepository.removeException(
      taskId: taskRow.id,
      originalDate: originalDate,
    );

    final remaining = await db.select(db.taskRecurrenceExceptionsTable).get();
    expect(remaining, isEmpty);
  });

  testSafe('project occurrence writes persist and forward OperationContext', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');
    final expander = MockOccurrenceStreamExpanderContract();
    final helper = RecordingOccurrenceWriteHelper(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );

    final projectRepository = ProjectRepository(
      driftDb: db,
      occurrenceExpander: expander,
      occurrenceWriteHelper: helper,
      idGenerator: idGenerator,
      clock: clock,
    );

    await projectRepository.create(name: 'Project Alpha');
    final projectRow = await db.select(db.projectTable).getSingle();

    final contextFactory = TestOperationContextFactory();
    final completeContext = contextFactory.create(
      feature: 'projects',
      intent: 'test',
      operation: 'projects.complete_occurrence',
    );

    await projectRepository.completeOccurrence(
      projectId: projectRow.id,
      occurrenceDate: DateTime.utc(2025, 1, 15),
      context: completeContext,
    );

    final completionRow = await db
        .select(db.projectCompletionHistoryTable)
        .getSingle();
    expect(completionRow.projectId, projectRow.id);
    expectOperationContextForwarded(
      created: completeContext,
      forwarded: helper.contextByOp['completeProjectOccurrence'],
    );

    final rescheduleContext = contextFactory.create(
      feature: 'projects',
      intent: 'test',
      operation: 'projects.reschedule_occurrence',
    );

    final originalDate = DateTime.utc(2025, 1, 9);
    final newDate = DateTime.utc(2025, 1, 12);
    await projectRepository.rescheduleOccurrence(
      projectId: projectRow.id,
      originalDate: originalDate,
      newDate: newDate,
      context: rescheduleContext,
    );

    final exceptionRow = await db
        .select(db.projectRecurrenceExceptionsTable)
        .getSingle();
    expect(exceptionRow.exceptionType, ExceptionType.reschedule);
    expect(exceptionRow.newDate, newDate);
    expectOperationContextForwarded(
      created: rescheduleContext,
      forwarded: helper.contextByOp['rescheduleProjectOccurrence'],
    );

    await projectRepository.removeException(
      projectId: projectRow.id,
      originalDate: originalDate,
    );

    final remaining = await db
        .select(db.projectRecurrenceExceptionsTable)
        .get();
    expect(remaining, isEmpty);
  });

  testSafe('task occurrence uncomplete and series operations persist', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');
    final expander = MockOccurrenceStreamExpanderContract();
    final helper = RecordingOccurrenceWriteHelper(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );

    final taskRepository = TaskRepository(
      driftDb: db,
      occurrenceExpander: expander,
      occurrenceWriteHelper: helper,
      idGenerator: idGenerator,
      clock: clock,
    );

    await taskRepository.create(
      name: 'Recurring Task',
      completed: false,
      isPinned: true,
      repeatIcalRrule: 'FREQ=DAILY',
      repeatFromCompletion: true,
    );
    final taskRow = await db.select(db.taskTable).getSingle();

    final contextFactory = TestOperationContextFactory();
    final completeContext = contextFactory.create(
      feature: 'tasks',
      intent: 'test',
      operation: 'tasks.complete_occurrence',
    );

    await taskRepository.completeOccurrence(
      taskId: taskRow.id,
      context: completeContext,
    );
    var updatedTask = await db.select(db.taskTable).getSingle();
    expect(updatedTask.completed, isTrue);

    await taskRepository.uncompleteOccurrence(
      taskId: taskRow.id,
      context: contextFactory.create(
        feature: 'tasks',
        intent: 'test',
        operation: 'tasks.uncomplete_occurrence',
      ),
    );
    updatedTask = await db.select(db.taskTable).getSingle();
    expect(updatedTask.completed, isFalse);

    final originalDate = DateTime.utc(2025, 1, 16);
    await taskRepository.skipOccurrence(
      taskId: taskRow.id,
      originalDate: originalDate,
      context: contextFactory.create(
        feature: 'tasks',
        intent: 'test',
        operation: 'tasks.skip_occurrence',
      ),
    );

    await taskRepository.stopSeries(taskRow.id);
    updatedTask = await db.select(db.taskTable).getSingle();
    expect(updatedTask.seriesEnded, isTrue);

    await taskRepository.completeSeries(taskRow.id);
    updatedTask = await db.select(db.taskTable).getSingle();
    expect(updatedTask.isPinned, isFalse);

    final remainingExceptions =
        await db.select(db.taskRecurrenceExceptionsTable).get();
    expect(remainingExceptions, isEmpty);

    await taskRepository.convertToOneTime(taskRow.id);
    updatedTask = await db.select(db.taskTable).getSingle();
    expect(updatedTask.repeatIcalRrule, isNull);
    expect(updatedTask.repeatFromCompletion, isFalse);
  });

  testSafe('project series operations persist', () async {
    final db = createTestDb();
    addTearDown(() => closeTestDb(db));

    final clock = _FixedClock(DateTime.utc(2025, 1, 15, 12));
    final idGenerator = FakeIdGenerator('user-1');
    final expander = MockOccurrenceStreamExpanderContract();
    final helper = RecordingOccurrenceWriteHelper(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );

    final projectRepository = ProjectRepository(
      driftDb: db,
      occurrenceExpander: expander,
      occurrenceWriteHelper: helper,
      idGenerator: idGenerator,
      clock: clock,
    );

    final valueRepository = ValueRepository(
      driftDb: db,
      idGenerator: idGenerator,
      clock: clock,
    );
    await valueRepository.create(
      name: 'Work',
      color: '#FF0000',
      priority: ValuePriority.high,
    );
    final valueRow = await db.select(db.valueTable).getSingle();

    await projectRepository.create(
      name: 'Recurring Project',
      completed: false,
      repeatIcalRrule: 'FREQ=WEEKLY',
      repeatFromCompletion: true,
      valueIds: [valueRow.id],
    );
    var projectRow = await db.select(db.projectTable).getSingle();
    await projectRepository.setPinned(
      id: projectRow.id,
      isPinned: true,
      context: const OperationContext(
        correlationId: 'corr-pin',
        feature: 'projects',
        intent: 'test',
        operation: 'projects.pin',
      ),
    );
    projectRow = await db.select(db.projectTable).getSingle();

    final originalDate = DateTime.utc(2025, 1, 16);
    await projectRepository.skipOccurrence(
      projectId: projectRow.id,
      originalDate: originalDate,
      context: const OperationContext(
        correlationId: 'corr-1',
        feature: 'projects',
        intent: 'test',
        operation: 'projects.skip_occurrence',
      ),
    );

    await projectRepository.stopSeries(projectRow.id);
    var updatedProject = await db.select(db.projectTable).getSingle();
    expect(updatedProject.seriesEnded, isTrue);

    await projectRepository.completeSeries(projectRow.id);
    updatedProject = await db.select(db.projectTable).getSingle();
    expect(updatedProject.isPinned, isFalse);

    final remainingExceptions =
        await db.select(db.projectRecurrenceExceptionsTable).get();
    expect(remainingExceptions, isEmpty);

    await projectRepository.convertToOneTime(projectRow.id);
    updatedProject = await db.select(db.projectTable).getSingle();
    expect(updatedProject.repeatIcalRrule, isNull);
    expect(updatedProject.repeatFromCompletion, isFalse);
  });
}

final class RecordingOccurrenceWriteHelper extends OccurrenceWriteHelper {
  RecordingOccurrenceWriteHelper({
    required AppDatabase driftDb,
    required IdGenerator idGenerator,
    Clock clock = systemClock,
  }) : super(driftDb: driftDb, idGenerator: idGenerator, clock: clock);

  final Map<String, OperationContext?> contextByOp = {};

  void _record(String op, OperationContext? context) {
    contextByOp[op] = context;
  }

  @override
  Future<void> completeTaskOccurrence({
    required String taskId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) {
    _record('completeTaskOccurrence', context);
    return super.completeTaskOccurrence(
      taskId: taskId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
      notes: notes,
      context: context,
    );
  }

  @override
  Future<void> skipTaskOccurrence({
    required String taskId,
    required DateTime originalDate,
    OperationContext? context,
  }) {
    _record('skipTaskOccurrence', context);
    return super.skipTaskOccurrence(
      taskId: taskId,
      originalDate: originalDate,
      context: context,
    );
  }

  @override
  Future<void> completeProjectOccurrence({
    required String projectId,
    DateTime? occurrenceDate,
    DateTime? originalOccurrenceDate,
    String? notes,
    OperationContext? context,
  }) {
    _record('completeProjectOccurrence', context);
    return super.completeProjectOccurrence(
      projectId: projectId,
      occurrenceDate: occurrenceDate,
      originalOccurrenceDate: originalOccurrenceDate,
      notes: notes,
      context: context,
    );
  }

  @override
  Future<void> rescheduleProjectOccurrence({
    required String projectId,
    required DateTime originalDate,
    required DateTime newDate,
    DateTime? newDeadline,
    OperationContext? context,
  }) {
    _record('rescheduleProjectOccurrence', context);
    return super.rescheduleProjectOccurrence(
      projectId: projectId,
      originalDate: originalDate,
      newDate: newDate,
      newDeadline: newDeadline,
      context: context,
    );
  }
}

final class _FixedClock implements Clock {
  _FixedClock(this._nowUtc);

  final DateTime _nowUtc;

  @override
  DateTime nowLocal() => _nowUtc.toLocal();

  @override
  DateTime nowUtc() => _nowUtc;
}
