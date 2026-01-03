import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/label_predicate.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';

void main() {
  group('LabelQuery', () {
    group('construction', () {
      test('creates with defaults', () {
        const query = LabelQuery();

        expect(query.filter.isMatchAll, isTrue);
        expect(query.sortCriteria, isEmpty);
      });

      test('creates with custom filter', () {
        const query = LabelQuery(
          filter: QueryFilter<LabelPredicate>(
            shared: [LabelTypePredicate(labelType: LabelType.value)],
          ),
        );

        expect(query.filter.shared, hasLength(1));
        expect(query.filter.isMatchAll, isFalse);
      });

      test('creates with sort criteria', () {
        const query = LabelQuery(
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );

        expect(query.sortCriteria, hasLength(1));
      });
    });

    group('factory constructors', () {
      group('values', () {
        test('creates query filtering for values only', () {
          final query = LabelQuery.values();

          expect(query.filter.shared, hasLength(1));
          final typePred = query.filter.shared
              .whereType<LabelTypePredicate>()
              .first;
          expect(typePred.labelType, LabelType.value);
        });

        test('values uses default sort criteria', () {
          final query = LabelQuery.values();

          expect(query.sortCriteria, isNotEmpty);
          expect(query.sortCriteria[0].field, SortField.name);
        });

        test('values accepts custom sort criteria', () {
          final query = LabelQuery.values(
            sortCriteria: const [
              SortCriterion(
                field: SortField.createdDate,
                direction: SortDirection.descending,
              ),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
          expect(query.sortCriteria[0].field, SortField.createdDate);
        });
      });

      group('labelsOnly', () {
        test('creates query filtering for labels only', () {
          final query = LabelQuery.labelsOnly();

          expect(query.filter.shared, hasLength(1));
          final typePred = query.filter.shared
              .whereType<LabelTypePredicate>()
              .first;
          expect(typePred.labelType, LabelType.label);
        });

        test('labelsOnly uses default sort criteria', () {
          final query = LabelQuery.labelsOnly();

          expect(query.sortCriteria, isNotEmpty);
        });

        test('labelsOnly accepts custom sort criteria', () {
          final query = LabelQuery.labelsOnly(
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
        });
      });

      group('byId', () {
        test('creates query filtering by single ID', () {
          final query = LabelQuery.byId('label-123');

          expect(query.filter.shared, hasLength(1));
          final idPred = query.filter.shared
              .whereType<LabelIdPredicate>()
              .first;
          expect(idPred.labelId, 'label-123');
        });
      });

      group('byIds', () {
        test('creates query filtering by multiple IDs', () {
          final query = LabelQuery.byIds(const [
            'label-1',
            'label-2',
            'label-3',
          ]);

          expect(query.filter.shared, hasLength(1));
          final idsPred = query.filter.shared
              .whereType<LabelIdsPredicate>()
              .first;
          expect(idsPred.labelIds, hasLength(3));
          expect(idsPred.labelIds, contains('label-1'));
        });
      });

      group('all', () {
        test('creates query with no filter', () {
          final query = LabelQuery.all();

          expect(query.filter.isMatchAll, isTrue);
        });

        test('all uses default sort criteria', () {
          final query = LabelQuery.all();

          expect(query.sortCriteria, isNotEmpty);
        });

        test('all accepts custom sort criteria', () {
          final query = LabelQuery.all(
            sortCriteria: const [
              SortCriterion(
                field: SortField.updatedDate,
                direction: SortDirection.descending,
              ),
            ],
          );

          expect(query.sortCriteria[0].field, SortField.updatedDate);
        });
      });

      group('search', () {
        test('creates query with name search filter', () {
          final query = LabelQuery.search('work');

          expect(query.filter.shared, hasLength(1));
          final namePred = query.filter.shared
              .whereType<LabelNamePredicate>()
              .first;
          expect(namePred.value, 'work');
          expect(namePred.operator, StringOperator.contains);
        });

        test('search uses default sort criteria', () {
          final query = LabelQuery.search('test');

          expect(query.sortCriteria, isNotEmpty);
        });

        test('search accepts custom sort criteria', () {
          final query = LabelQuery.search(
            'test',
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
        });
      });

      group('byColor', () {
        test('creates query filtering by color', () {
          final query = LabelQuery.byColor('#FF0000');

          expect(query.filter.shared, hasLength(1));
          final colorPred = query.filter.shared
              .whereType<LabelColorPredicate>()
              .first;
          expect(colorPred.colorHex, '#FF0000');
        });

        test('byColor uses default sort criteria', () {
          final query = LabelQuery.byColor('#00FF00');

          expect(query.sortCriteria, isNotEmpty);
        });

        test('byColor accepts custom sort criteria', () {
          final query = LabelQuery.byColor(
            '#0000FF',
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );

          expect(query.sortCriteria, hasLength(1));
        });
      });
    });

    group('helper properties', () {
      group('hasTypeFilter', () {
        test('returns false when no type predicates', () {
          const query = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              shared: [LabelNamePredicate(value: 'test')],
            ),
          );

          expect(query.hasTypeFilter, isFalse);
        });

        test('returns true when type predicate in shared', () {
          const query = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              shared: [LabelTypePredicate(labelType: LabelType.value)],
            ),
          );

          expect(query.hasTypeFilter, isTrue);
        });

        test('returns true when type predicate in orGroups', () {
          const query = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              orGroups: [
                [LabelTypePredicate(labelType: LabelType.label)],
              ],
            ),
          );

          expect(query.hasTypeFilter, isTrue);
        });
      });

      group('hasIdFilter', () {
        test('returns false when no ID predicates', () {
          const query = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              shared: [LabelNamePredicate(value: 'test')],
            ),
          );

          expect(query.hasIdFilter, isFalse);
        });

        test('returns true when LabelIdPredicate in shared', () {
          const query = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              shared: [LabelIdPredicate(labelId: 'label-123')],
            ),
          );

          expect(query.hasIdFilter, isTrue);
        });

        test('returns true when LabelIdsPredicate in shared', () {
          const query = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              shared: [
                LabelIdsPredicate(labelIds: ['a', 'b']),
              ],
            ),
          );

          expect(query.hasIdFilter, isTrue);
        });

        test('returns true when ID predicate in orGroups', () {
          const query = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              orGroups: [
                [LabelIdPredicate(labelId: 'label-123')],
              ],
            ),
          );

          expect(query.hasIdFilter, isTrue);
        });
      });
    });

    group('modification methods', () {
      group('addPredicate', () {
        test('adds predicate to shared filter', () {
          const original = LabelQuery();
          final modified = original.addPredicate(
            const LabelTypePredicate(labelType: LabelType.value),
          );

          expect(modified.filter.shared, hasLength(1));
          expect(original.filter.isMatchAll, isTrue);
        });

        test('preserves existing predicates', () {
          const original = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              shared: [LabelNamePredicate(value: 'test')],
            ),
          );
          final modified = original.addPredicate(
            const LabelTypePredicate(labelType: LabelType.value),
          );

          expect(modified.filter.shared, hasLength(2));
          expect(
            modified.filter.shared[0],
            isA<LabelNamePredicate>(),
          );
          expect(
            modified.filter.shared[1],
            isA<LabelTypePredicate>(),
          );
        });
      });

      group('copyWith', () {
        test('copies with filter change', () {
          const original = LabelQuery();
          final copy = original.copyWith(
            filter: const QueryFilter<LabelPredicate>(
              shared: [LabelTypePredicate(labelType: LabelType.value)],
            ),
          );

          expect(copy.filter.shared, hasLength(1));
          expect(original.filter.isMatchAll, isTrue);
        });

        test('copies with sort criteria change', () {
          const original = LabelQuery();
          final copy = original.copyWith(
            sortCriteria: [
              const SortCriterion(field: SortField.name),
            ],
          );

          expect(copy.sortCriteria, hasLength(1));
        });

        test('preserves unmodified fields', () {
          final original = LabelQuery(
            filter: const QueryFilter<LabelPredicate>(
              shared: [LabelTypePredicate(labelType: LabelType.value)],
            ),
            sortCriteria: const [
              SortCriterion(field: SortField.name),
            ],
          );
          final copy = original.copyWith(
            sortCriteria: [
              const SortCriterion(field: SortField.createdDate),
            ],
          );

          expect(copy.filter.shared, hasLength(1));
          expect(copy.sortCriteria[0].field, SortField.createdDate);
        });
      });
    });

    group('serialization', () {
      group('toJson', () {
        test('serializes query to json', () {
          const query = LabelQuery(
            filter: QueryFilter<LabelPredicate>(
              shared: [LabelTypePredicate(labelType: LabelType.value)],
            ),
            sortCriteria: [
              SortCriterion(field: SortField.name),
            ],
          );
          final json = query.toJson();

          expect(json['filter'], isA<Map>());
          expect(json['sortCriteria'], isA<List>());
        });
      });

      group('fromJson', () {
        test('deserializes query from json', () {
          final json = {
            'filter': {
              'shared': [
                {'type': 'type', 'labelType': 'value'},
              ],
            },
            'sortCriteria': [
              {'field': 'name', 'direction': 'ascending'},
            ],
          };
          final query = LabelQuery.fromJson(json);

          expect(query.filter.shared, hasLength(1));
          expect(query.sortCriteria, hasLength(1));
        });

        test('handles empty json', () {
          final json = <String, dynamic>{};
          final query = LabelQuery.fromJson(json);

          expect(query.filter.isMatchAll, isTrue);
          expect(query.sortCriteria, isEmpty);
        });
      });

      test('round-trip serialization preserves data', () {
        const original = LabelQuery(
          filter: QueryFilter<LabelPredicate>(
            shared: [
              LabelTypePredicate(labelType: LabelType.value),
              LabelNamePredicate(value: 'test'),
            ],
          ),
          sortCriteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(
              field: SortField.createdDate,
              direction: SortDirection.descending,
            ),
          ],
        );

        final json = original.toJson();
        final restored = LabelQuery.fromJson(json);

        expect(restored.filter.shared, hasLength(2));
        expect(restored.sortCriteria, hasLength(2));
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        const query1 = LabelQuery(
          filter: QueryFilter<LabelPredicate>(
            shared: [LabelTypePredicate(labelType: LabelType.value)],
          ),
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );
        const query2 = LabelQuery(
          filter: QueryFilter<LabelPredicate>(
            shared: [LabelTypePredicate(labelType: LabelType.value)],
          ),
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );

        expect(query1, equals(query2));
        expect(query1.hashCode, query2.hashCode);
      });

      test('not equal when filter differs', () {
        const query1 = LabelQuery(
          filter: QueryFilter<LabelPredicate>(
            shared: [LabelTypePredicate(labelType: LabelType.value)],
          ),
        );
        const query2 = LabelQuery(
          filter: QueryFilter<LabelPredicate>(
            shared: [LabelTypePredicate(labelType: LabelType.label)],
          ),
        );

        expect(query1, isNot(equals(query2)));
      });

      test('not equal when sort criteria differs', () {
        const query1 = LabelQuery(
          sortCriteria: [
            SortCriterion(field: SortField.name),
          ],
        );
        const query2 = LabelQuery(
          sortCriteria: [
            SortCriterion(field: SortField.createdDate),
          ],
        );

        expect(query1, isNot(equals(query2)));
      });
    });
  });

  group('ValueQuery type alias', () {
    test('ValueQuery is alias for LabelQuery', () {
      final valueQuery = LabelQuery.values();

      // ValueQuery should be usable as LabelQuery
      expect(valueQuery, isA<ValueQuery>());
      expect(valueQuery, isA<LabelQuery>());
    });
  });
}
