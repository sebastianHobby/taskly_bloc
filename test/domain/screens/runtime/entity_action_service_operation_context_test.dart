@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
import 'package:taskly_domain/services.dart';
import 'package:taskly_domain/allocation.dart';
import 'package:taskly_domain/taskly_domain.dart';

import '../../../helpers/operation_context_test_helpers.dart';
import '../../../helpers/test_environment.dart';
import '../../../helpers/test_imports.dart';
import '../../../mocks/repository_mocks.dart';

class MockAllocationOrchestrator extends Mock
    implements AllocationOrchestrator {}

class MockHomeDayKeyService extends Mock implements HomeDayKeyService {}

void main() {
  setUpAll(() {
    setUpAllTestEnvironment();

    // Needed for mocktail `any()` on non-primitive types.
    registerFallbackValue(
      OperationContext(
        correlationId: 'fallback-correlation-id',
        feature: 'fallback-feature',
        intent: 'fallback-intent',
        operation: 'fallback-operation',
      ),
    );
  });

  setUp(setUpTestEnvironment);

  group('EntityActionService (TG-006)', () {
    late MockTaskRepositoryContract taskRepository;
    late MockProjectRepositoryContract projectRepository;
    late MockValueRepositoryContract valueRepository;
    late MockAllocationOrchestrator allocationOrchestrator;
    late MockHomeDayKeyService dayKeyService;

    late EntityActionService service;

    setUp(() {
      taskRepository = MockTaskRepositoryContract();
      projectRepository = MockProjectRepositoryContract();
      valueRepository = MockValueRepositoryContract();
      allocationOrchestrator = MockAllocationOrchestrator();
      dayKeyService = MockHomeDayKeyService();

      service = EntityActionService(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        valueRepository: valueRepository,
        allocationOrchestrator: allocationOrchestrator,
        occurrenceCommandService: OccurrenceCommandService(
          taskRepository: taskRepository,
          projectRepository: projectRepository,
          dayKeyService: dayKeyService,
        ),
      );

      when(
        () => taskRepository.completeOccurrence(
          taskId: any(named: 'taskId'),
          occurrenceDate: any(named: 'occurrenceDate'),
          originalOccurrenceDate: any(named: 'originalOccurrenceDate'),
          notes: any(named: 'notes'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => taskRepository.uncompleteOccurrence(
          taskId: any(named: 'taskId'),
          occurrenceDate: any(named: 'occurrenceDate'),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});

      when(
        () => allocationOrchestrator.pinTask(
          any(),
          context: any(named: 'context'),
        ),
      ).thenAnswer((_) async {});
    });

    testSafe(
      'forwards OperationContext into TaskRepository.completeOccurrence',
      () async {
        final factory = TestOperationContextFactory(
          correlationIdPrefix: 'entity-action',
        );

        final created = factory.create(
          feature: 'usm',
          intent: 'task_completion_changed',
          operation: 'complete_occurrence',
          screen: 'screen_actions',
          entityType: 'task',
          entityId: 'task-1',
        );

        await service.completeTask(
          'task-1',
          occurrenceDate: DateTime.utc(2025, 1, 15),
          originalOccurrenceDate: DateTime.utc(2025, 1, 1),
          context: created,
        );

        final forwarded =
            verify(
                  () => taskRepository.completeOccurrence(
                    taskId: 'task-1',
                    occurrenceDate: any(named: 'occurrenceDate'),
                    originalOccurrenceDate: any(
                      named: 'originalOccurrenceDate',
                    ),
                    notes: any(named: 'notes'),
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expectOperationContextForwarded(created: created, forwarded: forwarded);
      },
    );

    testSafe(
      'forwards OperationContext into TaskRepository.uncompleteOccurrence',
      () async {
        final factory = TestOperationContextFactory(
          correlationIdPrefix: 'entity-action',
        );

        final created = factory.create(
          feature: 'usm',
          intent: 'task_completion_changed',
          operation: 'uncomplete_occurrence',
          screen: 'screen_actions',
          entityType: 'task',
          entityId: 'task-1',
        );

        await service.uncompleteTask(
          'task-1',
          occurrenceDate: DateTime.utc(2025, 1, 15),
          context: created,
        );

        final forwarded =
            verify(
                  () => taskRepository.uncompleteOccurrence(
                    taskId: 'task-1',
                    occurrenceDate: any(named: 'occurrenceDate'),
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expectOperationContextForwarded(created: created, forwarded: forwarded);
      },
    );

    testSafe(
      'forwards OperationContext into AllocationOrchestrator.pinTask',
      () async {
        final factory = TestOperationContextFactory(
          correlationIdPrefix: 'entity-action',
        );

        final created = factory.create(
          feature: 'usm',
          intent: 'task_pinned_changed',
          operation: 'pin',
          screen: 'screen_actions',
          entityType: 'task',
          entityId: 'task-1',
        );

        await service.pinTask('task-1', context: created);

        final forwarded =
            verify(
                  () => allocationOrchestrator.pinTask(
                    'task-1',
                    context: captureAny(named: 'context'),
                  ),
                ).captured.single
                as OperationContext?;

        expectOperationContextForwarded(created: created, forwarded: forwarded);
      },
    );
  });
}
