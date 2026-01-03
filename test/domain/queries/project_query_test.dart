import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/label_match_mode.dart';
import 'package:taskly_bloc/domain/queries/occurrence_expansion.dart';
import 'package:taskly_bloc/domain/queries/project_predicate.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart'
    show BoolOperator, DateOperator, LabelOperator;

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
      group('byId', () {
        test('creates project query with ID filter', () {
          final query = ProjectQuery.byId('project-123');

          expect(query.filter.shared, hasLength(1));

          final idPred = query.filter.shared
              .whereType<ProjectIdPredicate>()
              .first;
          expect(idPred.id, 'project-123');
        });
      });

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

      group('active', () {
        test('creates same query as incomplete (alias)', () {
          final activeQuery = ProjectQuery.active();
          final incompleteQuery = ProjectQuery.incomplete();

          expect(
            activeQuery.filter.shared.length,
            incompleteQuery.filter.shared.length,
          );

          final activeBool = activeQuery.filter.shared
              .whereType<ProjectBoolPredicate>()
              .first;
          final incompleteBool = incompleteQuery.filter.shared
              .whereType<ProjectBoolPredicate>()
              .first;

          expect(activeBool.field, incompleteBool.field);
          expect(activeBool.operator, incompleteBool.operator);
        });

        test('active accepts custom sort criteria', () {
          final query = ProjectQuery.active(
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
        });
      });

      group('completed', () {
        test('creates query filtering for completed projects', () {
          final query = ProjectQuery.completed();

          expect(query.filter.shared, hasLength(1));

          final boolPred = query.filter.shared
              .whereType<ProjectBoolPredicate>()
              .first;
          expect(boolPred.field, ProjectBoolField.completed);
          expect(boolPred.operator, BoolOperator.isTrue);
        });

        test('completed uses default sort criteria', () {
          final query = ProjectQuery.completed();

          expect(query.sortCriteria, isNotEmpty);
        });

        test('completed accepts custom sort criteria', () {
          final query = ProjectQuery.completed(
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
        });
      });

      group('byLabels', () {
        test('creates query filtering by label IDs with any mode', () {
          final query = ProjectQuery.byLabels(
            const ['label-1', 'label-2'],
            mode: LabelMatchMode.any,
          );

          expect(query.filter.shared, hasLength(1));

          final labelPred = query.filter.shared
              .whereType<ProjectLabelPredicate>()
              .first;
          expect(labelPred.operator, LabelOperator.hasAny);
          expect(labelPred.labelIds, ['label-1', 'label-2']);
        });

        test('creates query filtering by label IDs with all mode', () {
          final query = ProjectQuery.byLabels(
            const ['label-1', 'label-2'],
            mode: LabelMatchMode.all,
          );

          final labelPred = query.filter.shared
              .whereType<ProjectLabelPredicate>()
              .first;
          expect(labelPred.operator, LabelOperator.hasAll);
        });

        test('creates query filtering by label IDs with none mode', () {
          final query = ProjectQuery.byLabels(
            const ['label-1'],
            mode: LabelMatchMode.none,
          );

          final labelPred = query.filter.shared
              .whereType<ProjectLabelPredicate>()
              .first;
          expect(labelPred.operator, LabelOperator.isNull);
        });

        test('byLabels can filter by value type', () {
          final query = ProjectQuery.byLabels(
            const ['value-1'],
            labelType: LabelType.value,
          );

          final labelPred = query.filter.shared
              .whereType<ProjectLabelPredicate>()
              .first;
          expect(labelPred.labelType, LabelType.value);
        });

        test('byLabels uses default sort criteria', () {
          final query = ProjectQuery.byLabels(const ['label-1']);

          expect(query.sortCriteria, isNotEmpty);
        });

        test('byLabels accepts custom sort criteria', () {
          final query = ProjectQuery.byLabels(
            const ['label-1'],
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
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

    group('serialization', () {
      group('toJson', () {
        test('serializes query to json', () {
          final query = ProjectQuery.incomplete();
          final json = query.toJson();

          expect(json['filter'], isA<Map>());
          expect(json['sortCriteria'], isA<List>());
          expect(json['occurrenceExpansion'], isNull);
        });

        test('serializes query with occurrence expansion', () {
          final query = ProjectQuery.schedule(
            rangeStart: DateTime.utc(2025, 6, 1),
            rangeEnd: DateTime.utc(2025, 6, 30),
          );
          final json = query.toJson();

          expect(json['occurrenceExpansion'], isA<Map>());
        });
      });

      group('fromJson', () {
        test('deserializes query from json', () {
          final json = {
            'filter': {
              'shared': [
                {
                  'type': 'bool',
                  'field': 'completed',
                  'operator': 'isFalse',
                },
              ],
            },
            'sortCriteria': [
              {'field': 'name', 'direction': 'ascending'},
            ],
          };
          final query = ProjectQuery.fromJson(json);

          expect(query.filter.shared, hasLength(1));
          expect(query.sortCriteria, hasLength(1));
        });

        test('handles empty json', () {
          final json = <String, dynamic>{};
          final query = ProjectQuery.fromJson(json);

          expect(query.filter.isMatchAll, isTrue);
          expect(query.sortCriteria, isEmpty);
        });

        test('deserializes with occurrence expansion', () {
          final json = {
            'filter': {'shared': <dynamic>[]},
            'sortCriteria': <dynamic>[],
            'occurrenceExpansion': {
              'rangeStart': '2025-06-01T00:00:00.000Z',
              'rangeEnd': '2025-06-30T00:00:00.000Z',
            },
          };
          final query = ProjectQuery.fromJson(json);

          expect(query.occurrenceExpansion, isNotNull);
        });
      });

      test('round-trip serialization preserves data', () {
        final original = ProjectQuery.schedule(
          rangeStart: DateTime.utc(2025, 6, 1),
          rangeEnd: DateTime.utc(2025, 6, 30),
        );

        final json = original.toJson();
        final restored = ProjectQuery.fromJson(json);

        expect(restored.filter.shared.length, original.filter.shared.length);
        expect(restored.shouldExpandOccurrences, isTrue);
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
