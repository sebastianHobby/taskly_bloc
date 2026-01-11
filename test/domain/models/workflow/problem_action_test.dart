import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/workflow/model/problem_action.dart';

void main() {
  group('ProblemAction', () {
    group('date actions', () {
      test('rescheduleToday creates correct action', () {
        const action = ProblemAction.rescheduleToday();

        expect(action, isA<RescheduleToday>());
        expect(action.label, 'Today');
        expect(action.iconName, 'today');
      });

      test('rescheduleTomorrow creates correct action', () {
        const action = ProblemAction.rescheduleTomorrow();

        expect(action, isA<RescheduleTomorrow>());
        expect(action.label, 'Tomorrow');
        expect(action.iconName, 'event');
      });

      test('rescheduleInDays creates action with days', () {
        const action = ProblemAction.rescheduleInDays(days: 7);

        expect(action, isA<RescheduleInDays>());
        expect((action as RescheduleInDays).days, 7);
        expect(action.label, 'In 7 days');
        expect(action.iconName, 'date_range');
      });

      test('pickDate creates correct action', () {
        const action = ProblemAction.pickDate();

        expect(action, isA<PickDate>());
        expect(action.label, 'Pick date...');
        expect(action.iconName, 'calendar_month');
      });

      test('clearDeadline creates correct action', () {
        const action = ProblemAction.clearDeadline();

        expect(action, isA<ClearDeadline>());
        expect(action.label, 'Clear deadline');
        expect(action.iconName, 'event_busy');
      });
    });

    group('value assignment actions', () {
      test('assignValue creates action with value info', () {
        const action = ProblemAction.assignValue(
          valueId: 'value-1',
          valueName: 'Health',
        );

        expect(action, isA<AssignValue>());
        expect((action as AssignValue).valueId, 'value-1');
        expect(action.valueName, 'Health');
        expect(action.label, 'Health');
        expect(action.iconName, 'label');
      });

      test('pickValue creates correct action', () {
        const action = ProblemAction.pickValue();

        expect(action, isA<PickValue>());
        expect(action.label, 'Pick value...');
        expect(action.iconName, 'label_outline');
      });
    });

    group('priority actions', () {
      test('lowerPriority creates correct action', () {
        const action = ProblemAction.lowerPriority();

        expect(action, isA<LowerPriority>());
        expect(action.label, 'Lower priority');
        expect(action.iconName, 'arrow_downward');
      });

      test('removePriority creates correct action', () {
        const action = ProblemAction.removePriority();

        expect(action, isA<RemovePriority>());
        expect(action.label, 'Remove priority');
        expect(action.iconName, 'remove_circle_outline');
      });
    });

    group('serialization', () {
      test('rescheduleToday round-trips through JSON', () {
        const original = ProblemAction.rescheduleToday();
        final json = original.toJson();
        final restored = ProblemAction.fromJson(json);

        expect(restored, isA<RescheduleToday>());
      });

      test('rescheduleInDays round-trips through JSON', () {
        const original = ProblemAction.rescheduleInDays(days: 5);
        final json = original.toJson();
        final restored = ProblemAction.fromJson(json);

        expect(restored, isA<RescheduleInDays>());
        expect((restored as RescheduleInDays).days, 5);
      });

      test('assignValue round-trips through JSON', () {
        const original = ProblemAction.assignValue(
          valueId: 'v-1',
          valueName: 'Work',
        );
        final json = original.toJson();
        final restored = ProblemAction.fromJson(json);

        expect(restored, isA<AssignValue>());
        expect((restored as AssignValue).valueId, 'v-1');
        expect(restored.valueName, 'Work');
      });
    });
  });
}
