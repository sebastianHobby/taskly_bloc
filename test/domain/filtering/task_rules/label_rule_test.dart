import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/models/label.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('LabelRule', () {
    final today = DateTime(2025, 6, 15);
    final context = EvaluationContext(today: today);

    // Helper to create labels
    Label createLabel(String id, {LabelType type = LabelType.label}) {
      return TestData.label(id: id, name: 'Label $id', type: type);
    }

    group('construction', () {
      test('creates with required fields', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1', 'label-2'],
        );

        expect(rule.operator, LabelRuleOperator.hasAny);
        expect(rule.labelIds, ['label-1', 'label-2']);
        expect(rule.labelType, LabelType.label);
        expect(rule.type, RuleType.labels);
      });

      test('creates with value label type', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['value-1'],
          labelType: LabelType.value,
        );

        expect(rule.labelType, LabelType.value);
      });

      test('defaults labelIds to empty list', () {
        final rule = TestData.labelRule();

        expect(rule.labelIds, isEmpty);
      });
    });

    group('evaluate - hasAny operator', () {
      test('matches task with any of the specified labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1', 'label-2'],
        );
        final task = TestData.task(
          labels: [createLabel('label-1'), createLabel('label-3')],
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches task with multiple matching labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1', 'label-2'],
        );
        final task = TestData.task(
          labels: [createLabel('label-1'), createLabel('label-2')],
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task without any of the labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1', 'label-2'],
        );
        final task = TestData.task(
          labels: [createLabel('label-3'), createLabel('label-4')],
        );

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with no labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1'],
        );
        final task = TestData.task(labels: []);

        expect(rule.evaluate(task, context), isFalse);
      });

      test('returns false when labelIds is empty', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: [],
        );
        final task = TestData.task(labels: [createLabel('label-1')]);

        expect(rule.evaluate(task, context), isFalse);
      });

      test('ignores empty string labelIds', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['', '  ', 'label-1'],
        );
        final task = TestData.task(labels: [createLabel('label-1')]);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('returns false when all labelIds are empty', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['', '  '],
        );
        final task = TestData.task(labels: [createLabel('label-1')]);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - hasAll operator', () {
      test('matches task with all specified labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
        );
        final task = TestData.task(
          labels: [
            createLabel('label-1'),
            createLabel('label-2'),
            createLabel('label-3'),
          ],
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches task with exactly the specified labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
        );
        final task = TestData.task(
          labels: [createLabel('label-1'), createLabel('label-2')],
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task missing one label', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
        );
        final task = TestData.task(
          labels: [createLabel('label-1'), createLabel('label-3')],
        );

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with no labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1'],
        );
        final task = TestData.task(labels: []);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isNull operator', () {
      test('matches task with no labels of the type', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.isNull,
          labelType: LabelType.label,
        );
        final task = TestData.task(labels: []);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches task with only different type labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.isNull,
          labelType: LabelType.label,
        );
        final task = TestData.task(
          labels: [createLabel('value-1', type: LabelType.value)],
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with labels of the type', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.isNull,
          labelType: LabelType.label,
        );
        final task = TestData.task(labels: [createLabel('label-1')]);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isNotNull operator', () {
      test('matches task with labels of the type', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.isNotNull,
          labelType: LabelType.label,
        );
        final task = TestData.task(labels: [createLabel('label-1')]);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with no labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.isNotNull,
          labelType: LabelType.label,
        );
        final task = TestData.task(labels: []);

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with only different type labels', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.isNotNull,
          labelType: LabelType.label,
        );
        final task = TestData.task(
          labels: [createLabel('value-1', type: LabelType.value)],
        );

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - label type filtering', () {
      test('filters by label type for hasAny', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1'],
          labelType: LabelType.label,
        );
        // Task has the label but as value type
        final task = TestData.task(
          labels: [createLabel('label-1', type: LabelType.value)],
        );

        expect(rule.evaluate(task, context), isFalse);
      });

      test('matches correct label type for hasAny', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['value-1'],
          labelType: LabelType.value,
        );
        final task = TestData.task(
          labels: [createLabel('value-1', type: LabelType.value)],
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('filters by label type for hasAll', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
          labelType: LabelType.label,
        );
        // One label is the wrong type
        final task = TestData.task(
          labels: [
            createLabel('label-1', type: LabelType.label),
            createLabel('label-2', type: LabelType.value),
          ],
        );

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('validate', () {
      test('returns empty for valid hasAny rule', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1'],
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns empty for valid hasAll rule', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns error when hasAny has no labelIds', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: [],
        );

        expect(rule.validate(), contains(contains('requires at least one')));
      });

      test('returns error when hasAll has no labelIds', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: [],
        );

        expect(rule.validate(), contains(contains('requires at least one')));
      });

      test('returns error when all labelIds are empty strings', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['', '  '],
        );

        expect(rule.validate(), contains(contains('All label IDs are empty')));
      });

      test('returns empty for isNull operator', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.isNull,
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns empty for isNotNull operator', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.isNotNull,
        );

        expect(rule.validate(), isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
          labelType: LabelType.value,
        );

        final json = rule.toJson();

        expect(json['type'], 'labels');
        expect(json['operator'], 'hasAll');
        expect(json['labelIds'], ['label-1', 'label-2']);
        expect(json['labelType'], 'value');
      });

      test('serializes with default label type', () {
        final rule = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1'],
        );

        final json = rule.toJson();

        expect(json['labelType'], 'label');
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = <String, dynamic>{
          'type': 'labels',
          'operator': 'hasAll',
          'labelIds': ['label-1', 'label-2'],
          'labelType': 'value',
        };

        final rule = LabelRule.fromJson(json);

        expect(rule.operator, LabelRuleOperator.hasAll);
        expect(rule.labelIds, ['label-1', 'label-2']);
        expect(rule.labelType, LabelType.value);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'labels'};

        final rule = LabelRule.fromJson(json);

        expect(rule.operator, LabelRuleOperator.hasAll);
        expect(rule.labelIds, isEmpty);
        expect(rule.labelType, LabelType.label);
      });

      test('filters non-string labelIds', () {
        final json = <String, dynamic>{
          'type': 'labels',
          'labelIds': ['label-1', 123, null, 'label-2'],
        };

        final rule = LabelRule.fromJson(json);

        expect(rule.labelIds, ['label-1', 'label-2']);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final rule1 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
          labelType: LabelType.label,
        );
        final rule2 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
          labelType: LabelType.label,
        );

        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });

      test('not equal when operator differs', () {
        final rule1 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1'],
        );
        final rule2 = TestData.labelRule(
          operator: LabelRuleOperator.hasAny,
          labelIds: ['label-1'],
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when labelIds differ', () {
        final rule1 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1'],
        );
        final rule2 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-2'],
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when labelType differs', () {
        final rule1 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1'],
          labelType: LabelType.label,
        );
        final rule2 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1'],
          labelType: LabelType.value,
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when labelIds order differs', () {
        final rule1 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2'],
        );
        final rule2 = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-2', 'label-1'],
        );

        expect(rule1, isNot(equals(rule2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips through JSON', () {
        final original = TestData.labelRule(
          operator: LabelRuleOperator.hasAll,
          labelIds: ['label-1', 'label-2', 'label-3'],
          labelType: LabelType.value,
        );

        final json = original.toJson();
        final restored = LabelRule.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trips isNull operator', () {
        final original = TestData.labelRule(
          operator: LabelRuleOperator.isNull,
        );

        final json = original.toJson();
        final restored = LabelRule.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
