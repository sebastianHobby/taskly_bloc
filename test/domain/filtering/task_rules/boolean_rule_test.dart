import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(registerAllFallbackValues);

  group('TaskRule', () {
    group('fromJson', () {
      test('returns BooleanRule for unknown type', () {
        final json = {
          'type': 'unknownType',
          'field': 'completed',
          'operator': 'isFalse',
        };

        final rule = TaskRule.fromJson(json);

        expect(rule, isA<BooleanRule>());
      });

      test('returns BooleanRule when type is null', () {
        final json = <String, dynamic>{
          'field': 'completed',
          'operator': 'isFalse',
        };

        final rule = TaskRule.fromJson(json);

        expect(rule, isA<BooleanRule>());
      });
    });
  });

  group('BooleanRule', () {
    final today = DateTime(2025, 6, 15);
    final context = EvaluationContext(today: today);

    group('construction', () {
      test('creates with required fields', () {
        final rule = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        );

        expect(rule.field, BooleanRuleField.completed);
        expect(rule.operator, BooleanRuleOperator.isFalse);
        expect(rule.type, RuleType.boolean);
      });

      test('creates with isTrue operator', () {
        final rule = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isTrue,
        );

        expect(rule.operator, BooleanRuleOperator.isTrue);
      });
    });

    group('evaluate - isFalse operator', () {
      test('matches incomplete task', () {
        final rule = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        );
        final task = TestData.task(completed: false);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match completed task', () {
        final rule = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        );
        final task = TestData.task(completed: true);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isTrue operator', () {
      test('matches completed task', () {
        final rule = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isTrue,
        );
        final task = TestData.task(completed: true);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match incomplete task', () {
        final rule = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isTrue,
        );
        final task = TestData.task(completed: false);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('applies', () {
      test('applies method delegates to evaluate', () {
        final rule = TestData.booleanRule(
          operator: BooleanRuleOperator.isFalse,
        );
        final task = TestData.task(completed: false);

        expect(rule.applies(task, today), isTrue);
      });
    });

    group('validate', () {
      test('always returns empty list', () {
        final rule1 = TestData.booleanRule(
          operator: BooleanRuleOperator.isFalse,
        );
        final rule2 = TestData.booleanRule(
          operator: BooleanRuleOperator.isTrue,
        );

        expect(rule1.validate(), isEmpty);
        expect(rule2.validate(), isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final rule = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isTrue,
        );

        final json = rule.toJson();

        expect(json['type'], 'boolean');
        expect(json['field'], 'completed');
        expect(json['operator'], 'isTrue');
      });

      test('serializes isFalse operator', () {
        final rule = TestData.booleanRule(
          operator: BooleanRuleOperator.isFalse,
        );

        final json = rule.toJson();

        expect(json['operator'], 'isFalse');
      });
    });

    group('fromJson', () {
      test('parses valid JSON with isTrue', () {
        final json = <String, dynamic>{
          'type': 'boolean',
          'field': 'completed',
          'operator': 'isTrue',
        };

        final rule = BooleanRule.fromJson(json);

        expect(rule.field, BooleanRuleField.completed);
        expect(rule.operator, BooleanRuleOperator.isTrue);
      });

      test('parses valid JSON with isFalse', () {
        final json = <String, dynamic>{
          'type': 'boolean',
          'field': 'completed',
          'operator': 'isFalse',
        };

        final rule = BooleanRule.fromJson(json);

        expect(rule.operator, BooleanRuleOperator.isFalse);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'boolean'};

        final rule = BooleanRule.fromJson(json);

        expect(rule.field, BooleanRuleField.completed);
        expect(rule.operator, BooleanRuleOperator.isFalse);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final rule1 = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isTrue,
        );
        final rule2 = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isTrue,
        );

        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });

      test('not equal when field differs', () {
        // Since there's only one field, we test operator difference
        final rule1 = TestData.booleanRule(
          operator: BooleanRuleOperator.isTrue,
        );
        final rule2 = TestData.booleanRule(
          operator: BooleanRuleOperator.isFalse,
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when operator differs', () {
        final rule1 = TestData.booleanRule(
          operator: BooleanRuleOperator.isTrue,
        );
        final rule2 = TestData.booleanRule(
          operator: BooleanRuleOperator.isFalse,
        );

        expect(rule1, isNot(equals(rule2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips through JSON with isTrue', () {
        final original = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isTrue,
        );

        final json = original.toJson();
        final restored = BooleanRule.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trips through JSON with isFalse', () {
        final original = TestData.booleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        );

        final json = original.toJson();
        final restored = BooleanRule.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
