import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator, LabelOperator;

void main() {
  group('ProjectQuery', () {
    test('default constructor creates instance with empty lists', () {
      const query = ProjectQuery();

      expect(query.filter, const QueryFilter<ProjectPredicate>.matchAll());
      expect(query.sortCriteria, isEmpty);
      expect(query.occurrenceExpansion, isNull);
      expect(query.shouldExpandOccurrences, isFalse);
    });

    test('constructor accepts all parameters', () {
      const filter = QueryFilter<ProjectPredicate>(
        shared: [
          ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        ],
      );
      final sortCriteria = [
        const SortCriterion(field: SortField.name),
      ];
      final expansion = OccurrenceExpansion(
        rangeStart: DateTime(2025),
        rangeEnd: DateTime(2025, 1, 31),
      );

      final query = ProjectQuery(
        filter: filter,
        sortCriteria: sortCriteria,
        occurrenceExpansion: expansion,
      );

      expect(query.filter, filter);
      expect(query.sortCriteria, sortCriteria);
      expect(query.occurrenceExpansion, expansion);
      expect(query.shouldExpandOccurrences, isTrue);
    });

    group('all factory', () {
      test('creates query with no filtering rules', () {
        final query = ProjectQuery.all();

        expect(query.filter, const QueryFilter<ProjectPredicate>.matchAll());
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

        expect(query.filter.orGroups, isEmpty);
        expect(query.filter.shared, hasLength(1));
        expect(query.filter.shared.first, isA<ProjectBoolPredicate>());

        final predicate = query.filter.shared.first as ProjectBoolPredicate;
        expect(predicate.field, ProjectBoolField.completed);
        expect(predicate.operator, BoolOperator.isFalse);
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

        expect(query.filter.orGroups, isEmpty);
        expect(query.filter.shared, hasLength(2));

        final boolPredicate = query.filter.shared
            .whereType<ProjectBoolPredicate>()
            .first;
        expect(boolPredicate.field, ProjectBoolField.completed);
        expect(boolPredicate.operator, BoolOperator.isFalse);

        final datePredicate = query.filter.shared
            .whereType<ProjectDatePredicate>()
            .first;
        expect(datePredicate.field, ProjectDateField.startDate);
        expect(datePredicate.operator, DateOperator.between);
        expect(datePredicate.startDate, rangeStart);
        expect(datePredicate.endDate, rangeEnd);
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

        final datePredicate = query.filter.shared
            .whereType<ProjectDatePredicate>()
            .first;
        expect(datePredicate.startDate, date);
        expect(datePredicate.endDate, date);
      });

      test('handles range spanning multiple months', () {
        final rangeStart = DateTime(2025);
        final rangeEnd = DateTime(2025, 6, 30);

        final query = ProjectQuery.schedule(
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        final datePredicate = query.filter.shared
            .whereType<ProjectDatePredicate>()
            .first;
        expect(datePredicate.startDate!.month, 1);
        expect(datePredicate.endDate!.month, 6);
      });

      test('handles range spanning year boundary', () {
        final rangeStart = DateTime(2025, 12);
        final rangeEnd = DateTime(2026, 1, 31);

        final query = ProjectQuery.schedule(
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        final datePredicate = query.filter.shared
            .whereType<ProjectDatePredicate>()
            .first;
        expect(datePredicate.startDate!.year, 2025);
        expect(datePredicate.endDate!.year, 2026);
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
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        final query1 = ProjectQuery(filter: filter);
        final query2 = ProjectQuery(filter: filter);

        expect(query1, equals(query2));
      });

      test('queries with different rules are not equal', () {
        final query1 = ProjectQuery(
          filter: const QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );

        final query2 = ProjectQuery(
          filter: const QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isTrue,
              ),
            ],
          ),
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
        const filter = QueryFilter<ProjectPredicate>(
          shared: [
            ProjectBoolPredicate(
              field: ProjectBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        final query1 = ProjectQuery(filter: filter);
        final query2 = ProjectQuery(filter: filter);

        expect(query1.hashCode, equals(query2.hashCode));
      });
    });

    group('toString', () {
      test('provides readable representation', () {
        const query = ProjectQuery();

        final string = query.toString();

        expect(string, contains('ProjectQuery'));
        expect(string, contains('filter'));
        expect(string, contains('sortCriteria'));
        expect(string, contains('occurrenceExpansion'));
      });

      test('includes filter information', () {
        final query = ProjectQuery(
          filter: const QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );

        final string = query.toString();

        expect(string, contains('ProjectBoolPredicate'));
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
      test('can combine multiple predicate types', () {
        final query = ProjectQuery(
          filter: QueryFilter<ProjectPredicate>(
            shared: [
              const ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
              ProjectDatePredicate(
                field: ProjectDateField.deadlineDate,
                operator: DateOperator.onOrBefore,
                date: DateTime(2025, 12, 31),
              ),
              const ProjectLabelPredicate(
                operator: LabelOperator.hasAny,
                labelType: LabelType.label,
                labelIds: ['label-1', 'label-2'],
              ),
            ],
          ),
        );

        expect(query.filter.shared, hasLength(3));
        expect(query.filter.shared[0], isA<ProjectBoolPredicate>());
        expect(query.filter.shared[1], isA<ProjectDatePredicate>());
        expect(query.filter.shared[2], isA<ProjectLabelPredicate>());
      });

      test('can have multiple sort criteria', () {
        final query = ProjectQuery(
          sortCriteria: const [
            SortCriterion(
              field: SortField.deadlineDate,
            ),
            SortCriterion(
              field: SortField.name,
            ),
            SortCriterion(
              field: SortField.createdDate,
              direction: SortDirection.descending,
            ),
          ],
        );

        expect(query.sortCriteria, hasLength(3));
      });

      test('can combine rules, sort, and expansion', () {
        final query = ProjectQuery(
          filter: const QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
          sortCriteria: const [
            SortCriterion(field: SortField.name),
          ],
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime(2025),
            rangeEnd: DateTime(2025, 1, 31),
          ),
        );

        expect(query.filter.shared, isNotEmpty);
        expect(query.sortCriteria, isNotEmpty);
        expect(query.shouldExpandOccurrences, isTrue);
      });
    });

    group('edge cases', () {
      test('handles empty filter', () {
        const query = ProjectQuery();

        expect(query.filter.shared, isEmpty);
        expect(query.filter.orGroups, isEmpty);
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

      test('handles very large number of predicates', () {
        final predicates = List.generate(
          100,
          (i) => const ProjectBoolPredicate(
            field: ProjectBoolField.completed,
            operator: BoolOperator.isFalse,
          ),
        );

        final query = ProjectQuery(
          filter: QueryFilter<ProjectPredicate>(shared: predicates),
        );

        expect(query.filter.shared, hasLength(100));
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
