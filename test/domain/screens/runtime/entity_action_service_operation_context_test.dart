@Tags(['unit'])
library;

import 'package:mocktail/mocktail.dart';
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

  group('TaskWriteService (TG-006)', () {
    late MockTaskRepositoryContract taskRepository;
    late MockProjectRepositoryContract projectRepository;
    late MockAllocationOrchestrator allocationOrchestrator;
    late MockHomeDayKeyService dayKeyService;

    late TaskWriteService service;

    setUp(() {
      taskRepository = MockTaskRepositoryContract();
      projectRepository = MockProjectRepositoryContract();
      allocationOrchestrator = MockAllocationOrchestrator();
      dayKeyService = MockHomeDayKeyService();

      final occurrenceCommandService = OccurrenceCommandService(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        dayKeyService: dayKeyService,
      );

      service = TaskWriteService(
        taskRepository: taskRepository,
        projectRepository: projectRepository,
        allocationOrchestrator: allocationOrchestrator,
        occurrenceCommandService: occurrenceCommandService,
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
          feature: 'screen_actions',
          intent: 'task_completion_changed',
          operation: 'complete_occurrence',
          screen: 'screen_actions',
          entityType: 'task',
          entityId: 'task-1',
        );

        await service.complete(
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
      'forwards OperationContext into AllocationOrchestrator.pinTask',
      () async {
        final factory = TestOperationContextFactory(
          correlationIdPrefix: 'entity-action',
        );

        final created = factory.create(
          feature: 'screen_actions',
          intent: 'task_pinned_changed',
          operation: 'pin',
          screen: 'screen_actions',
          entityType: 'task',
          entityId: 'task-1',
        );

        await service.setPinned(
          'task-1',
          isPinned: true,
          context: created,
        );

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
