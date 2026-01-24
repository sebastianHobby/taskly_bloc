@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';

import 'package:mocktail/mocktail.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_domain/contracts.dart';
import 'package:taskly_domain/core.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/telemetry.dart';

class _MockTaskRepo extends Mock implements TaskRepositoryContract {}

class _MockProjectRepo extends Mock implements ProjectRepositoryContract {}

class _MockValueRepo extends Mock implements ValueRepositoryContract {}

class _MockAllocationOrchestrator extends Mock
    implements AllocationOrchestrator {}

class _MockOccurrenceCommandService extends Mock
    implements OccurrenceCommandService {}

void main() {
  setUpAll(initializeLoggingForTest);

  setUpAll(() {
    registerFallbackValue(const OperationContext());
  });

  Task buildTask({required String id, String? projectId}) {
    return Task(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Task $id',
      completed: false,
      projectId: projectId,
    );
  }

  Project buildProject({required String id}) {
    return Project(
      id: id,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
      name: 'Project $id',
      completed: false,
    );
  }

  testSafe('performAction move task updates projectId', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final valueRepo = _MockValueRepo();
    final allocation = _MockAllocationOrchestrator();
    final occurrence = _MockOccurrenceCommandService();

    final task = buildTask(id: 't1');

    when(() => taskRepo.getById('t1')).thenAnswer((_) async => task);
    when(
      () => taskRepo.update(
        id: any(named: 'id'),
        name: any(named: 'name'),
        completed: any(named: 'completed'),
        description: any(named: 'description'),
        projectId: any(named: 'projectId'),
        startDate: any(named: 'startDate'),
        deadlineDate: any(named: 'deadlineDate'),
        priority: any(named: 'priority'),
        repeatIcalRrule: any(named: 'repeatIcalRrule'),
        repeatFromCompletion: any(named: 'repeatFromCompletion'),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final service = EntityActionService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      valueRepository: valueRepo,
      allocationOrchestrator: allocation,
      occurrenceCommandService: occurrence,
    );

    await service.performAction(
      entityId: 't1',
      entityType: EntityType.task,
      action: EntityActionType.move,
      params: {'targetProjectId': 'p2'},
    );

    verify(
      () => taskRepo.update(
        id: 't1',
        name: task.name,
        completed: task.completed,
        description: task.description,
        projectId: 'p2',
        startDate: task.startDate,
        deadlineDate: task.deadlineDate,
        priority: task.priority,
        repeatIcalRrule: task.repeatIcalRrule,
        repeatFromCompletion: task.repeatFromCompletion,
        context: null,
      ),
    ).called(1);
  });

  testSafe('performAction delete value uses repository', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final valueRepo = _MockValueRepo();
    final allocation = _MockAllocationOrchestrator();
    final occurrence = _MockOccurrenceCommandService();

    when(
      () => valueRepo.delete(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final service = EntityActionService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      valueRepository: valueRepo,
      allocationOrchestrator: allocation,
      occurrenceCommandService: occurrence,
    );

    await service.performAction(
      entityId: 'v1',
      entityType: EntityType.value,
      action: EntityActionType.delete,
    );

    verify(
      () => valueRepo.delete('v1', context: null),
    ).called(1);
  });

  testSafe(
    'performAction complete task delegates to occurrence service',
    () async {
      final taskRepo = _MockTaskRepo();
      final projectRepo = _MockProjectRepo();
      final valueRepo = _MockValueRepo();
      final allocation = _MockAllocationOrchestrator();
      final occurrence = _MockOccurrenceCommandService();

      when(
        () => occurrence.completeTask(
          taskId: any(named: 'taskId'),
          occurrenceDate: any(named: 'occurrenceDate'),
          originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      final service = EntityActionService(
        taskRepository: taskRepo,
        projectRepository: projectRepo,
        valueRepository: valueRepo,
        allocationOrchestrator: allocation,
        occurrenceCommandService: occurrence,
      );

      await service.performAction(
        entityId: 't3',
        entityType: EntityType.task,
        action: EntityActionType.complete,
      );

      verify(
        () => occurrence.completeTask(
          taskId: 't3',
          occurrenceDate: null,
          originalOccurrenceDate: null,
          context: null,
        ),
      ).called(1);
    },
  );

  testSafe('pinTask forwards to allocation orchestrator', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final valueRepo = _MockValueRepo();
    final allocation = _MockAllocationOrchestrator();
    final occurrence = _MockOccurrenceCommandService();

    when(
      () => allocation.pinTask(
        any(),
        context: any(named: 'context'),
      ),
    ).thenAnswer((_) async {});

    final service = EntityActionService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      valueRepository: valueRepo,
      allocationOrchestrator: allocation,
      occurrenceCommandService: occurrence,
    );

    await service.pinTask('t9');

    verify(
      () => allocation.pinTask('t9', context: null),
    ).called(1);
  });

  testSafe('performAction move project throws UnsupportedError', () async {
    final taskRepo = _MockTaskRepo();
    final projectRepo = _MockProjectRepo();
    final valueRepo = _MockValueRepo();
    final allocation = _MockAllocationOrchestrator();
    final occurrence = _MockOccurrenceCommandService();

    when(
      () => projectRepo.getById('p1'),
    ).thenAnswer((_) async => buildProject(id: 'p1'));

    final service = EntityActionService(
      taskRepository: taskRepo,
      projectRepository: projectRepo,
      valueRepository: valueRepo,
      allocationOrchestrator: allocation,
      occurrenceCommandService: occurrence,
    );

    await expectLater(
      () => service.performAction(
        entityId: 'p1',
        entityType: EntityType.project,
        action: EntityActionType.move,
      ),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
