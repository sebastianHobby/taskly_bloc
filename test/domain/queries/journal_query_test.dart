import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/journal/model/mood_rating.dart';
import 'package:taskly_bloc/domain/queries/journal_predicate.dart';
import 'package:taskly_bloc/domain/queries/journal_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show DateOperator;

void main() {
  group('JournalQuery', () {
    group('construction', () {
      test('creates with defaults', () {
        const query = JournalQuery();

        expect(query.filter.isMatchAll, isTrue);
        expect(query.sortCriteria, isEmpty);
      });

      test('creates with custom filter', () {
        final query = JournalQuery(
          filter: QueryFilter<JournalPredicate>(
            shared: [
              JournalDatePredicate(
                operator: DateOperator.on,
                date: DateTime(2026, 1, 3),
              ),
            ],
          ),
        );

        expect(query.filter.shared, hasLength(1));
        expect(query.filter.isMatchAll, isFalse);
      });

      test('creates with sort criteria', () {
        const query = JournalQuery(
          sortCriteria: [
            SortCriterion(field: SortField.createdDate),
          ],
        );

        expect(query.sortCriteria, hasLength(1));
      });
    });

    group('factory constructors', () {
      group('all', () {
        test('creates query with no filtering', () {
          final query = JournalQuery.all();

          expect(query.filter.isMatchAll, isTrue);
        });

        test('all uses default sort criteria', () {
          final query = JournalQuery.all();

          expect(query.sortCriteria, isNotEmpty);
          expect(query.sortCriteria[0].field, SortField.createdDate);
          expect(
            query.sortCriteria[0].direction,
            SortDirection.descending,
          );
        });

        test('all accepts custom sort criteria', () {
          final query = JournalQuery.all(
            sortCriteria: const [
              SortCriterion(
                field: SortField.updatedDate,
                direction: SortDirection.ascending,
              ),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
          expect(query.sortCriteria[0].field, SortField.updatedDate);
        });
      });

      group('byId', () {
        test('creates query for specific ID', () {
          final query = JournalQuery.byId('entry-123');

          expect(query.filter.shared, hasLength(1));
          final idPred = query.filter.shared
              .whereType<JournalIdPredicate>()
              .first;
          expect(idPred.id, 'entry-123');
        });
      });

      group('forDate', () {
        test('creates query for specific date', () {
          final query = JournalQuery.forDate(DateTime(2026, 1, 3, 14, 30));

          expect(query.filter.shared, hasLength(1));
          final datePred = query.filter.shared
              .whereType<JournalDatePredicate>()
              .first;
          expect(datePred.operator, DateOperator.on);
          // Should strip time component
          expect(datePred.date?.hour, 0);
          expect(datePred.date?.minute, 0);
        });
      });

      group('dateRange', () {
        test('creates query for date range', () {
          final query = JournalQuery.dateRange(
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 31),
          );

          expect(query.filter.shared, hasLength(1));
          final datePred = query.filter.shared
              .whereType<JournalDatePredicate>()
              .first;
          expect(datePred.operator, DateOperator.between);
          expect(datePred.startDate, isNotNull);
          expect(datePred.endDate, isNotNull);
        });
      });

      group('recent', () {
        test('creates query for recent entries', () {
          final query = JournalQuery.recent(days: 7);

          expect(query.filter.shared, hasLength(1));
          final datePred = query.filter.shared
              .whereType<JournalDatePredicate>()
              .first;
          expect(datePred.operator, DateOperator.onOrAfter);
        });

        test('defaults to 7 days', () {
          final query = JournalQuery.recent();

          expect(query.filter.shared, hasLength(1));
        });
      });

      group('search', () {
        test('creates query for text search', () {
          final query = JournalQuery.search('grateful');

          expect(query.filter.shared, hasLength(1));
          final textPred = query.filter.shared
              .whereType<JournalTextPredicate>()
              .first;
          expect(textPred.operator, TextOperator.contains);
          expect(textPred.value, 'grateful');
        });
      });
    });

    group('helper properties', () {
      test('hasDateFilter returns true when date filter present', () {
        final query = JournalQuery.forDate(DateTime(2026, 1, 3));
        expect(query.hasDateFilter, isTrue);
      });

      test('hasDateFilter returns false when no date filter', () {
        final query = JournalQuery.byId('test-id');
        expect(query.hasDateFilter, isFalse);
      });

      test('hasIdFilter returns true when id filter present', () {
        final query = JournalQuery.byId('test-id');
        expect(query.hasIdFilter, isTrue);
      });

      test('hasIdFilter returns false when no id filter', () {
        final query = JournalQuery.all();
        expect(query.hasIdFilter, isFalse);
      });
    });

    group('modification methods', () {
      test('addPredicate adds predicate to filter', () {
        const query = JournalQuery();
        final newQuery = query.addPredicate(
          const JournalMoodPredicate(
            operator: MoodOperator.greaterThanOrEqual,
            value: MoodRating.good,
          ),
        );

        expect(newQuery.filter.shared, hasLength(1));
        expect(query.filter.shared, isEmpty); // Original unchanged
      });

      test('copyWith creates modified copy', () {
        const query = JournalQuery();
        final newQuery = query.copyWith(
          sortCriteria: const [
            SortCriterion(field: SortField.name),
          ],
        );

        expect(newQuery.sortCriteria, hasLength(1));
        expect(query.sortCriteria, isEmpty); // Original unchanged
      });
    });

    group('JSON serialization', () {
      test('toJson creates valid JSON', () {
        final query = JournalQuery.forDate(DateTime(2026, 1, 3));
        final json = query.toJson();

        expect(json.containsKey('filter'), isTrue);
        expect(json.containsKey('sortCriteria'), isTrue);
      });

      test('fromJson restores query', () {
        final original = JournalQuery.forDate(DateTime(2026, 1, 3));
        final json = original.toJson();
        final restored = JournalQuery.fromJson(json);

        expect(restored.filter.shared, hasLength(1));
        expect(restored.hasDateFilter, isTrue);
      });

      test('round-trip preserves query', () {
        final queries = [
          JournalQuery.all(),
          JournalQuery.byId('test-123'),
          JournalQuery.forDate(DateTime(2026, 1, 3)),
          JournalQuery.recent(days: 14),
          JournalQuery.search('test'),
        ];

        for (final original in queries) {
          final json = original.toJson();
          final restored = JournalQuery.fromJson(json);

          expect(
            restored.filter.shared.length,
            original.filter.shared.length,
            reason: 'Filter shared predicates should match',
          );
        }
      });
    });

    group('equality', () {
      test('equal queries are equal', () {
        final q1 = JournalQuery.byId('test');
        final q2 = JournalQuery.byId('test');

        expect(q1, equals(q2));
        expect(q1.hashCode, equals(q2.hashCode));
      });

      test('different queries are not equal', () {
        final q1 = JournalQuery.byId('test1');
        final q2 = JournalQuery.byId('test2');

        expect(q1, isNot(equals(q2)));
      });
    });
  });
}
