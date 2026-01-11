import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/workflow/model/workflow_step_state.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('WorkflowStepState', () {
    group('construction', () {
      test('creates with required stepIndex', () {
        final state = WorkflowStepState(stepIndex: 0);

        expect(state.stepIndex, 0);
      });

      test('reviewedEntityIds defaults to empty list', () {
        final state = WorkflowStepState(stepIndex: 0);

        expect(state.reviewedEntityIds, isEmpty);
      });

      test('skippedEntityIds defaults to empty list', () {
        final state = WorkflowStepState(stepIndex: 0);

        expect(state.skippedEntityIds, isEmpty);
      });

      test('pendingEntityIds defaults to empty list', () {
        final state = WorkflowStepState(stepIndex: 0);

        expect(state.pendingEntityIds, isEmpty);
      });

      test('creates with all fields', () {
        final state = WorkflowStepState(
          stepIndex: 2,
          reviewedEntityIds: ['task-1', 'task-2'],
          skippedEntityIds: ['task-3'],
          pendingEntityIds: ['task-4', 'task-5'],
        );

        expect(state.stepIndex, 2);
        expect(state.reviewedEntityIds, ['task-1', 'task-2']);
        expect(state.skippedEntityIds, ['task-3']);
        expect(state.pendingEntityIds, ['task-4', 'task-5']);
      });
    });

    group('stepIndex', () {
      test('can be 0 (first step)', () {
        final state = WorkflowStepState(stepIndex: 0);

        expect(state.stepIndex, 0);
      });

      test('can be large positive value', () {
        final state = WorkflowStepState(stepIndex: 100);

        expect(state.stepIndex, 100);
      });

      test('different step indices', () {
        final state0 = WorkflowStepState(stepIndex: 0);
        final state1 = WorkflowStepState(stepIndex: 1);
        final state5 = WorkflowStepState(stepIndex: 5);

        expect(state0.stepIndex, 0);
        expect(state1.stepIndex, 1);
        expect(state5.stepIndex, 5);
      });
    });

    group('entity tracking', () {
      test('tracks reviewed entities', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1', 'task-2', 'task-3'],
        );

        expect(state.reviewedEntityIds, hasLength(3));
        expect(state.reviewedEntityIds, contains('task-1'));
        expect(state.reviewedEntityIds, contains('task-2'));
        expect(state.reviewedEntityIds, contains('task-3'));
      });

      test('tracks skipped entities', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          skippedEntityIds: ['task-skipped-1'],
        );

        expect(state.skippedEntityIds, ['task-skipped-1']);
      });

      test('tracks pending entities', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          pendingEntityIds: ['task-pending-1', 'task-pending-2'],
        );

        expect(state.pendingEntityIds, hasLength(2));
      });

      test('entities can be in different lists', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1'],
          skippedEntityIds: ['task-2'],
          pendingEntityIds: ['task-3'],
        );

        expect(state.reviewedEntityIds, ['task-1']);
        expect(state.skippedEntityIds, ['task-2']);
        expect(state.pendingEntityIds, ['task-3']);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final state1 = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1'],
          skippedEntityIds: ['task-2'],
        );
        final state2 = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1'],
          skippedEntityIds: ['task-2'],
        );

        expect(state1, equals(state2));
        expect(state1.hashCode, equals(state2.hashCode));
      });

      test('not equal when stepIndex differs', () {
        final state1 = WorkflowStepState(stepIndex: 0);
        final state2 = WorkflowStepState(stepIndex: 1);

        expect(state1, isNot(equals(state2)));
      });

      test('not equal when reviewedEntityIds differ', () {
        final state1 = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1'],
        );
        final state2 = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-2'],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('not equal when skippedEntityIds differ', () {
        final state1 = WorkflowStepState(
          stepIndex: 0,
          skippedEntityIds: ['a'],
        );
        final state2 = WorkflowStepState(
          stepIndex: 0,
          skippedEntityIds: ['b'],
        );

        expect(state1, isNot(equals(state2)));
      });

      test('equal with empty lists', () {
        final state1 = WorkflowStepState(stepIndex: 0);
        final state2 = WorkflowStepState(stepIndex: 0);

        expect(state1, equals(state2));
      });
    });

    group('copyWith', () {
      test('copies with new stepIndex', () {
        final state = TestData.workflowStepState();
        final copied = state.copyWith(stepIndex: 5);

        expect(copied.stepIndex, 5);
      });

      test('copies with new reviewedEntityIds', () {
        final state = WorkflowStepState(stepIndex: 0);
        final copied = state.copyWith(reviewedEntityIds: ['task-1', 'task-2']);

        expect(copied.reviewedEntityIds, ['task-1', 'task-2']);
      });

      test('copies with new skippedEntityIds', () {
        final state = WorkflowStepState(stepIndex: 0);
        final copied = state.copyWith(skippedEntityIds: ['skipped']);

        expect(copied.skippedEntityIds, ['skipped']);
      });

      test('copies with new pendingEntityIds', () {
        final state = WorkflowStepState(stepIndex: 0);
        final copied = state.copyWith(pendingEntityIds: ['pending-1']);

        expect(copied.pendingEntityIds, ['pending-1']);
      });

      test('preserves unchanged fields', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['reviewed'],
          skippedEntityIds: ['skipped'],
          pendingEntityIds: ['pending'],
        );
        final copied = state.copyWith(stepIndex: 1);

        expect(copied.reviewedEntityIds, ['reviewed']);
        expect(copied.skippedEntityIds, ['skipped']);
        expect(copied.pendingEntityIds, ['pending']);
      });

      test('can clear entity lists', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1', 'task-2'],
        );
        final copied = state.copyWith(reviewedEntityIds: []);

        expect(copied.reviewedEntityIds, isEmpty);
      });
    });

    group('progress tracking scenarios', () {
      test('initial state for a new step', () {
        final state = WorkflowStepState(stepIndex: 0);

        expect(state.reviewedEntityIds, isEmpty);
        expect(state.skippedEntityIds, isEmpty);
        expect(state.pendingEntityIds, isEmpty);
      });

      test('partially completed step', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1', 'task-2'],
          pendingEntityIds: ['task-3', 'task-4'],
        );

        expect(state.reviewedEntityIds, hasLength(2));
        expect(state.pendingEntityIds, hasLength(2));
      });

      test('fully completed step', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1', 'task-2', 'task-3'],
        );

        expect(state.reviewedEntityIds, hasLength(3));
        expect(state.skippedEntityIds, isEmpty);
        expect(state.pendingEntityIds, isEmpty);
      });

      test('step with mixed actions', () {
        final state = WorkflowStepState(
          stepIndex: 0,
          reviewedEntityIds: ['task-1'],
          skippedEntityIds: ['task-2'],
          pendingEntityIds: ['task-3'],
        );

        // Total entities = 3, all accounted for
        final totalTracked =
            state.reviewedEntityIds.length +
            state.skippedEntityIds.length +
            state.pendingEntityIds.length;
        expect(totalTracked, 3);
      });
    });
  });
}
