import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_step_state.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  final now = DateTime(2025, 1, 15, 12);

  group('WorkflowStatus', () {
    test('inProgress has correct value', () {
      expect(WorkflowStatus.inProgress.name, 'inProgress');
    });

    test('completed has correct value', () {
      expect(WorkflowStatus.completed.name, 'completed');
    });

    test('abandoned has correct value', () {
      expect(WorkflowStatus.abandoned.name, 'abandoned');
    });

    test('enum has 3 values', () {
      expect(WorkflowStatus.values, hasLength(3));
    });
  });

  group('Workflow', () {
    group('construction', () {
      test('creates with required fields', () {
        final stepStates = [WorkflowStepState(stepIndex: 0)];
        final workflow = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        );

        expect(workflow.id, 'wf-1');
        expect(workflow.workflowDefinitionId, 'wf-def-1');
        expect(workflow.status, WorkflowStatus.inProgress);
        expect(workflow.stepStates, stepStates);
        expect(workflow.createdAt, now);
        expect(workflow.updatedAt, now);
      });

      test('completedAt defaults to null', () {
        final workflow = TestData.workflow();

        expect(workflow.completedAt, isNull);
      });

      test('currentStepIndex defaults to 0', () {
        final workflow = TestData.workflow();

        expect(workflow.currentStepIndex, 0);
      });

      test('creates with all optional fields', () {
        final completedAt = DateTime(2025, 1, 16);
        final workflow = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.completed,
          stepStates: [WorkflowStepState(stepIndex: 0)],
          createdAt: now,
          updatedAt: now,
          completedAt: completedAt,
          currentStepIndex: 3,
        );

        expect(workflow.completedAt, completedAt);
        expect(workflow.currentStepIndex, 3);
      });
    });

    group('stepStates', () {
      test('can have empty stepStates list', () {
        final workflow = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: [],
          createdAt: now,
          updatedAt: now,
        );

        expect(workflow.stepStates, isEmpty);
      });

      test('can have multiple stepStates', () {
        final stepStates = [
          WorkflowStepState(stepIndex: 0, reviewedEntityIds: ['task-1']),
          WorkflowStepState(stepIndex: 1),
          WorkflowStepState(stepIndex: 2),
        ];
        final workflow = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        );

        expect(workflow.stepStates, hasLength(3));
        expect(workflow.stepStates[0].stepIndex, 0);
        expect(workflow.stepStates[0].reviewedEntityIds, ['task-1']);
      });
    });

    group('status transitions', () {
      test('inProgress workflow', () {
        final workflow = TestData.workflow();

        expect(workflow.status, WorkflowStatus.inProgress);
        expect(workflow.completedAt, isNull);
      });

      test('completed workflow has completedAt', () {
        final completedAt = DateTime(2025, 1, 16);
        final workflow = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.completed,
          stepStates: [WorkflowStepState(stepIndex: 0)],
          createdAt: now,
          updatedAt: now,
          completedAt: completedAt,
        );

        expect(workflow.status, WorkflowStatus.completed);
        expect(workflow.completedAt, completedAt);
      });

      test('abandoned workflow', () {
        final workflow = TestData.workflow(status: WorkflowStatus.abandoned);

        expect(workflow.status, WorkflowStatus.abandoned);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final stepStates = [WorkflowStepState(stepIndex: 0)];
        final wf1 = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        );
        final wf2 = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        );

        expect(wf1, equals(wf2));
        expect(wf1.hashCode, equals(wf2.hashCode));
      });

      test('not equal when id differs', () {
        final stepStates = [WorkflowStepState(stepIndex: 0)];
        final wf1 = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        );
        final wf2 = Workflow(
          id: 'wf-2',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        );

        expect(wf1, isNot(equals(wf2)));
      });

      test('not equal when status differs', () {
        final stepStates = [WorkflowStepState(stepIndex: 0)];
        final wf1 = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        );
        final wf2 = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.completed,
          stepStates: stepStates,
          createdAt: now,
          updatedAt: now,
        );

        expect(wf1, isNot(equals(wf2)));
      });
    });

    group('copyWith', () {
      test('copies with new status', () {
        final workflow = TestData.workflow();
        final copied = workflow.copyWith(status: WorkflowStatus.completed);

        expect(copied.status, WorkflowStatus.completed);
        expect(copied.id, workflow.id);
      });

      test('copies with new currentStepIndex', () {
        final workflow = TestData.workflow();
        final copied = workflow.copyWith(currentStepIndex: 2);

        expect(copied.currentStepIndex, 2);
      });

      test('copies with new completedAt', () {
        final workflow = TestData.workflow();
        final completedAt = DateTime(2025, 1, 20);
        final copied = workflow.copyWith(completedAt: completedAt);

        expect(copied.completedAt, completedAt);
      });

      test('copies with new stepStates', () {
        final workflow = TestData.workflow();
        final newStepStates = [
          WorkflowStepState(stepIndex: 0, reviewedEntityIds: ['task-1']),
        ];
        final copied = workflow.copyWith(stepStates: newStepStates);

        expect(copied.stepStates, newStepStates);
      });

      test('preserves unchanged fields', () {
        final workflow = Workflow(
          id: 'wf-1',
          workflowDefinitionId: 'wf-def-1',
          status: WorkflowStatus.inProgress,
          stepStates: [WorkflowStepState(stepIndex: 0)],
          createdAt: now,
          updatedAt: now,
          currentStepIndex: 1,
        );
        final copied = workflow.copyWith(status: WorkflowStatus.completed);

        expect(copied.workflowDefinitionId, 'wf-def-1');
        expect(copied.currentStepIndex, 1);
      });
    });
  });
}
