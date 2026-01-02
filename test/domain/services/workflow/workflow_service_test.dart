import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow.dart';
import 'package:taskly_bloc/domain/services/workflow/workflow_service.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';
import '../../../helpers/test_helpers.dart';
import '../../../mocks/fake_repositories.dart';
import '../../../mocks/feature_mocks.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  late WorkflowService workflowService;
  late FakeWorkflowRepository workflowRepo;
  late MockViewService mockViewService;

  setUp(() {
    workflowRepo = FakeWorkflowRepository();
    mockViewService = MockViewService();
    workflowService = WorkflowService(
      workflowRepository: workflowRepo,
      viewService: mockViewService,
    );
  });

  group('WorkflowService', () {
    group('startWorkflow', () {
      test('creates a new workflow from definition', () async {
        final definition = TestData.workflowDefinition(
          id: 'def-1',
          steps: [
            TestData.workflowStep(stepName: 'Step 1'),
            TestData.workflowStep(stepName: 'Step 2'),
          ],
        );

        final workflow = await workflowService.startWorkflow(
          definition: definition,
        );

        expect(workflow.id, isNotEmpty);
        expect(workflow.workflowDefinitionId, 'def-1');
        expect(workflow.status, WorkflowStatus.inProgress);
        expect(workflow.stepStates, hasLength(2));
        expect(workflow.currentStepIndex, 0);
      });

      test('creates step states for each step in definition', () async {
        final definition = TestData.workflowDefinition(
          steps: [
            TestData.workflowStep(stepName: 'Step 1'),
            TestData.workflowStep(stepName: 'Step 2'),
            TestData.workflowStep(stepName: 'Step 3'),
          ],
        );

        final workflow = await workflowService.startWorkflow(
          definition: definition,
        );

        expect(workflow.stepStates, hasLength(3));
        expect(workflow.stepStates[0].stepIndex, 0);
        expect(workflow.stepStates[1].stepIndex, 1);
        expect(workflow.stepStates[2].stepIndex, 2);
      });
    });

    group('watchWorkflow', () {
      test('returns stream from repository', () async {
        final workflow = TestData.workflow(id: 'workflow-1');
        workflowRepo.pushWorkflows([workflow]);

        final result = await workflowService
            .watchWorkflow('workflow-1')
            .first
            .timeout(kDefaultStreamTimeout);

        expect(result.id, 'workflow-1');
      });
    });

    group('getCurrentStep', () {
      test('returns step at current index', () {
        final step1 = TestData.workflowStep(stepName: 'Step 1');
        final step2 = TestData.workflowStep(stepName: 'Step 2');
        final definition = TestData.workflowDefinition(steps: [step1, step2]);
        final workflow = TestData.workflow(currentStepIndex: 1);

        final result = workflowService.getCurrentStep(definition, workflow);

        expect(result.stepName, 'Step 2');
      });

      test('throws when step index out of bounds', () {
        final definition = TestData.workflowDefinition(
          steps: [TestData.workflowStep(stepName: 'Step 1')],
        );
        final workflow = TestData.workflow(currentStepIndex: 5);

        expect(
          () => workflowService.getCurrentStep(definition, workflow),
          throwsStateError,
        );
      });
    });

    group('getCurrentStepState', () {
      test('returns step state at current index', () {
        final workflow = TestData.workflow(
          currentStepIndex: 1,
          stepStates: [
            TestData.workflowStepState(),
            TestData.workflowStepState(
              stepIndex: 1,
              reviewedEntityIds: ['entity-1'],
            ),
          ],
        );

        final result = workflowService.getCurrentStepState(workflow);

        expect(result.stepIndex, 1);
        expect(result.reviewedEntityIds, ['entity-1']);
      });

      test('throws when step state index out of bounds', () {
        final workflow = TestData.workflow(
          currentStepIndex: 5,
          stepStates: [TestData.workflowStepState()],
        );

        expect(
          () => workflowService.getCurrentStepState(workflow),
          throwsStateError,
        );
      });
    });

    group('markEntityReviewed', () {
      test('adds entity to reviewed list', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
          stepStates: [
            TestData.workflowStepState(),
          ],
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.markEntityReviewed(
          workflow: workflow,
          entityId: 'entity-1',
        );

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(updated!.stepStates[0].reviewedEntityIds, contains('entity-1'));
      });

      test('removes entity from pending list', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
          stepStates: [
            TestData.workflowStepState(
              pendingEntityIds: ['entity-1', 'entity-2'],
            ),
          ],
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.markEntityReviewed(
          workflow: workflow,
          entityId: 'entity-1',
        );

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(
          updated!.stepStates[0].pendingEntityIds,
          isNot(contains('entity-1')),
        );
        expect(updated.stepStates[0].pendingEntityIds, contains('entity-2'));
      });
    });

    group('skipEntity', () {
      test('adds entity to skipped list', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
          stepStates: [
            TestData.workflowStepState(),
          ],
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.skipEntity(
          workflow: workflow,
          entityId: 'entity-1',
        );

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(updated!.stepStates[0].skippedEntityIds, contains('entity-1'));
      });

      test('removes entity from pending list', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
          stepStates: [
            TestData.workflowStepState(
              pendingEntityIds: ['entity-1', 'entity-2'],
            ),
          ],
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.skipEntity(
          workflow: workflow,
          entityId: 'entity-1',
        );

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(
          updated!.stepStates[0].pendingEntityIds,
          isNot(contains('entity-1')),
        );
        expect(updated.stepStates[0].pendingEntityIds, contains('entity-2'));
      });
    });

    group('advanceToNextStep', () {
      test('increments current step index', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.advanceToNextStep(workflow);

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(updated!.currentStepIndex, 1);
      });

      test('preserves step states when advancing', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
          stepStates: [
            TestData.workflowStepState(
              reviewedEntityIds: ['entity-1'],
            ),
            TestData.workflowStepState(stepIndex: 1),
          ],
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.advanceToNextStep(workflow);

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(
          updated!.stepStates[0].reviewedEntityIds,
          contains('entity-1'),
        );
      });
    });

    group('completeWorkflow', () {
      test('sets status to completed', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.completeWorkflow(workflow);

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(updated!.status, WorkflowStatus.completed);
      });

      test('sets completedAt timestamp', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.completeWorkflow(workflow);

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(updated!.completedAt, isNotNull);
      });
    });

    group('abandonWorkflow', () {
      test('sets status to abandoned', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.abandonWorkflow(workflow);

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(updated!.status, WorkflowStatus.abandoned);
      });

      test('preserves step states when abandoning', () async {
        final workflow = TestData.workflow(
          id: 'workflow-1',
          stepStates: [
            TestData.workflowStepState(
              reviewedEntityIds: ['entity-1'],
            ),
          ],
        );
        workflowRepo.pushWorkflows([workflow]);

        await workflowService.abandonWorkflow(workflow);

        final updated = await workflowRepo.getWorkflow('workflow-1');
        expect(
          updated!.stepStates[0].reviewedEntityIds,
          contains('entity-1'),
        );
      });
    });

    group('isCurrentStepComplete', () {
      test('returns true when all entities processed', () {
        final workflow = TestData.workflow(
          stepStates: [
            TestData.workflowStepState(
              reviewedEntityIds: ['entity-1', 'entity-2'],
              skippedEntityIds: ['entity-3'],
            ),
          ],
        );

        final result = workflowService.isCurrentStepComplete(workflow, 3);

        expect(result, isTrue);
      });

      test('returns false when entities remain', () {
        final workflow = TestData.workflow(
          stepStates: [
            TestData.workflowStepState(
              reviewedEntityIds: ['entity-1'],
            ),
          ],
        );

        final result = workflowService.isCurrentStepComplete(workflow, 3);

        expect(result, isFalse);
      });

      test('counts both reviewed and skipped entities', () {
        final workflow = TestData.workflow(
          stepStates: [
            TestData.workflowStepState(
              reviewedEntityIds: ['entity-1'],
              skippedEntityIds: ['entity-2'],
            ),
          ],
        );

        final result = workflowService.isCurrentStepComplete(workflow, 2);

        expect(result, isTrue);
      });
    });

    group('isWorkflowComplete', () {
      test('returns true when current step exceeds definition steps', () {
        final definition = TestData.workflowDefinition(
          steps: [
            TestData.workflowStep(stepName: 'Step 1'),
            TestData.workflowStep(stepName: 'Step 2'),
          ],
        );
        final workflow = TestData.workflow(currentStepIndex: 2);

        final result = workflowService.isWorkflowComplete(definition, workflow);

        expect(result, isTrue);
      });

      test('returns false when steps remain', () {
        final definition = TestData.workflowDefinition(
          steps: [
            TestData.workflowStep(stepName: 'Step 1'),
            TestData.workflowStep(stepName: 'Step 2'),
          ],
        );
        final workflow = TestData.workflow(currentStepIndex: 1);

        final result = workflowService.isWorkflowComplete(definition, workflow);

        expect(result, isFalse);
      });
    });
  });
}
