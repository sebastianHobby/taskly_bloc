import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';

import '../../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('TaskRule.fromJson', () {
    test('parses DateRule from JSON', () {
      final json = <String, dynamic>{
        'type': 'date',
        'field': 'deadlineDate',
        'operator': 'onOrBefore',
        'date': '2025-06-15',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<DateRule>());
      expect((rule as DateRule).field, DateRuleField.deadlineDate);
    });

    test('parses BooleanRule from JSON', () {
      final json = <String, dynamic>{
        'type': 'boolean',
        'field': 'completed',
        'operator': 'isFalse',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<BooleanRule>());
      expect((rule as BooleanRule).operator, BooleanRuleOperator.isFalse);
    });

    test('parses ValueRule from JSON', () {
      final json = <String, dynamic>{
        'type': 'value',
        'operator': 'hasAny',
        'valueIds': ['value-1'],
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<ValueRule>());
      expect((rule as ValueRule).operator, ValueRuleOperator.hasAny);
    });

    test('parses ProjectRule from JSON', () {
      final json = <String, dynamic>{
        'type': 'project',
        'operator': 'matches',
        'projectId': 'project-1',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<ProjectRule>());
      expect((rule as ProjectRule).projectId, 'project-1');
    });

    test('defaults to BooleanRule for unknown type', () {
      final json = <String, dynamic>{
        'type': 'unknown_type',
        'field': 'completed',
        'operator': 'isFalse',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<BooleanRule>());
    });

    test('defaults to BooleanRule for missing type', () {
      final json = <String, dynamic>{
        'field': 'completed',
        'operator': 'isFalse',
      };

      final rule = TaskRule.fromJson(json);

      expect(rule, isA<BooleanRule>());
    });
  });

  group('RuleType', () {
    test('has all expected values', () {
      expect(
        RuleType.values,
        containsAll([
          RuleType.date,
          RuleType.boolean,
          RuleType.project,
          RuleType.value,
        ]),
      );
    });
  });

  group('RuleSetOperator', () {
    test('has all expected values', () {
      expect(
        RuleSetOperator.values,
        containsAll([
          RuleSetOperator.and,
          RuleSetOperator.or,
        ]),
      );
    });
  });

  group('DateRuleField', () {
    test('has all expected values', () {
      expect(
        DateRuleField.values,
        containsAll([
          DateRuleField.startDate,
          DateRuleField.deadlineDate,
          DateRuleField.createdAt,
          DateRuleField.updatedAt,
          DateRuleField.completedAt,
        ]),
      );
    });
  });

  group('DateRuleOperator', () {
    test('has all expected values', () {
      expect(
        DateRuleOperator.values,
        containsAll([
          DateRuleOperator.onOrAfter,
          DateRuleOperator.onOrBefore,
          DateRuleOperator.before,
          DateRuleOperator.after,
          DateRuleOperator.on,
          DateRuleOperator.between,
          DateRuleOperator.relative,
          DateRuleOperator.isNull,
          DateRuleOperator.isNotNull,
        ]),
      );
    });
  });

  group('RelativeComparison', () {
    test('has all expected values', () {
      expect(
        RelativeComparison.values,
        containsAll([
          RelativeComparison.on,
          RelativeComparison.before,
          RelativeComparison.after,
          RelativeComparison.onOrAfter,
          RelativeComparison.onOrBefore,
        ]),
      );
    });
  });

  group('BooleanRuleField', () {
    test('has completed field', () {
      expect(BooleanRuleField.values, contains(BooleanRuleField.completed));
    });
  });

  group('BooleanRuleOperator', () {
    test('has all expected values', () {
      expect(
        BooleanRuleOperator.values,
        containsAll([
          BooleanRuleOperator.isTrue,
          BooleanRuleOperator.isFalse,
        ]),
      );
    });
  });

  group('LabelRuleOperator', () {
    test('has all expected values', () {
      expect(
        LabelRuleOperator.values,
        containsAll([
          LabelRuleOperator.hasAll,
          LabelRuleOperator.hasAny,
          LabelRuleOperator.isNull,
          LabelRuleOperator.isNotNull,
        ]),
      );
    });
  });

  group('ValueRuleOperator', () {
    test('has all expected values', () {
      expect(
        ValueRuleOperator.values,
        containsAll([
          ValueRuleOperator.hasAll,
          ValueRuleOperator.hasAny,
          ValueRuleOperator.isNull,
          ValueRuleOperator.isNotNull,
        ]),
      );
    });
  });

  group('ProjectRuleOperator', () {
    test('has all expected values', () {
      expect(
        ProjectRuleOperator.values,
        containsAll([
          ProjectRuleOperator.matches,
          ProjectRuleOperator.matchesAny,
          ProjectRuleOperator.isNull,
          ProjectRuleOperator.isNotNull,
        ]),
      );
    });
  });
}
