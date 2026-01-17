import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(registerAllFallbackValues);

  group('ValueRule', () {
    final today = DateTime(2025, 6, 15);
    final context = EvaluationContext(today: today);

    // Helper to create values
    Value createValue(String id) {
      return TestData.value(id: id, name: 'Value $id');
    }

    group('construction', () {
      test('creates with required fields', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: ['value-1', 'value-2'],
        );

        expect(rule.operator, ValueRuleOperator.hasAny);
        expect(rule.valueIds, ['value-1', 'value-2']);
        expect(rule.type, RuleType.value);
      });

      test('defaults valueIds to empty list', () {
        final rule = TestData.valueRule();

        expect(rule.valueIds, isEmpty);
      });
    });

    group('evaluate - hasAny operator', () {
      test('matches task with any of the specified values', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: ['value-1', 'value-2'],
        );
        final task = TestData.task(
          values: [createValue('value-1'), createValue('value-3')],
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task without any of the values', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: ['value-1', 'value-2'],
        );
        final task = TestData.task(
          values: [createValue('value-3'), createValue('value-4')],
        );

        expect(rule.evaluate(task, context), isFalse);
      });

      test('returns false when valueIds is empty', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: [],
        );
        final task = TestData.task(values: [createValue('value-1')]);

        expect(rule.evaluate(task, context), isFalse);
      });

      test('ignores empty string valueIds', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: ['', '  ', 'value-1'],
        );
        final task = TestData.task(values: [createValue('value-1')]);

        expect(rule.evaluate(task, context), isTrue);
      });
    });

    group('evaluate - hasAll operator', () {
      test('matches task with all specified values', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-1', 'value-2'],
        );
        final task = TestData.task(
          values: [
            createValue('value-1'),
            createValue('value-2'),
            createValue('value-3'),
          ],
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task missing one value', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-1', 'value-2'],
        );
        final task = TestData.task(values: [createValue('value-1')]);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isNull operator', () {
      test('matches task with no values', () {
        final rule = TestData.valueRule(operator: ValueRuleOperator.isNull);
        final task = TestData.task(values: []);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with values', () {
        final rule = TestData.valueRule(operator: ValueRuleOperator.isNull);
        final task = TestData.task(values: [createValue('value-1')]);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isNotNull operator', () {
      test('matches task with values', () {
        final rule = TestData.valueRule(operator: ValueRuleOperator.isNotNull);
        final task = TestData.task(values: [createValue('value-1')]);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with no values', () {
        final rule = TestData.valueRule(operator: ValueRuleOperator.isNotNull);
        final task = TestData.task(values: []);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('validate', () {
      test('returns empty for valid hasAny rule', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: ['value-1'],
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns error when hasAny has no valueIds', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: [],
        );

        expect(rule.validate(), contains(contains('requires at least one')));
      });

      test('returns error when hasAll has no valueIds', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: [],
        );

        expect(rule.validate(), contains(contains('requires at least one')));
      });

      test('returns error when all valueIds are empty strings', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: ['', '  '],
        );

        expect(rule.validate(), contains(contains('All value IDs are empty')));
      });

      test('returns empty for isNull operator', () {
        final rule = TestData.valueRule(operator: ValueRuleOperator.isNull);

        expect(rule.validate(), isEmpty);
      });

      test('returns empty for isNotNull operator', () {
        final rule = TestData.valueRule(operator: ValueRuleOperator.isNotNull);

        expect(rule.validate(), isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final rule = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-1', 'value-2'],
        );

        final json = rule.toJson();

        expect(json['type'], 'value');
        expect(json['operator'], 'hasAll');
        expect(json['valueIds'], ['value-1', 'value-2']);
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = <String, dynamic>{
          'type': 'value',
          'operator': 'hasAll',
          'valueIds': ['value-1', 'value-2'],
        };

        final rule = ValueRule.fromJson(json);

        expect(rule.operator, ValueRuleOperator.hasAll);
        expect(rule.valueIds, ['value-1', 'value-2']);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'value'};

        final rule = ValueRule.fromJson(json);

        expect(rule.operator, ValueRuleOperator.hasAll);
        expect(rule.valueIds, isEmpty);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final rule1 = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-1', 'value-2'],
        );
        final rule2 = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-1', 'value-2'],
        );

        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });

      test('not equal when operator differs', () {
        final rule1 = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-1'],
        );
        final rule2 = TestData.valueRule(
          operator: ValueRuleOperator.hasAny,
          valueIds: ['value-1'],
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when valueIds differ', () {
        final rule1 = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-1'],
        );
        final rule2 = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-2'],
        );

        expect(rule1, isNot(equals(rule2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips through JSON', () {
        final original = TestData.valueRule(
          operator: ValueRuleOperator.hasAll,
          valueIds: ['value-1', 'value-2'],
        );

        final json = original.toJson();
        final restored = ValueRule.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
