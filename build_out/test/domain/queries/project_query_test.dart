import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/filtering/task_rules.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

void main() {
  group('ProjectQuery', () {
    test('default constructor creates instance with empty lists', () {
      const query = ProjectQuery();

      expect(query.rules, isEmpty);
      expect(query.sortCriteria, isEmpty);
      expect(query.occurrenceExpansion, isNull);
      expect(query.shouldExpandOccurrences, isFalse);
    });

    test('constructor accepts all parameters', () {
      final rules = [
        const BooleanRule(
          field: BooleanRuleField.completed,
          operator: BooleanRuleOperator.isFalse,
        ),
      ];
      final sortCriteria = [
        const SortCriterion(field: SortField.name),
      ];
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final query = ProjectQuery(
        rules: rules,
        sortCriteria: sortCriteria,
        occurrenceExpansion: expansion,
      );

      expect(query.rules, rules);
      expect(query.sortCriteria, sortCriteria);
      expect(query.occurrenceExpansion, expansion);
      expect(query.shouldExpandOccurrences, isTrue);
    });

    group('all factory', () {
      test('creates query with no filtering rules', () {
        final query = ProjectQuery.all();

        expect(query.rules, isEmpty);
        expect(query.occurrenceExpansion, isNull);
      });

      test('uses default sort criteria', () {
        final query = ProjectQuery.all();

        expect(query.sortCriteria, isNotEmpty);
        expect(query.sortCriteria.first.field, SortField.deadlineDate);
        expect(query.sortCriteria[1].field, SortField.name);
      });

      test('accepts custom sort criteria', () {
        final customSort = [
          const SortCriterion(
            field: SortField.name,
            direction: SortDirection.descending,
          ),
        ];
        final query = ProjectQuery.all(sortCriteria: customSort);

        expect(query.sortCriteria, customSort);
      });
    });

    group('incomplete factory', () {
      test('creates query with completed=false rule', () {
        final query = ProjectQuery.incomplete();

        expect(query.rules, hasLength(1));
        expect(query.rules.first, isA<BooleanRule>());

        final rule = query.rules.first as BooleanRule;
        expect(rule.field, BooleanRuleField.completed);
        expect(rule.operator, BooleanRuleOperator.isFalse);
      });

      test('uses default sort criteria', () {
        final query = ProjectQuery.incomplete();

        expect(query.sortCriteria, isNotEmpty);
        expect(query.sortCriteria.first.field, SortField.deadlineDate);
      });

      test('accepts custom sort criteria', () {
        final customSort = [
          const SortCriterion(field: SortField.createdDate),
        ];
        final query = ProjectQuery.incomplete(sortCriteria: customSort);

        expect(query.sortCriteria, customSort);
      });

      test('does not enable occurrence expansion', () {
        final query = ProjectQuery.incomplete();

        expect(query.occurrenceExpansion, isNull);
        expect(query.shouldExpandOccurrences, isFalse);
      });
    });

    group('schedule factory', () {
      test('creates query with completed=false and date range rules', () {
        final rangeStart = DateTime(2025);
        final rangeEnd = DateTime(2025, 1, 31);

        final query = ProjectQuery.schedule(
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        expect(query.rules, hasLength(2));

        final boolRule = query.rules.whereType<BooleanRule>().first;
        expect(boolRule.field, BooleanRuleField.completed);
        expect(boolRule.operator, BooleanRuleOperator.isFalse);

        final dateRule = query.rules.whereType<DateRule>().first;
        expect(dateRule.field, DateRuleField.startDate);
        expect(dateRule.operator, DateRuleOperator.between);
        expect(dateRule.startDate, rangeStart);
        expect(dateRule.endDate, rangeEnd);
      });

      test('enables occurrence expansion with date range', () {
        final rangeStart = DateTime(2025);
        final rangeEnd = DateTime(2025, 1, 31);

        final query = ProjectQuery.schedule(
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        expect(query.shouldExpandOccurrences, isTrue);
        expect(query.occurrenceExpansion, isNotNull);
        expect(query.occurrenceExpansion!.rangeStart, rangeStart);
        expect(query.occurrenceExpansion!.rangeEnd, rangeEnd);
      });

      test('uses default sort criteria', () {
        final query = ProjectQuery.schedule(
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
        );

        expect(query.sortCriteria, isNotEmpty);
        expect(query.sortCriteria.first.field, SortField.deadlineDate);
      });

      test('accepts custom sort criteria', () {
        final customSort = [
          const SortCriterion(
            field: SortField.startDate,
            direction: SortDirection.ascending,
          ),
        ];

        final query = ProjectQuery.schedule(
          rangeStart: DateTime(2025),
          rangeEnd: DateTime(2025, 1, 31),
          sortCriteria: customSort,
        );

        expect(query.sortCriteria, customSort);
      });

      test('handles single-day range', () {
        final date = DateTime(2025, 1, 15);

        final query = ProjectQuery.schedule(
          rangeStart: date,
          rangeEnd: date,
        );

        final dateRule = query.rules.whereType<DateRule>().first;
        expect(dateRule.startDate, date);
        expect(dateRule.endDate, date);
      });

      test('handles range spanning multiple months', () {
        final rangeStart = DateTime(2025);
        final rangeEnd = DateTime(2025, 6, 30);

        final query = ProjectQuery.schedule(
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        final dateRule = query.rules.whereType<DateRule>().first;
        expect(dateRule.startDate!.month, 1);
        expect(dateRule.endDate!.month, 6);
      });

      test('handles range spanning year boundary', () {
        final rangeStart = DateTime(2025, 12);
        final rangeEnd = DateTime(2026, 1, 31);

        final query = ProjectQuery.schedule(
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        final dateRule = query.rules.whereType<DateRule>().first;
        expect(dateRule.startDate!.year, 2025);
        expect(dateRule.endDate!.year, 2026);
      });
    });

    group('shouldExpandOccurrences', () {
      test('returns false when occurrenceExpansion is null', () {
        const query = ProjectQuery();

        expect(query.shouldExpandOccurrences, isFalse);
      });

      test('returns true when occurrenceExpansion is set', () {
        final query = ProjectQuery(
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime(2025),
            rangeEnd: DateTime(2025, 1, 31),
          ),
        );

        expect(query.shouldExpandOccurrences, isTrue);
      });
    });

    group('equality', () {
      test('identical queries are equal', () {
        const query1 = ProjectQuery();
        const query2 = ProjectQuery();

        expect(query1, equals(query2));
      });

      test('queries with same parameters are equal', () {
        final rules = [
          const BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isFalse,
          ),
        ];

        final query1 = ProjectQuery(rules: rules);
        final query2 = ProjectQuery(rules: rules);

        expect(query1, equals(query2));
      });

      test('queries with different rules are not equal', () {
        final query1 = ProjectQuery(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
        );

        final query2 = ProjectQuery(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isTrue,
            ),
          ],
        );

        expect(query1, isNot(equals(query2)));
      });

      test('queries with different sort criteria are not equal', () {
        final query1 = ProjectQuery(
          sortCriteria: const [
            SortCriterion(field: SortField.name),
          ],
        );

        final query2 = ProjectQuery(
          sortCriteria: const [
            SortCriterion(field: SortField.deadlineDate),
          ],
        );

        expect(query1, isNot(equals(query2)));
      });

      test('queries with different expansion are not equal', () {
        final query1 = ProjectQuery(
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime(2025),
            rangeEnd: DateTime(2025, 1, 31),
          ),
        );

        final query2 = ProjectQuery(
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime(2025, 2),
            rangeEnd: DateTime(2025, 2, 28),
          ),
        );

        expect(query1, isNot(equals(query2)));
      });

      test('same instance is equal to itself', () {
        final query = ProjectQuery.all();

        expect(query, equals(query));
      });
    });

    group('hashCode', () {
      test('equal queries have same hashCode', () {
        const query1 = ProjectQuery();
        const query2 = ProjectQuery();

        expect(query1.hashCode, equals(query2.hashCode));
      });

      test('queries with same rules have same hashCode', () {
        final rules = [
          const BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isFalse,
          ),
        ];

        final query1 = ProjectQuery(rules: rules);
        final query2 = ProjectQuery(rules: rules);

        expect(query1.hashCode, equals(query2.hashCode));
      });
    });

    group('toString', () {
      test('provides readable representation', () {
        const query = ProjectQuery();

        final string = query.toString();

        expect(string, contains('ProjectQuery'));
        expect(string, contains('rules'));
        expect(string, contains('sortCriteria'));
        expect(string, contains('occurrenceExpansion'));
      });

      test('includes rule information', () {
        final query = ProjectQuery(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
        );

        final string = query.toString();

        expect(string, contains('BooleanRule'));
      });

      test('includes sort criteria information', () {
        final query = ProjectQuery(
          sortCriteria: const [
            SortCriterion(field: SortField.name),
          ],
        );

        final string = query.toString();

        expect(string, contains('SortCriterion'));
      });
    });

    group('complex queries', () {
      test('can combine multiple rule types', () {
        final query = ProjectQuery(
          rules: [
            const BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
            DateRule(
              field: DateRuleField.deadlineDate,
              operator: DateRuleOperator.onOrBefore,
              date: DateTime(2025, 12, 31),
            ),
            const LabelRule(
              operator: LabelRuleOperator.hasAny,
              labelIds: ['label-1', 'label-2'],
            ),
          ],
        );

        expect(query.rules, hasLength(3));
        expect(query.rules[0], isA<BooleanRule>());
        expect(query.rules[1], isA<DateRule>());
        expect(query.rules[2], isA<LabelRule>());
      });

      test('can have multiple sort criteria', () {
        final query = ProjectQuery(
          sortCriteria: [
            const SortCriterion(
              field: SortField.deadlineDate,
              direction: SortDirection.ascending,
            ),
            const SortCriterion(
              field: SortField.name,
              direction: SortDirection.ascending,
            ),
            const SortCriterion(
              field: SortField.createdDate,
              direction: SortDirection.descending,
            ),
          ],
        );

        expect(query.sortCriteria, hasLength(3));
      });

      test('can combine rules, sort, and expansion', () {
        final query = ProjectQuery(
          rules: const [
            BooleanRule(
              field: BooleanRuleField.completed,
              operator: BooleanRuleOperator.isFalse,
            ),
          ],
          sortCriteria: const [
            SortCriterion(field: SortField.name),
          ],
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime(2025),
            rangeEnd: DateTime(2025, 1, 31),
          ),
        );

        expect(query.rules, isNotEmpty);
        expect(query.sortCriteria, isNotEmpty);
        expect(query.shouldExpandOccurrences, isTrue);
      });
    });

    group('edge cases', () {
      test('handles empty rules list', () {
        const query = ProjectQuery();

        expect(query.rules, isEmpty);
      });

      test('handles empty sort criteria list', () {
        const query = ProjectQuery();

        expect(query.sortCriteria, isEmpty);
      });

      test('handles null occurrence expansion', () {
        const query = ProjectQuery();

        expect(query.occurrenceExpansion, isNull);
        expect(query.shouldExpandOccurrences, isFalse);
      });

      test('handles very large number of rules', () {
        final rules = List.generate(
          100,
          (i) => const BooleanRule(
            field: BooleanRuleField.completed,
            operator: BooleanRuleOperator.isFalse,
          ),
        );

        final query = ProjectQuery(rules: rules);

        expect(query.rules, hasLength(100));
      });

      test('handles very large number of sort criteria', () {
        final sortCriteria = List.generate(
          10,
          (i) => const SortCriterion(field: SortField.name),
        );

        final query = ProjectQuery(sortCriteria: sortCriteria);

        expect(query.sortCriteria, hasLength(10));
      });
    });
  });
}
