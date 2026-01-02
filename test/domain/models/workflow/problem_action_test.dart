import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/workflow/problem_action.dart';

void main() {
  group('ProblemAction', () {
    group('date actions', () {
      test('rescheduleToday has correct label', () {
        const action = ProblemAction.rescheduleToday();
        expect(action.label, 'Today');
        expect(action.iconName, 'today');
      });

      test('rescheduleTomorrow has correct label', () {
        const action = ProblemAction.rescheduleTomorrow();
        expect(action.label, 'Tomorrow');
        expect(action.iconName, 'event');
      });

      test('rescheduleInDays formats label with days', () {
        const action = ProblemAction.rescheduleInDays(days: 3);
        expect(action.label, 'In 3 days');
        expect(action.iconName, 'date_range');
      });

      test('pickDate has correct label', () {
        const action = ProblemAction.pickDate();
        expect(action.label, 'Pick date...');
        expect(action.iconName, 'calendar_month');
      });

      test('clearDeadline has correct label', () {
        const action = ProblemAction.clearDeadline();
        expect(action.label, 'Clear deadline');
        expect(action.iconName, 'event_busy');
      });
    });

    group('value actions', () {
      test('assignValue formats label with value name', () {
        const action = ProblemAction.assignValue(
          valueId: 'v1',
          valueName: 'Work',
        );
        expect(action.label, 'Work');
        expect(action.iconName, 'label');
      });

      test('pickValue has correct label', () {
        const action = ProblemAction.pickValue();
        expect(action.label, 'Pick value...');
        expect(action.iconName, 'label_outline');
      });
    });

    group('priority actions', () {
      test('lowerPriority has correct label', () {
        const action = ProblemAction.lowerPriority();
        expect(action.label, 'Lower priority');
        expect(action.iconName, 'arrow_downward');
      });

      test('removePriority has correct label', () {
        const action = ProblemAction.removePriority();
        expect(action.label, 'Remove priority');
        expect(action.iconName, 'remove_circle_outline');
      });
    });

    group('JSON serialization', () {
      test('rescheduleToday serializes correctly', () {
        const action = ProblemAction.rescheduleToday();
        final json = action.toJson();
        expect(json['type'], 'reschedule_today');
      });

      test('rescheduleInDays serializes with days field', () {
        const action = ProblemAction.rescheduleInDays(days: 7);
        final json = action.toJson();
        expect(json['type'], 'reschedule_in_days');
        expect(json['days'], 7);
      });

      test('assignValue serializes with value fields', () {
        const action = ProblemAction.assignValue(
          valueId: 'v1',
          valueName: 'Health',
        );
        final json = action.toJson();
        expect(json['type'], 'assign_value');
        expect(json['value_id'], 'v1');
        expect(json['value_name'], 'Health');
      });

      test('roundtrip serialization works', () {
        const original = ProblemAction.rescheduleInDays(days: 5);
        final json = original.toJson();
        final restored = ProblemAction.fromJson(json);
        expect(restored, original);
      });
    });
  });
}
