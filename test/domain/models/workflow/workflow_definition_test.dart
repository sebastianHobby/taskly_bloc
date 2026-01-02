import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  final now = DateTime(2025, 1, 15, 12);

  WorkflowStep createTestStep(String name) {
    return WorkflowStep(
      stepName: name,
      view: ViewDefinition.collection(
        selector: EntitySelector(entityType: EntityType.task),
        display: DisplayConfig(),
      ),
    );
  }

  group('WorkflowDefinition', () {
    group('construction', () {
      test('creates with required fields', () {
        final steps = [createTestStep('Step 1')];
        final definition = WorkflowDefinition(
          id: 'wf-def-1',
          name: 'Weekly Review',
          steps: steps,
          createdAt: now,
          updatedAt: now,
        );

        expect(definition.id, 'wf-def-1');
        expect(definition.name, 'Weekly Review');
        expect(definition.steps, steps);
        expect(definition.createdAt, now);
        expect(definition.updatedAt, now);
      });

      test('triggerConfig defaults to null', () {
        final definition = TestData.workflowDefinition();

        expect(definition.triggerConfig, isNull);
      });

      test('lastCompletedAt defaults to null', () {
        final definition = TestData.workflowDefinition();

        expect(definition.lastCompletedAt, isNull);
      });

      test('description defaults to null', () {
        final definition = TestData.workflowDefinition();

        expect(definition.description, isNull);
      });

      test('iconName defaults to null', () {
        final definition = TestData.workflowDefinition();

        expect(definition.iconName, isNull);
      });

      test('isSystem defaults to false', () {
        final definition = TestData.workflowDefinition();

        expect(definition.isSystem, false);
      });

      test('isActive defaults to true', () {
        final definition = TestData.workflowDefinition();

        expect(definition.isActive, true);
      });

      test('creates with all optional fields', () {
        final steps = [createTestStep('Step 1')];
        final trigger = TriggerConfig.schedule(rrule: 'FREQ=WEEKLY');
        final lastCompleted = DateTime(2025, 1, 10);

        final definition = WorkflowDefinition(
          id: 'wf-def-1',
          name: 'Weekly Review',
          steps: steps,
          createdAt: now,
          updatedAt: now,
          triggerConfig: trigger,
          lastCompletedAt: lastCompleted,
          description: 'Weekly review workflow',
          iconName: 'calendar',
          isSystem: true,
          isActive: false,
        );

        expect(definition.triggerConfig, trigger);
        expect(definition.lastCompletedAt, lastCompleted);
        expect(definition.description, 'Weekly review workflow');
        expect(definition.iconName, 'calendar');
        expect(definition.isSystem, true);
        expect(definition.isActive, false);
      });
    });

    group('steps', () {
      test('can have empty steps list', () {
        final definition = WorkflowDefinition(
          id: 'wf-def-1',
          name: 'Empty Workflow',
          steps: [],
          createdAt: now,
          updatedAt: now,
        );

        expect(definition.steps, isEmpty);
      });

      test('can have multiple steps', () {
        final steps = [
          createTestStep('Review Projects'),
          createTestStep('Review Tasks'),
          createTestStep('Plan Week'),
        ];
        final definition = WorkflowDefinition(
          id: 'wf-def-1',
          name: 'Weekly Review',
          steps: steps,
          createdAt: now,
          updatedAt: now,
        );

        expect(definition.steps, hasLength(3));
        expect(definition.steps[0].stepName, 'Review Projects');
        expect(definition.steps[1].stepName, 'Review Tasks');
        expect(definition.steps[2].stepName, 'Plan Week');
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final steps = [createTestStep('Step 1')];
        final def1 = WorkflowDefinition(
          id: 'wf-def-1',
          name: 'Weekly Review',
          steps: steps,
          createdAt: now,
          updatedAt: now,
        );
        final def2 = WorkflowDefinition(
          id: 'wf-def-1',
          name: 'Weekly Review',
          steps: steps,
          createdAt: now,
          updatedAt: now,
        );

        expect(def1, equals(def2));
        expect(def1.hashCode, equals(def2.hashCode));
      });

      test('not equal when id differs', () {
        final steps = [createTestStep('Step 1')];
        final def1 = WorkflowDefinition(
          id: 'wf-def-1',
          name: 'Weekly Review',
          steps: steps,
          createdAt: now,
          updatedAt: now,
        );
        final def2 = WorkflowDefinition(
          id: 'wf-def-2',
          name: 'Weekly Review',
          steps: steps,
          createdAt: now,
          updatedAt: now,
        );

        expect(def1, isNot(equals(def2)));
      });
    });

    group('copyWith', () {
      test('copies with new name', () {
        final definition = TestData.workflowDefinition(name: 'Old Name');
        final copied = definition.copyWith(name: 'New Name');

        expect(copied.name, 'New Name');
        expect(copied.id, definition.id);
      });

      test('copies with new isActive', () {
        final definition = TestData.workflowDefinition();
        final copied = definition.copyWith(isActive: false);

        expect(copied.isActive, false);
      });

      test('copies with new steps', () {
        final definition = TestData.workflowDefinition();
        final newSteps = [createTestStep('New Step')];
        final copied = definition.copyWith(steps: newSteps);

        expect(copied.steps, newSteps);
      });

      test('preserves unchanged fields', () {
        final definition = TestData.workflowDefinition(
          name: 'Test',
          description: 'Test description',
          iconName: 'star',
        );
        final copied = definition.copyWith(name: 'Changed');

        expect(copied.description, 'Test description');
        expect(copied.iconName, 'star');
      });
    });
  });

  group('TriggerConfig', () {
    group('TriggerConfig.schedule', () {
      test('creates with required rrule', () {
        final trigger = TriggerConfig.schedule(rrule: 'FREQ=WEEKLY;BYDAY=MO');

        expect(trigger, isA<ScheduleTrigger>());
        expect((trigger as ScheduleTrigger).rrule, 'FREQ=WEEKLY;BYDAY=MO');
      });

      test('nextTriggerDate defaults to null', () {
        final trigger = TriggerConfig.schedule(rrule: 'FREQ=DAILY');

        expect((trigger as ScheduleTrigger).nextTriggerDate, isNull);
      });

      test('creates with nextTriggerDate', () {
        final nextDate = DateTime(2025, 1, 20);
        final trigger = TriggerConfig.schedule(
          rrule: 'FREQ=WEEKLY',
          nextTriggerDate: nextDate,
        );

        expect((trigger as ScheduleTrigger).nextTriggerDate, nextDate);
      });
    });

    group('TriggerConfig.notReviewedSince', () {
      test('creates with required days', () {
        final trigger = TriggerConfig.notReviewedSince(days: 7);

        expect(trigger, isA<NotReviewedSinceTrigger>());
        expect((trigger as NotReviewedSinceTrigger).days, 7);
      });

      test('can create with different day values', () {
        final trigger1 = TriggerConfig.notReviewedSince(days: 1);
        final trigger30 = TriggerConfig.notReviewedSince(days: 30);

        expect((trigger1 as NotReviewedSinceTrigger).days, 1);
        expect((trigger30 as NotReviewedSinceTrigger).days, 30);
      });
    });

    group('TriggerConfig.manual', () {
      test('creates ManualTrigger', () {
        final trigger = TriggerConfig.manual();

        expect(trigger, isA<ManualTrigger>());
      });
    });

    group('pattern matching', () {
      test('can match on schedule', () {
        final trigger = TriggerConfig.schedule(rrule: 'FREQ=DAILY');

        final result = switch (trigger) {
          ScheduleTrigger() => 'schedule',
          NotReviewedSinceTrigger() => 'not_reviewed',
          ManualTrigger() => 'manual',
          _ => 'unknown',
        };

        expect(result, 'schedule');
      });

      test('can match on notReviewedSince', () {
        final trigger = TriggerConfig.notReviewedSince(days: 14);

        final result = switch (trigger) {
          ScheduleTrigger() => 'schedule',
          NotReviewedSinceTrigger() => 'not_reviewed',
          ManualTrigger() => 'manual',
          _ => 'unknown',
        };

        expect(result, 'not_reviewed');
      });

      test('can match on manual', () {
        final trigger = TriggerConfig.manual();

        final result = switch (trigger) {
          ScheduleTrigger() => 'schedule',
          NotReviewedSinceTrigger() => 'not_reviewed',
          ManualTrigger() => 'manual',
          _ => 'unknown',
        };

        expect(result, 'manual');
      });
    });
  });
}
