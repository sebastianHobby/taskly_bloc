import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/screens/entity_selector.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_action.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_definition.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_type.dart';

void main() {
  group('ProblemDefinition', () {
    group('forType', () {
      test('returns definition for excludedUrgentTask', () {
        final definition = ProblemDefinition.forType(
          ProblemType.excludedUrgentTask,
        );

        expect(definition.type, ProblemType.excludedUrgentTask);
        expect(definition.title, 'Urgent Task Excluded');
        expect(definition.severity, ProblemSeverity.high);
        expect(definition.applicableEntityTypes, contains(EntityType.task));
        expect(definition.availableActions, isNotEmpty);
      });

      test('returns definition for overdueHighPriority', () {
        final definition = ProblemDefinition.forType(
          ProblemType.overdueHighPriority,
        );

        expect(definition.type, ProblemType.overdueHighPriority);
        expect(definition.title, 'Overdue Task');
        expect(definition.severity, ProblemSeverity.high);
        expect(definition.applicableEntityTypes, contains(EntityType.task));

        // Should include both date and priority actions
        expect(
          definition.availableActions,
          contains(const ProblemAction.rescheduleToday()),
        );
        expect(
          definition.availableActions,
          contains(const ProblemAction.lowerPriority()),
        );
      });

      test('returns definition for noNextActions', () {
        final definition = ProblemDefinition.forType(ProblemType.noNextActions);

        expect(definition.type, ProblemType.noNextActions);
        expect(definition.title, 'No Next Actions');
        expect(definition.severity, ProblemSeverity.medium);
        expect(
          definition.applicableEntityTypes,
          containsAll([EntityType.project, EntityType.label]),
        );
      });

      test('returns definition for unbalancedAllocation', () {
        final definition = ProblemDefinition.forType(
          ProblemType.unbalancedAllocation,
        );

        expect(definition.type, ProblemType.unbalancedAllocation);
        expect(definition.title, 'Unbalanced Allocation');
        expect(definition.severity, ProblemSeverity.low);
        expect(definition.applicableEntityTypes, contains(EntityType.label));
      });

      test('returns definition for staleTasks', () {
        final definition = ProblemDefinition.forType(ProblemType.staleTasks);

        expect(definition.type, ProblemType.staleTasks);
        expect(definition.title, 'Stale Item');
        expect(definition.severity, ProblemSeverity.low);
        expect(
          definition.applicableEntityTypes,
          containsAll([EntityType.task, EntityType.project]),
        );
      });
    });

    group('all', () {
      test('returns all problem definitions', () {
        final all = ProblemDefinition.all;

        expect(all.length, ProblemType.values.length);
        for (final type in ProblemType.values) {
          expect(all.any((d) => d.type == type), isTrue);
        }
      });
    });

    group('severity levels', () {
      test('high severity for urgent/overdue problems', () {
        expect(
          ProblemDefinition.forType(ProblemType.excludedUrgentTask).severity,
          ProblemSeverity.high,
        );
        expect(
          ProblemDefinition.forType(ProblemType.overdueHighPriority).severity,
          ProblemSeverity.high,
        );
      });

      test('medium severity for no-next-actions', () {
        expect(
          ProblemDefinition.forType(ProblemType.noNextActions).severity,
          ProblemSeverity.medium,
        );
      });

      test('low severity for allocation/stale problems', () {
        expect(
          ProblemDefinition.forType(ProblemType.unbalancedAllocation).severity,
          ProblemSeverity.low,
        );
        expect(
          ProblemDefinition.forType(ProblemType.staleTasks).severity,
          ProblemSeverity.low,
        );
      });
    });

    group('JSON serialization', () {
      test('serializes basic properties correctly', () {
        final original = ProblemDefinition.forType(
          ProblemType.excludedUrgentTask,
        );
        final json = original.toJson();

        expect(json['type'], 'excluded_urgent_task');
        expect(json['title'], 'Urgent Task Excluded');
        expect(json['severity'], 'high');
      });

      test('availableActions is present in serialization', () {
        final original = ProblemDefinition.forType(
          ProblemType.overdueHighPriority,
        );
        final json = original.toJson();

        // The availableActions should be serialized as a list
        expect(json['available_actions'], isNotNull);
        expect(json['available_actions'], isA<List>());
      });
    });
  });
}
