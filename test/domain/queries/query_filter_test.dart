import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fallback_values.dart';

import 'package:taskly_domain/taskly_domain.dart';
void main() {
  setUpAll(registerAllFallbackValues);

  group('QueryFilter', () {
    group('construction', () {
      test('creates empty filter with defaults', () {
        const filter = QueryFilter<TaskPredicate>();

        expect(filter.shared, isEmpty);
        expect(filter.orGroups, isEmpty);
      });

      test('creates matchAll filter', () {
        const filter = QueryFilter<TaskPredicate>.matchAll();

        expect(filter.shared, isEmpty);
        expect(filter.orGroups, isEmpty);
        expect(filter.isMatchAll, isTrue);
      });

      test('creates filter with shared predicates', () {
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(filter.shared, hasLength(1));
        expect(filter.orGroups, isEmpty);
      });

      test('creates filter with orGroups', () {
        const filter = QueryFilter<TaskPredicate>(
          orGroups: [
            [
              TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isTrue,
              ),
            ],
            [
              TaskProjectPredicate(operator: ProjectOperator.isNull),
            ],
          ],
        );

        expect(filter.shared, isEmpty);
        expect(filter.orGroups, hasLength(2));
      });

      test('creates filter with shared and orGroups', () {
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
            [
              TaskProjectPredicate(
                operator: ProjectOperator.matches,
                projectId: 'project-1',
              ),
            ],
          ],
        );

        expect(filter.shared, hasLength(1));
        expect(filter.orGroups, hasLength(2));
      });
    });

    group('isMatchAll', () {
      test('returns true when shared and orGroups are empty', () {
        const filter = QueryFilter<TaskPredicate>();

        expect(filter.isMatchAll, isTrue);
      });

      test('returns false when shared is not empty', () {
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(filter.isMatchAll, isFalse);
      });

      test('returns false when orGroups is not empty', () {
        const filter = QueryFilter<TaskPredicate>(
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
          ],
        );

        expect(filter.isMatchAll, isFalse);
      });
    });

    group('toDnfTerms', () {
      test('returns single term with shared when orGroups is empty', () {
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskProjectPredicate(operator: ProjectOperator.isNotNull),
          ],
        );

        final terms = filter.toDnfTerms();

        expect(terms, hasLength(1));
        expect(terms[0], hasLength(2));
      });

      test('returns terms with shared prepended to each orGroup', () {
        const sharedPredicate = TaskBoolPredicate(
          field: TaskBoolField.completed,
          operator: BoolOperator.isFalse,
        );
        const filter = QueryFilter<TaskPredicate>(
          shared: [sharedPredicate],
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
            [
              TaskProjectPredicate(
                operator: ProjectOperator.matches,
                projectId: 'p1',
              ),
            ],
          ],
        );

        final terms = filter.toDnfTerms();

        expect(terms, hasLength(2));
        // Each term starts with the shared predicate
        expect(terms[0][0], equals(sharedPredicate));
        expect(terms[1][0], equals(sharedPredicate));
        // Each term has its specific orGroup predicates after shared
        expect(terms[0][1], isA<TaskProjectPredicate>());
        expect(terms[1][1], isA<TaskProjectPredicate>());
      });

      test('returns empty term for matchAll filter', () {
        const filter = QueryFilter<TaskPredicate>.matchAll();

        final terms = filter.toDnfTerms();

        expect(terms, hasLength(1));
        expect(terms[0], isEmpty);
      });
    });

    group('copyWith', () {
      test('copies with shared change', () {
        const original = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        final copy = original.copyWith(
          shared: [
            const TaskProjectPredicate(operator: ProjectOperator.isNull),
          ],
        );

        expect(copy.shared, hasLength(1));
        expect(copy.shared[0], isA<TaskProjectPredicate>());
        expect(copy.orGroups, isEmpty);
      });

      test('copies with orGroups change', () {
        const original = QueryFilter<TaskPredicate>(
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
          ],
        );

        final copy = original.copyWith(
          orGroups: [
            [
              const TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isTrue,
              ),
            ],
          ],
        );

        expect(copy.orGroups, hasLength(1));
        expect(copy.orGroups[0][0], isA<TaskBoolPredicate>());
      });

      test('preserves unmodified fields', () {
        const original = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
          ],
        );

        final copy = original.copyWith(shared: []);

        expect(copy.shared, isEmpty);
        expect(copy.orGroups, hasLength(1));
      });
    });

    group('toJson', () {
      test('serializes empty filter', () {
        const filter = QueryFilter<TaskPredicate>();

        final json = filter.toJson((p) => p.toJson());

        expect(json['shared'], isEmpty);
        expect(json['orGroups'], isEmpty);
      });

      test('serializes filter with shared predicates', () {
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        final json = filter.toJson((p) => p.toJson());

        expect(json['shared'], hasLength(1));
        final shared = json['shared']! as List<dynamic>;
        expect((shared[0] as Map<String, dynamic>)['type'], 'bool');
      });

      test('serializes filter with orGroups', () {
        const filter = QueryFilter<TaskPredicate>(
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
            [
              TaskBoolPredicate(
                field: TaskBoolField.completed,
                operator: BoolOperator.isTrue,
              ),
            ],
          ],
        );

        final json = filter.toJson((p) => p.toJson());

        expect(json['orGroups'], hasLength(2));
        expect((json['orGroups'] as List)[0], hasLength(1));
        expect((json['orGroups'] as List)[1], hasLength(1));
      });
    });

    group('fromJson', () {
      test('parses empty filter', () {
        final json = <String, dynamic>{
          'shared': <dynamic>[],
          'orGroups': <dynamic>[],
        };

        final filter = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(filter.shared, isEmpty);
        expect(filter.orGroups, isEmpty);
        expect(filter.isMatchAll, isTrue);
      });

      test('parses filter with shared predicates', () {
        final json = <String, dynamic>{
          'shared': [
            {'type': 'bool', 'field': 'completed', 'operator': 'isFalse'},
          ],
          'orGroups': <dynamic>[],
        };

        final filter = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(filter.shared, hasLength(1));
        expect(filter.shared[0], isA<TaskBoolPredicate>());
      });

      test('parses filter with orGroups', () {
        final json = <String, dynamic>{
          'shared': <dynamic>[],
          'orGroups': [
            [
              {'type': 'project', 'operator': 'isNull'},
            ],
            [
              {'type': 'bool', 'field': 'completed', 'operator': 'isTrue'},
            ],
          ],
        };

        final filter = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(filter.orGroups, hasLength(2));
        expect(filter.orGroups[0][0], isA<TaskProjectPredicate>());
        expect(filter.orGroups[1][0], isA<TaskBoolPredicate>());
      });

      test('handles null shared and orGroups', () {
        final json = <String, dynamic>{};

        final filter = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(filter.shared, isEmpty);
        expect(filter.orGroups, isEmpty);
      });

      test('filters out non-map items from shared', () {
        final json = <String, dynamic>{
          'shared': [
            {'type': 'bool', 'field': 'completed', 'operator': 'isFalse'},
            'not-a-map',
            42,
            null,
          ],
          'orGroups': <dynamic>[],
        };

        final filter = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(filter.shared, hasLength(1));
      });

      test('filters out non-list items from orGroups', () {
        final json = <String, dynamic>{
          'shared': <dynamic>[],
          'orGroups': [
            [
              {'type': 'project', 'operator': 'isNull'},
            ],
            'not-a-list',
            42,
            null,
          ],
        };

        final filter = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(filter.orGroups, hasLength(1));
      });
    });

    group('equality', () {
      test('equal when shared and orGroups match', () {
        const filter1 = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
          ],
        );
        const filter2 = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
          ],
        );

        expect(filter1, equals(filter2));
        expect(filter1.hashCode, filter2.hashCode);
      });

      test('not equal when shared differs', () {
        const filter1 = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );
        const filter2 = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isTrue,
            ),
          ],
        );

        expect(filter1, isNot(equals(filter2)));
      });

      test('not equal when orGroups differs', () {
        const filter1 = QueryFilter<TaskPredicate>(
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
          ],
        );
        const filter2 = QueryFilter<TaskPredicate>(
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNotNull)],
          ],
        );

        expect(filter1, isNot(equals(filter2)));
      });

      test('equal for empty filters', () {
        const filter1 = QueryFilter<TaskPredicate>();
        const filter2 = QueryFilter<TaskPredicate>.matchAll();

        expect(filter1, equals(filter2));
      });
    });

    group('toString', () {
      test('returns matchAll string for empty filter', () {
        const filter = QueryFilter<TaskPredicate>.matchAll();

        expect(filter.toString(), 'QueryFilter.matchAll()');
      });

      test('returns descriptive string for non-empty filter', () {
        const filter = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
        );

        expect(filter.toString(), contains('QueryFilter'));
        expect(filter.toString(), contains('shared'));
      });
    });

    group('round-trip serialization', () {
      test('round-trips empty filter', () {
        const original = QueryFilter<TaskPredicate>.matchAll();

        final json = original.toJson((p) => p.toJson());
        final restored = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(restored, equals(original));
      });

      test('round-trips filter with shared predicates', () {
        const original = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
            TaskProjectPredicate(
              operator: ProjectOperator.matches,
              projectId: 'project-1',
            ),
          ],
        );

        final json = original.toJson((p) => p.toJson());
        final restored = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(restored, equals(original));
      });

      test('round-trips filter with orGroups', () {
        const original = QueryFilter<TaskPredicate>(
          shared: [
            TaskBoolPredicate(
              field: TaskBoolField.completed,
              operator: BoolOperator.isFalse,
            ),
          ],
          orGroups: [
            [TaskProjectPredicate(operator: ProjectOperator.isNull)],
            [
              TaskProjectPredicate(
                operator: ProjectOperator.matches,
                projectId: 'p1',
              ),
            ],
          ],
        );

        final json = original.toJson((p) => p.toJson());
        final restored = QueryFilter.fromJson<TaskPredicate>(
          json,
          TaskPredicate.fromJson,
        );

        expect(restored, equals(original));
      });
    });
  });
}
