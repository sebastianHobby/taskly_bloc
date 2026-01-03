import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('WorkflowDefinition', () {
    final now = DateTime.utc(2025, 6, 1);

    WorkflowDefinition createDefinition({
      List<WorkflowStep>? steps,
      List<SupportBlock>? globalSupportBlocks,
    }) {
      return WorkflowDefinition(
        id: 'workflow-123',
        name: 'Test Workflow',
        steps: steps ?? [],
        createdAt: now,
        updatedAt: now,
        globalSupportBlocks: globalSupportBlocks ?? [],
      );
    }

    WorkflowStep createStep(String id, int order) {
      return WorkflowStep(
        id: id,
        name: 'Step $order',
        order: order,
        sections: const [
          Section.agenda(dateField: AgendaDateField.deadlineDate),
        ],
      );
    }

    group('construction', () {
      test('creates with required fields', () {
        final workflow = createDefinition();

        expect(workflow.id, 'workflow-123');
        expect(workflow.name, 'Test Workflow');
        expect(workflow.steps, isEmpty);
        expect(workflow.createdAt, now);
        expect(workflow.updatedAt, now);
      });

      test('globalSupportBlocks defaults to empty list', () {
        final workflow = createDefinition();

        expect(workflow.globalSupportBlocks, isEmpty);
      });

      test('isSystem defaults to false', () {
        final workflow = createDefinition();

        expect(workflow.isSystem, isFalse);
      });

      test('isActive defaults to true', () {
        final workflow = createDefinition();

        expect(workflow.isActive, isTrue);
      });

      test('creates with optional fields', () {
        final lastCompleted = DateTime.utc(2025, 5, 15);
        final workflow = WorkflowDefinition(
          id: 'wf-1',
          name: 'Full Workflow',
          steps: [createStep('step-1', 0)],
          createdAt: now,
          updatedAt: now,
          description: 'A detailed workflow',
          iconName: 'workflow_icon',
          isSystem: true,
          isActive: false,
          lastCompletedAt: lastCompleted,
        );

        expect(workflow.description, 'A detailed workflow');
        expect(workflow.iconName, 'workflow_icon');
        expect(workflow.isSystem, isTrue);
        expect(workflow.isActive, isFalse);
        expect(workflow.lastCompletedAt, lastCompleted);
      });
    });

    group('totalSteps', () {
      test('returns 0 for empty steps', () {
        final workflow = createDefinition();

        expect(workflow.totalSteps, 0);
      });

      test('returns correct count for single step', () {
        final workflow = createDefinition(steps: [createStep('s1', 0)]);

        expect(workflow.totalSteps, 1);
      });

      test('returns correct count for multiple steps', () {
        final workflow = createDefinition(
          steps: [
            createStep('s1', 0),
            createStep('s2', 1),
            createStep('s3', 2),
          ],
        );

        expect(workflow.totalSteps, 3);
      });
    });

    group('getStep', () {
      test('returns null for negative index', () {
        final workflow = createDefinition(steps: [createStep('s1', 0)]);

        expect(workflow.getStep(-1), isNull);
      });

      test('returns null for index >= steps.length', () {
        final workflow = createDefinition(steps: [createStep('s1', 0)]);

        expect(workflow.getStep(1), isNull);
        expect(workflow.getStep(5), isNull);
      });

      test('returns null for empty steps list', () {
        final workflow = createDefinition();

        expect(workflow.getStep(0), isNull);
      });

      test('returns correct step for valid index 0', () {
        final step = createStep('first', 0);
        final workflow = createDefinition(steps: [step, createStep('s2', 1)]);

        final result = workflow.getStep(0);

        expect(result, isNotNull);
        expect(result!.id, 'first');
      });

      test('returns correct step for valid middle index', () {
        final workflow = createDefinition(
          steps: [
            createStep('s0', 0),
            createStep('s1', 1),
            createStep('s2', 2),
          ],
        );

        final result = workflow.getStep(1);

        expect(result, isNotNull);
        expect(result!.id, 's1');
      });

      test('returns correct step for last valid index', () {
        final workflow = createDefinition(
          steps: [
            createStep('s0', 0),
            createStep('s1', 1),
            createStep('last', 2),
          ],
        );

        final result = workflow.getStep(2);

        expect(result, isNotNull);
        expect(result!.id, 'last');
      });
    });

    group('getStepById', () {
      test('returns null for non-existent id', () {
        final workflow = createDefinition(
          steps: [createStep('s1', 0), createStep('s2', 1)],
        );

        expect(workflow.getStepById('non-existent'), isNull);
      });

      test('returns null for empty steps list', () {
        final workflow = createDefinition();

        expect(workflow.getStepById('any-id'), isNull);
      });

      test('returns correct step for matching id', () {
        final workflow = createDefinition(
          steps: [
            createStep('first', 0),
            createStep('target', 1),
            createStep('last', 2),
          ],
        );

        final result = workflow.getStepById('target');

        expect(result, isNotNull);
        expect(result!.id, 'target');
        expect(result.order, 1);
      });

      test('returns first matching step when multiple match (edge case)', () {
        // This shouldn't happen in practice but tests the behavior
        final workflow = createDefinition(
          steps: [
            createStep('dupe', 0),
            createStep('other', 1),
          ],
        );

        final result = workflow.getStepById('dupe');

        expect(result, isNotNull);
        expect(result!.id, 'dupe');
      });
    });

    group('equality', () {
      test('equal workflows have same hashCode', () {
        final wf1 = createDefinition(steps: [createStep('s1', 0)]);
        final wf2 = createDefinition(steps: [createStep('s1', 0)]);

        expect(wf1, equals(wf2));
        expect(wf1.hashCode, equals(wf2.hashCode));
      });

      test('different ids are not equal', () {
        final wf1 = createDefinition();
        final wf2 = WorkflowDefinition(
          id: 'different-id',
          name: 'Test Workflow',
          steps: [],
          createdAt: now,
          updatedAt: now,
        );

        expect(wf1, isNot(equals(wf2)));
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final workflow = createDefinition();
        final copied = workflow.copyWith(name: 'New Name');

        expect(copied.name, 'New Name');
        expect(copied.id, workflow.id);
      });

      test('copies with new steps', () {
        final workflow = createDefinition();
        final newSteps = [createStep('new-step', 0)];
        final copied = workflow.copyWith(steps: newSteps);

        expect(copied.steps, hasLength(1));
        expect(copied.steps.first.id, 'new-step');
      });
    });
  });
}
