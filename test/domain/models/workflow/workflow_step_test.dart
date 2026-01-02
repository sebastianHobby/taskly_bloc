import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/screens/view_definition.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  ViewDefinition createTestView() {
    return ViewDefinition.collection(
      selector: EntitySelector(entityType: EntityType.task),
      display: DisplayConfig(),
    );
  }

  group('WorkflowStep', () {
    group('construction', () {
      test('creates with required fields', () {
        final view = createTestView();
        final step = WorkflowStep(
          stepName: 'Review Tasks',
          view: view,
        );

        expect(step.stepName, 'Review Tasks');
        expect(step.view, view);
      });

      test('creates with collection view', () {
        final step = TestData.workflowStep(stepName: 'Collection Step');

        expect(step.view, isA<CollectionView>());
      });

      test('creates with agenda view', () {
        final agendaView = ViewDefinition.agenda(
          selector: EntitySelector(entityType: EntityType.task),
          display: DisplayConfig(),
          agendaConfig: AgendaConfig(
            dateField: DateField.deadlineDate,
            groupingStrategy: AgendaGrouping.today,
          ),
        );
        final step = WorkflowStep(
          stepName: 'Today Review',
          view: agendaView,
        );

        expect(step.view, isA<AgendaView>());
      });

      test('creates with detail view', () {
        final detailView = ViewDefinition.detail(
          parentType: DetailParentType.project,
        );
        final step = WorkflowStep(
          stepName: 'Project Detail',
          view: detailView,
        );

        expect(step.view, isA<DetailView>());
      });

      test('creates with allocated view', () {
        final allocatedView = ViewDefinition.allocated(
          selector: EntitySelector(entityType: EntityType.task),
          display: DisplayConfig(),
        );
        final step = WorkflowStep(
          stepName: 'Allocated Tasks',
          view: allocatedView,
        );

        expect(step.view, isA<AllocatedView>());
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final view = createTestView();
        final step1 = WorkflowStep(
          stepName: 'Review',
          view: view,
        );
        final step2 = WorkflowStep(
          stepName: 'Review',
          view: view,
        );

        expect(step1, equals(step2));
        expect(step1.hashCode, equals(step2.hashCode));
      });

      test('not equal when stepName differs', () {
        final view = createTestView();
        final step1 = WorkflowStep(
          stepName: 'Review Tasks',
          view: view,
        );
        final step2 = WorkflowStep(
          stepName: 'Review Projects',
          view: view,
        );

        expect(step1, isNot(equals(step2)));
      });

      test('not equal when view differs', () {
        final view1 = ViewDefinition.collection(
          selector: EntitySelector(entityType: EntityType.task),
          display: DisplayConfig(),
        );
        final view2 = ViewDefinition.collection(
          selector: EntitySelector(entityType: EntityType.project),
          display: DisplayConfig(),
        );
        final step1 = WorkflowStep(stepName: 'Review', view: view1);
        final step2 = WorkflowStep(stepName: 'Review', view: view2);

        expect(step1, isNot(equals(step2)));
      });
    });

    group('copyWith', () {
      test('copies with new stepName', () {
        final step = TestData.workflowStep(stepName: 'Original');
        final copied = step.copyWith(stepName: 'Changed');

        expect(copied.stepName, 'Changed');
      });

      test('copies with new view', () {
        final step = TestData.workflowStep();
        final newView = ViewDefinition.detail(
          parentType: DetailParentType.label,
        );
        final copied = step.copyWith(view: newView);

        expect(copied.view, newView);
        expect(copied.view, isA<DetailView>());
      });

      test('preserves unchanged fields', () {
        final view = createTestView();
        final step = WorkflowStep(
          stepName: 'Original',
          view: view,
        );
        final copied = step.copyWith(stepName: 'Changed');

        expect(copied.view, view);
      });
    });

    group('step name variations', () {
      test('handles empty step name', () {
        final step = WorkflowStep(
          stepName: '',
          view: createTestView(),
        );

        expect(step.stepName, '');
      });

      test('handles long step name', () {
        const longName =
            'This is a very long step name that describes '
            'the detailed process of reviewing all tasks';
        final step = WorkflowStep(
          stepName: longName,
          view: createTestView(),
        );

        expect(step.stepName, longName);
      });

      test('handles step name with special characters', () {
        final step = WorkflowStep(
          stepName: 'Review 📋 Tasks (Weekly)',
          view: createTestView(),
        );

        expect(step.stepName, 'Review 📋 Tasks (Weekly)');
      });
    });
  });
}
