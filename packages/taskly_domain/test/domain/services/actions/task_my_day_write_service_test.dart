@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/my_day.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

import '../../../helpers/test_imports.dart';

class _MockTaskRepository extends Mock implements TaskRepositoryContract {}

class _MockProjectRepository extends Mock implements ProjectRepositoryContract {}

class _MockOccurrenceCommandService extends Mock
    implements OccurrenceCommandService {}

class _MockMyDayRepository extends Mock implements MyDayRepositoryContract {}

class _FakeDayKeyService extends Fake implements HomeDayKeyService {
  @override
  DateTime todayDayKeyUtc({DateTime? nowUtc}) => DateTime.utc(2026, 1, 2);
}

void main() {
  testSafe('createAndPickForToday appends a pick on success', () async {
    final taskRepository = _MockTaskRepository();
    final projectRepository = _MockProjectRepository();
    final occurrenceCommandService = _MockOccurrenceCommandService();
    final myDayRepository = _MockMyDayRepository();
    final dayKeyService = _FakeDayKeyService();
    final taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceCommandService: occurrenceCommandService,
    );
    final service = TaskMyDayWriteService(
      taskWriteService: taskWriteService,
      myDayRepository: myDayRepository,
      dayKeyService: dayKeyService,
    );

    final command = CreateTaskCommand(name: 'Task', completed: false);
    final context = OperationContext(
      correlationId: 'corr-1',
      feature: 'tasks',
      intent: 'test',
      operation: 'tasks.create',
    );

    when(
      () => taskRepository.createReturningId(
        name: 'Task',
        description: null,
        completed: false,
        startDate: null,
        deadlineDate: null,
        projectId: null,
        priority: null,
        repeatIcalRrule: null,
        repeatFromCompletion: false,
        seriesEnded: false,
        valueIds: null,
        context: context,
      ),
    ).thenAnswer((_) async => 'task-1');
    when(
      () => myDayRepository.appendPick(
        dayKeyUtc: DateTime.utc(2026, 1, 2),
        taskId: 'task-1',
        bucket: MyDayPickBucket.manual,
        context: context,
      ),
    ).thenAnswer((_) async {});

    final result = await service.createAndPickForToday(
      command,
      context: context,
    );

    expect(result, isA<CommandSuccess>());
    verify(
      () => myDayRepository.appendPick(
        dayKeyUtc: DateTime.utc(2026, 1, 2),
        taskId: 'task-1',
        bucket: MyDayPickBucket.manual,
        context: context,
      ),
    ).called(1);
  });

  testSafe('createAndPickForToday skips append on validation failure', () async {
    final taskRepository = _MockTaskRepository();
    final projectRepository = _MockProjectRepository();
    final occurrenceCommandService = _MockOccurrenceCommandService();
    final myDayRepository = _MockMyDayRepository();
    final dayKeyService = _FakeDayKeyService();
    final taskWriteService = TaskWriteService(
      taskRepository: taskRepository,
      projectRepository: projectRepository,
      occurrenceCommandService: occurrenceCommandService,
    );
    final service = TaskMyDayWriteService(
      taskWriteService: taskWriteService,
      myDayRepository: myDayRepository,
      dayKeyService: dayKeyService,
    );

    const failure = ValidationFailure();
    final command = CreateTaskCommand(name: '', completed: false);
    final context = OperationContext(
      correlationId: 'corr-2',
      feature: 'tasks',
      intent: 'test',
      operation: 'tasks.create',
    );

    final result = await service.createAndPickForToday(
      command,
      context: context,
    );

    expect(result, isA<CommandValidationFailure>());
    verifyNever(
      () => myDayRepository.appendPick(
        dayKeyUtc: DateTime.utc(2026, 1, 2),
        taskId: 'task-1',
        bucket: MyDayPickBucket.manual,
        context: context,
      ),
    );
  });
}
