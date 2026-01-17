import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/test_data.dart';
import '../../../helpers/fallback_values.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(registerAllFallbackValues);

  group('DateRule', () {
    // Use a fixed reference date for all tests
    final today = DateTime(2025, 6, 15);
    final context = EvaluationContext(today: today);

    group('construction', () {
      test('creates with required fields', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrBefore,
        );

        expect(rule.field, DateRuleField.deadlineDate);
        expect(rule.operator, DateRuleOperator.onOrBefore);
        expect(rule.type, RuleType.date);
      });

      test('creates with all optional fields', () {
        final rule = TestData.dateRule(
          field: DateRuleField.startDate,
          operator: DateRuleOperator.between,
          date: DateTime(2025, 6, 1),
          startDate: DateTime(2025, 6, 1),
          endDate: DateTime(2025, 6, 30),
          relativeComparison: RelativeComparison.onOrAfter,
          relativeDays: 7,
        );

        expect(rule.date, DateTime(2025, 6, 1));
        expect(rule.startDate, DateTime(2025, 6, 1));
        expect(rule.endDate, DateTime(2025, 6, 30));
        expect(rule.relativeComparison, RelativeComparison.onOrAfter);
        expect(rule.relativeDays, 7);
      });
    });

    group('evaluate - onOrAfter operator', () {
      test('matches task with deadline on reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrAfter,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches task with deadline after reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrAfter,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 20));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with deadline before reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrAfter,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 10));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with null deadline', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrAfter,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: null);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - onOrBefore operator', () {
      test('matches task with deadline on reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrBefore,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches task with deadline before reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrBefore,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 10));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with deadline after reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrBefore,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 20));

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - before operator', () {
      test('matches task with deadline before reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.before,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 14));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with deadline on reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.before,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with deadline after reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.before,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 16));

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - after operator', () {
      test('matches task with deadline after reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.after,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 16));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with deadline on reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.after,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with deadline before reference date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.after,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 14));

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - on operator', () {
      test('matches task with deadline on exact date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches ignoring time component', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15, 14, 30));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with different date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 16));

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - between operator', () {
      test('matches task with deadline within range', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches task with deadline on start date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 10));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches task with deadline on end date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 20));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with deadline before range', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 5));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('does not match task with deadline after range', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 25));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('returns false when startDate is missing', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          endDate: DateTime(2025, 6, 20),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('returns false when endDate is missing', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 10),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('returns false when end is before start', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 20),
          endDate: DateTime(2025, 6, 10),
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - relative operator', () {
      test('matches with relative onOrAfter comparison', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.onOrAfter,
          relativeDays: 5,
        );
        // today + 5 = June 20, task deadline is June 25
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 25));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches with relative on comparison', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.on,
          relativeDays: 5,
        );
        // today + 5 = June 20
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 20));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches with relative before comparison', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.before,
          relativeDays: 5,
        );
        // today + 5 = June 20, task deadline is June 18
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 18));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches with relative after comparison', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.after,
          relativeDays: 5,
        );
        // today + 5 = June 20, task deadline is June 21
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 21));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('matches with relative onOrBefore comparison', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.onOrBefore,
          relativeDays: 5,
        );
        // today + 5 = June 20, task deadline is June 18
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 18));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('works with negative relativeDays', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.onOrBefore,
          relativeDays: -5,
        );
        // today - 5 = June 10, task deadline is June 8
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 8));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('returns false when relativeComparison is null', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeDays: 5,
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 20));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('returns false when relativeDays is null', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.on,
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 20));

        expect(rule.evaluate(task, context), isFalse);
      });

      test('returns false when task date is null', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.on,
          relativeDays: 5,
        );
        final task = TestData.task(deadlineDate: null);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isNull operator', () {
      test('matches task with null date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.isNull,
        );
        final task = TestData.task(deadlineDate: null);

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with date set', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.isNull,
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - isNotNull operator', () {
      test('matches task with date set', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.isNotNull,
        );
        final task = TestData.task(deadlineDate: DateTime(2025, 6, 15));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('does not match task with null date', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.isNotNull,
        );
        final task = TestData.task(deadlineDate: null);

        expect(rule.evaluate(task, context), isFalse);
      });
    });

    group('evaluate - different fields', () {
      test('evaluates startDate field', () {
        final rule = TestData.dateRule(
          field: DateRuleField.startDate,
          operator: DateRuleOperator.isNotNull,
        );
        final task = TestData.task(startDate: DateTime(2025, 6, 1));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('evaluates createdAt field', () {
        final rule = TestData.dateRule(
          field: DateRuleField.createdAt,
          operator: DateRuleOperator.onOrBefore,
          date: DateTime(2025, 6, 15),
        );
        final task = TestData.task(createdAt: DateTime(2025, 6, 10));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('evaluates updatedAt field', () {
        final rule = TestData.dateRule(
          field: DateRuleField.updatedAt,
          operator: DateRuleOperator.onOrAfter,
          date: DateTime(2025, 6, 1),
        );
        final task = TestData.task(updatedAt: DateTime(2025, 6, 10));

        expect(rule.evaluate(task, context), isTrue);
      });

      test('evaluates completedAt field from occurrence', () {
        final rule = TestData.dateRule(
          field: DateRuleField.completedAt,
          operator: DateRuleOperator.isNotNull,
        );
        final task = TestData.task(
          occurrence: TestData.occurrenceData(
            completedAt: DateTime(2025, 6, 10),
          ),
        );

        expect(rule.evaluate(task, context), isTrue);
      });

      test('completedAt is null when no occurrence', () {
        final rule = TestData.dateRule(
          field: DateRuleField.completedAt,
          operator: DateRuleOperator.isNull,
        );
        final task = TestData.task(occurrence: null);

        expect(rule.evaluate(task, context), isTrue);
      });
    });

    group('validate', () {
      test('returns empty for valid onOrAfter rule', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.onOrAfter,
          date: DateTime(2025, 6, 15),
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns error when onOrAfter has no date', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.onOrAfter,
        );

        expect(rule.validate(), contains(contains('requires a date')));
      });

      test('returns error when onOrBefore has no date', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.onOrBefore,
        );

        expect(rule.validate(), contains(contains('requires a date')));
      });

      test('returns error when before has no date', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.before,
        );

        expect(rule.validate(), contains(contains('requires a date')));
      });

      test('returns error when after has no date', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.after,
        );

        expect(rule.validate(), contains(contains('requires a date')));
      });

      test('returns error when on has no date', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.on,
        );

        expect(rule.validate(), contains(contains('requires a date')));
      });

      test('returns error when between has no startDate', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.between,
          endDate: DateTime(2025, 6, 20),
        );

        expect(
          rule.validate(),
          contains(contains('requires both start and end dates')),
        );
      });

      test('returns error when between has no endDate', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 10),
        );

        expect(
          rule.validate(),
          contains(contains('requires both start and end dates')),
        );
      });

      test('returns error when between end is before start', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 20),
          endDate: DateTime(2025, 6, 10),
        );

        expect(
          rule.validate(),
          contains(contains('End date must be after start date')),
        );
      });

      test('returns empty for valid between rule', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.between,
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns error when relative has no comparison', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.relative,
          relativeDays: 5,
        );

        expect(
          rule.validate(),
          contains(contains('requires comparison type')),
        );
      });

      test('returns error when relative has no days', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.on,
        );

        expect(rule.validate(), contains(contains('requires days value')));
      });

      test('returns empty for valid relative rule', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.on,
          relativeDays: 5,
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns empty for isNull operator', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.isNull,
        );

        expect(rule.validate(), isEmpty);
      });

      test('returns empty for isNotNull operator', () {
        final rule = TestData.dateRule(
          operator: DateRuleOperator.isNotNull,
        );

        expect(rule.validate(), isEmpty);
      });
    });

    group('toJson', () {
      test('serializes all fields', () {
        final rule = TestData.dateRule(
          field: DateRuleField.startDate,
          operator: DateRuleOperator.between,
          date: DateTime(2025, 6, 15),
          startDate: DateTime(2025, 6, 10),
          endDate: DateTime(2025, 6, 20),
          relativeComparison: RelativeComparison.onOrAfter,
          relativeDays: 7,
        );

        final json = rule.toJson();

        expect(json['type'], 'date');
        expect(json['field'], 'startDate');
        expect(json['operator'], 'between');
        expect(json['startDate'], isNotNull);
        expect(json['endDate'], isNotNull);
        expect(json['relativeComparison'], 'onOrAfter');
        expect(json['relativeDays'], 7);
      });

      test('handles null optional fields', () {
        final rule = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.isNull,
        );

        final json = rule.toJson();

        expect(json['date'], isNull);
        expect(json['startDate'], isNull);
        expect(json['endDate'], isNull);
        expect(json['relativeComparison'], isNull);
        expect(json['relativeDays'], isNull);
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'onOrBefore',
          'date': '2025-06-15',
        };

        final rule = DateRule.fromJson(json);

        expect(rule.field, DateRuleField.deadlineDate);
        expect(rule.operator, DateRuleOperator.onOrBefore);
        // fromJson parses dates as UTC midnight
        expect(rule.date, DateTime.utc(2025, 6, 15));
      });

      test('parses between operator with range', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'startDate',
          'operator': 'between',
          'startDate': '2025-06-10',
          'endDate': '2025-06-20',
        };

        final rule = DateRule.fromJson(json);

        expect(rule.operator, DateRuleOperator.between);
        // fromJson parses dates as UTC midnight
        expect(rule.startDate, DateTime.utc(2025, 6, 10));
        expect(rule.endDate, DateTime.utc(2025, 6, 20));
      });

      test('parses relative operator', () {
        final json = <String, dynamic>{
          'type': 'date',
          'field': 'deadlineDate',
          'operator': 'relative',
          'relativeComparison': 'onOrAfter',
          'relativeDays': 7,
        };

        final rule = DateRule.fromJson(json);

        expect(rule.operator, DateRuleOperator.relative);
        expect(rule.relativeComparison, RelativeComparison.onOrAfter);
        expect(rule.relativeDays, 7);
      });

      test('uses defaults for missing fields', () {
        final json = <String, dynamic>{'type': 'date'};

        final rule = DateRule.fromJson(json);

        expect(rule.field, DateRuleField.deadlineDate);
        expect(rule.operator, DateRuleOperator.onOrAfter);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final rule1 = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final rule2 = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );

        expect(rule1, equals(rule2));
        expect(rule1.hashCode, equals(rule2.hashCode));
      });

      test('not equal when field differs', () {
        final rule1 = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final rule2 = TestData.dateRule(
          field: DateRuleField.startDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when operator differs', () {
        final rule1 = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final rule2 = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.onOrBefore,
          date: DateTime(2025, 6, 15),
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('not equal when date differs', () {
        final rule1 = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 15),
        );
        final rule2 = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.on,
          date: DateTime(2025, 6, 16),
        );

        expect(rule1, isNot(equals(rule2)));
      });

      test('equal with both dates null', () {
        final rule1 = TestData.dateRule(
          operator: DateRuleOperator.isNull,
        );
        final rule2 = TestData.dateRule(
          operator: DateRuleOperator.isNull,
        );

        expect(rule1, equals(rule2));
      });
    });

    group('round-trip serialization', () {
      test('round-trips through JSON', () {
        final original = TestData.dateRule(
          field: DateRuleField.startDate,
          operator: DateRuleOperator.relative,
          relativeComparison: RelativeComparison.onOrBefore,
          relativeDays: -7,
        );

        final json = original.toJson();
        final restored = DateRule.fromJson(json);

        expect(restored, equals(original));
      });

      test('round-trips between operator', () {
        // Use UTC dates since fromJson normalizes to UTC midnight
        final original = TestData.dateRule(
          field: DateRuleField.deadlineDate,
          operator: DateRuleOperator.between,
          startDate: DateTime.utc(2025, 6, 1),
          endDate: DateTime.utc(2025, 6, 30),
        );

        final json = original.toJson();
        final restored = DateRule.fromJson(json);

        expect(restored, equals(original));
      });
    });
  });
}
