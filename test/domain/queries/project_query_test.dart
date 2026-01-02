import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator;

import '../../helpers/fallback_values.dart';

void main() {
  setUpAll(registerAllFallbackValues);

  group('ProjectQuery', () {
    group('construction', () {
      test('creates with defaults', () {
        const query = ProjectQuery();

        expect(query.filter.isMatchAll, isTrue);
        expect(query.sortCriteria, isEmpty);
        expect(query.occurrenceExpansion, isNull);
      });

      test('creates with custom filter', () {
        const query = ProjectQuery(
          filter: QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );

        expect(query.filter.shared, hasLength(1));
        expect(query.filter.isMatchAll, isFalse);
      });

      test('creates with sort criteria', () {
        const query = ProjectQuery(
          sortCriteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(
              field: SortField.deadlineDate,
              direction: SortDirection.descending,
            ),
          ],
        );

        expect(query.sortCriteria, hasLength(2));
      });

      test('creates with occurrence expansion', () {
        final query = ProjectQuery(
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime.utc(2025, 6, 1),
            rangeEnd: DateTime.utc(2025, 6, 30),
          ),
        );

        expect(query.occurrenceExpansion, isNotNull);
        expect(query.shouldExpandOccurrences, isTrue);
      });
    });

    group('factory constructors', () {
      group('all', () {
        test('creates all query with no filter', () {
          final query = ProjectQuery.all();

          expect(query.filter.isMatchAll, isTrue);
        });

        test('uses default sort criteria', () {
          final query = ProjectQuery.all();

          expect(query.sortCriteria, isNotEmpty);
        });

        test('accepts custom sort criteria', () {
          final query = ProjectQuery.all(
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
          expect(query.sortCriteria[0].field, SortField.name);
        });
      });

      group('incomplete', () {
        test('creates incomplete query with completed = false filter', () {
          final query = ProjectQuery.incomplete();

          expect(query.filter.shared, hasLength(1));

          final boolPred = query.filter.shared
              .whereType<ProjectBoolPredicate>()
              .first;
          expect(boolPred.field, ProjectBoolField.completed);
          expect(boolPred.operator, BoolOperator.isFalse);
        });

        test('incomplete uses default sort criteria', () {
          final query = ProjectQuery.incomplete();

          expect(query.sortCriteria, isNotEmpty);
        });

        test('incomplete accepts custom sort criteria', () {
          final query = ProjectQuery.incomplete(
            sortCriteria: const [
              SortCriterion(field: SortField.createdDate),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
          expect(query.sortCriteria[0].field, SortField.createdDate);
        });
      });

      group('schedule', () {
        test('creates schedule query with date range', () {
          final rangeStart = DateTime.utc(2025, 6, 1);
          final rangeEnd = DateTime.utc(2025, 6, 30);
          final query = ProjectQuery.schedule(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(query.filter.shared, hasLength(2));

          // Check for incomplete filter
          final boolPred = query.filter.shared
              .whereType<ProjectBoolPredicate>()
              .first;
          expect(boolPred.operator, BoolOperator.isFalse);

          // Check for date predicate on start date
          final datePred = query.filter.shared
              .whereType<ProjectDatePredicate>()
              .first;
          expect(datePred.field, ProjectDateField.startDate);
          expect(datePred.operator, DateOperator.between);
          expect(datePred.startDate, rangeStart);
          expect(datePred.endDate, rangeEnd);
        });

        test('schedule includes occurrence expansion', () {
          final rangeStart = DateTime.utc(2025, 6, 1);
          final rangeEnd = DateTime.utc(2025, 6, 30);
          final query = ProjectQuery.schedule(
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );

          expect(query.occurrenceExpansion, isNotNull);
          expect(query.occurrenceExpansion!.rangeStart, rangeStart);
          expect(query.occurrenceExpansion!.rangeEnd, rangeEnd);
        });

        test('schedule accepts custom sort criteria', () {
          final query = ProjectQuery.schedule(
            rangeStart: DateTime.utc(2025, 6, 1),
            rangeEnd: DateTime.utc(2025, 6, 30),
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
          expect(query.sortCriteria[0].field, SortField.name);
        });
      });
    });

    group('helper properties', () {
      group('shouldExpandOccurrences', () {
        test('returns false when occurrenceExpansion is null', () {
          const query = ProjectQuery();

          expect(query.shouldExpandOccurrences, isFalse);
        });

        test('returns true when occurrenceExpansion is set', () {
          final query = ProjectQuery(
            occurrenceExpansion: OccurrenceExpansion(
              rangeStart: DateTime.utc(2025, 6, 1),
              rangeEnd: DateTime.utc(2025, 6, 30),
            ),
          );

          expect(query.shouldExpandOccurrences, isTrue);
        });
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        const query1 = ProjectQuery(
          filter: QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );
        const query2 = ProjectQuery(
          filter: QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );

        expect(query1, equals(query2));
        expect(query1.hashCode, query2.hashCode);
      });

      test('not equal when filter differs', () {
        const query1 = ProjectQuery(
          filter: QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );
        const query2 = ProjectQuery(
          filter: QueryFilter<ProjectPredicate>(
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

      test('not equal when sort criteria differs', () {
        const query1 = ProjectQuery(
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );
        const query2 = ProjectQuery(
          sortCriteria: [
            SortCriterion(field: SortField.deadlineDate),
          ],
        );

        expect(query1, isNot(equals(query2)));
      });

      test('not equal when occurrence expansion differs', () {
        final query1 = ProjectQuery(
          occurrenceExpansion: OccurrenceExpansion(
            rangeStart: DateTime.utc(2025, 6, 1),
            rangeEnd: DateTime.utc(2025, 6, 30),
          ),
        );
        const query2 = ProjectQuery();

        expect(query1, isNot(equals(query2)));
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        const query = ProjectQuery(
          filter: QueryFilter<ProjectPredicate>(
            shared: [
              ProjectBoolPredicate(
                field: ProjectBoolField.completed,
                operator: BoolOperator.isFalse,
              ),
            ],
          ),
        );

        expect(query.toString(), contains('ProjectQuery'));
        expect(query.toString(), contains('filter'));
        expect(query.toString(), contains('sortCriteria'));
      });
    });
  });
}
