import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/evaluation_context.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('TaskRuleSet', () {
    final today = DateTime(2025, 6, 15);
    final context = EvaluationContext(today: today);

    group('construction', () {
      test('creates with required fields', () {
        final rules = [
          TestData.booleanRule(operator: BooleanRuleOperator.isFalse),
        ];
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: rules,
        );

        expect(ruleSet.operator, RuleSetOperator.and);
        expect(ruleSet.rules, rules);
      });

      test('creates with empty rules', () {
        final ruleSet = TestData.taskRuleSet(rules: []);

        expect(ruleSet.rules, isEmpty);
      });
    });

    group('evaluate - AND operator', () {
      test('returns true when all rules match', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isFalse),
            TestData.dateRule(
              operator: DateRuleOperator.isNotNull,
              field: DateRuleField.deadlineDate,
            ),
          ],
        );
        final task = TestData.task(
          completed: false,
          deadlineDate: DateTime(2025, 6, 20),
        );

        expect(ruleSet.evaluate(task, context), isTrue);
      });

      test('returns false when any rule does not match', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isFalse),
            TestData.dateRule(
              operator: DateRuleOperator.isNotNull,
              field: DateRuleField.deadlineDate,
            ),
          ],
        );
        final task = TestData.task(
          completed: false,
          deadlineDate: null, // This fails the second rule
        );

        expect(ruleSet.evaluate(task, context), isFalse);
      });

      test('returns false when first rule does not match', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isFalse),
            TestData.dateRule(
              operator: DateRuleOperator.isNotNull,
              field: DateRuleField.deadlineDate,
            ),
          ],
        );
        final task = TestData.task(
          completed: true, // This fails the first rule
          deadlineDate: DateTime(2025, 6, 20),
        );

        expect(ruleSet.evaluate(task, context), isFalse);
      });

      test('returns true when rules list is empty', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [],
        );
        final task = TestData.task();

        expect(ruleSet.evaluate(task, context), isTrue);
      });

      test('handles single rule', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isFalse),
          ],
        );
        final task = TestData.task(completed: false);

        expect(ruleSet.evaluate(task, context), isTrue);
      });
    });

    group('evaluate - OR operator', () {
      test('returns true when any rule matches', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.or,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isTrue),
            TestData.dateRule(
              operator: DateRuleOperator.isNotNull,
              field: DateRuleField.deadlineDate,
            ),
          ],
        );
        final task = TestData.task(
          completed: false, // Fails first rule
          deadlineDate: DateTime(2025, 6, 20), // Passes second rule
        );

        expect(ruleSet.evaluate(task, context), isTrue);
      });

      test('returns true when all rules match', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.or,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isFalse),
            TestData.dateRule(
              operator: DateRuleOperator.isNotNull,
              field: DateRuleField.deadlineDate,
            ),
          ],
        );
        final task = TestData.task(
          completed: false,
          deadlineDate: DateTime(2025, 6, 20),
        );

        expect(ruleSet.evaluate(task, context), isTrue);
      });

      test('returns false when no rules match', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.or,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isTrue),
            TestData.dateRule(
              operator: DateRuleOperator.isNotNull,
              field: DateRuleField.deadlineDate,
            ),
          ],
        );
        final task = TestData.task(
          completed: false, // Fails first rule
          deadlineDate: null, // Fails second rule
        );

        expect(ruleSet.evaluate(task, context), isFalse);
      });

      test('returns true when rules list is empty', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.or,
          rules: [],
        );
        final task = TestData.task();

        expect(ruleSet.evaluate(task, context), isTrue);
      });
    });

    group('validate', () {
      test('returns error for empty rules', () {
        final ruleSet = TestData.taskRuleSet(rules: []);

        final errors = ruleSet.validate();

        expect(
          errors,
          contains(contains('must contain at least one rule')),
        );
      });

      test('returns empty for valid rule set', () {
        final ruleSet = TestData.taskRuleSet(
          rules: [
            TestData.booleanRule(),
          ],
        );

        expect(ruleSet.validate(), isEmpty);
      });

      test('aggregates errors from child rules', () {
        final ruleSet = TestData.taskRuleSet(
          rules: [
            TestData.dateRule(
              operator: DateRuleOperator.onOrBefore,
              // Missing date - should be invalid
            ),
            TestData.projectRule(
              operator: ProjectRuleOperator.matches,
              // Missing projectId - should be invalid
            ),
          ],
        );

        final errors = ruleSet.validate();

        expect(errors.length, 2);
        expect(errors[0], contains('Rule 1'));
        expect(errors[1], contains('Rule 2'));
      });

      test('includes rule index in error messages', () {
        final ruleSet = TestData.taskRuleSet(
          rules: [
            TestData.booleanRule(), // Valid
            TestData.dateRule(operator: DateRuleOperator.on), // Invalid
          ],
        );

        final errors = ruleSet.validate();

        expect(errors, hasLength(1));
        expect(errors[0], startsWith('Rule 2:'));
      });
    });

    group('copyWith', () {
      test('copies with no changes', () {
        final original = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [TestData.booleanRule()],
        );

        final copy = original.copyWith();

        expect(copy.operator, original.operator);
        expect(copy.rules, original.rules);
      });

      test('copies with operator change', () {
        final original = TestData.taskRuleSet(operator: RuleSetOperator.and);

        final copy = original.copyWith(operator: RuleSetOperator.or);

        expect(copy.operator, RuleSetOperator.or);
      });

      test('copies with rules change', () {
        final original = TestData.taskRuleSet(rules: []);
        final newRules = [TestData.booleanRule()];

        final copy = original.copyWith(rules: newRules);

        expect(copy.rules, newRules);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final ruleSet = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isFalse),
            TestData.dateRule(
              operator: DateRuleOperator.isNotNull,
              field: DateRuleField.deadlineDate,
            ),
          ],
        );

        final json = ruleSet.toJson();

        expect(json['operator'], 'and');
        expect(json['rules'], isA<List>());
        expect((json['rules'] as List).length, 2);
      });

      test('serializes OR operator', () {
        final ruleSet = TestData.taskRuleSet(operator: RuleSetOperator.or);

        final json = ruleSet.toJson();

        expect(json['operator'], 'or');
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = <String, dynamic>{
          'operator': 'and',
          'rules': [
            {'type': 'boolean', 'field': 'completed', 'operator': 'isFalse'},
          ],
        };

        final ruleSet = TaskRuleSet.fromJson(json);

        expect(ruleSet.operator, RuleSetOperator.and);
        expect(ruleSet.rules, hasLength(1));
        expect(ruleSet.rules[0], isA<BooleanRule>());
      });

      test('parses OR operator', () {
        final json = <String, dynamic>{
          'operator': 'or',
          'rules': <dynamic>[],
        };

        final ruleSet = TaskRuleSet.fromJson(json);

        expect(ruleSet.operator, RuleSetOperator.or);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{};

        final ruleSet = TaskRuleSet.fromJson(json);

        expect(ruleSet.operator, RuleSetOperator.and);
        expect(ruleSet.rules, isEmpty);
      });

      test('filters non-map rules', () {
        final json = <String, dynamic>{
          'operator': 'and',
          'rules': [
            {'type': 'boolean', 'field': 'completed', 'operator': 'isFalse'},
            'invalid',
            123,
            null,
          ],
        };

        final ruleSet = TaskRuleSet.fromJson(json);

        expect(ruleSet.rules, hasLength(1));
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final rule = TestData.booleanRule();
        final ruleSet1 = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [rule],
        );
        final ruleSet2 = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [rule],
        );

        expect(ruleSet1, equals(ruleSet2));
        expect(ruleSet1.hashCode, equals(ruleSet2.hashCode));
      });

      test('not equal when operator differs', () {
        final rules = [TestData.booleanRule()];
        final ruleSet1 = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: rules,
        );
        final ruleSet2 = TestData.taskRuleSet(
          operator: RuleSetOperator.or,
          rules: rules,
        );

        expect(ruleSet1, isNot(equals(ruleSet2)));
      });

      test('not equal when rules differ', () {
        final ruleSet1 = TestData.taskRuleSet(
          rules: [TestData.booleanRule(operator: BooleanRuleOperator.isTrue)],
        );
        final ruleSet2 = TestData.taskRuleSet(
          rules: [TestData.booleanRule(operator: BooleanRuleOperator.isFalse)],
        );

        expect(ruleSet1, isNot(equals(ruleSet2)));
      });
    });

    group('round-trip serialization', () {
      test('round-trips through JSON', () {
        final original = TestData.taskRuleSet(
          operator: RuleSetOperator.and,
          rules: [
            TestData.booleanRule(operator: BooleanRuleOperator.isFalse),
            TestData.dateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              // Use UTC date since fromJson normalizes to UTC midnight
              date: DateTime.utc(2025, 6, 30),
            ),
          ],
        );

        final json = original.toJson();
        final restored = TaskRuleSet.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
