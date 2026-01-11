import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/preferences/model/sort_preferences.dart';

void main() {
  group('SortField', () {
    test('has expected values', () {
      expect(SortField.values, [
        SortField.name,
        SortField.startDate,
        SortField.deadlineDate,
        SortField.createdDate,
        SortField.updatedDate,
      ]);
    });
  });

  group('SortDirection', () {
    test('has expected values', () {
      expect(SortDirection.values, [
        SortDirection.ascending,
        SortDirection.descending,
      ]);
    });
  });

  group('SortCriterion', () {
    group('constructor', () {
      test('creates with required field', () {
        const criterion = SortCriterion(field: SortField.name);

        expect(criterion.field, SortField.name);
        expect(criterion.direction, SortDirection.ascending);
      });

      test('creates with custom direction', () {
        const criterion = SortCriterion(
          field: SortField.name,
          direction: SortDirection.descending,
        );

        expect(criterion.field, SortField.name);
        expect(criterion.direction, SortDirection.descending);
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final criterion = SortCriterion.fromJson(const {
          'field': 'deadlineDate',
          'direction': 'descending',
        });

        expect(criterion.field, SortField.deadlineDate);
        expect(criterion.direction, SortDirection.descending);
      });

      test('defaults to name when field is null', () {
        final criterion = SortCriterion.fromJson(const {
          'direction': 'ascending',
        });

        expect(criterion.field, SortField.name);
      });

      test('defaults to ascending when direction is null', () {
        final criterion = SortCriterion.fromJson(const {
          'field': 'name',
        });

        expect(criterion.direction, SortDirection.ascending);
      });

      test('handles legacy asc direction', () {
        final criterion = SortCriterion.fromJson(const {
          'field': 'name',
          'direction': 'asc',
        });

        expect(criterion.direction, SortDirection.ascending);
      });

      test('handles legacy desc direction', () {
        final criterion = SortCriterion.fromJson(const {
          'field': 'name',
          'direction': 'desc',
        });

        expect(criterion.direction, SortDirection.descending);
      });
    });

    group('toJson', () {
      test('serializes to correct format', () {
        const criterion = SortCriterion(
          field: SortField.startDate,
          direction: SortDirection.descending,
        );

        final json = criterion.toJson();

        expect(json, {
          'field': 'startDate',
          'direction': 'descending',
        });
      });

      test('round-trip serialization preserves values', () {
        const original = SortCriterion(
          field: SortField.createdDate,
          direction: SortDirection.ascending,
        );

        final json = original.toJson();
        final restored = SortCriterion.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('updates field only', () {
        const original = SortCriterion(
          field: SortField.name,
          direction: SortDirection.ascending,
        );

        final copy = original.copyWith(field: SortField.deadlineDate);

        expect(copy.field, SortField.deadlineDate);
        expect(copy.direction, SortDirection.ascending);
      });

      test('updates direction only', () {
        const original = SortCriterion(
          field: SortField.name,
          direction: SortDirection.ascending,
        );

        final copy = original.copyWith(direction: SortDirection.descending);

        expect(copy.field, SortField.name);
        expect(copy.direction, SortDirection.descending);
      });

      test('returns equivalent when no parameters', () {
        const original = SortCriterion(
          field: SortField.name,
          direction: SortDirection.ascending,
        );

        final copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const a = SortCriterion(
          field: SortField.name,
          direction: SortDirection.ascending,
        );
        const b = SortCriterion(
          field: SortField.name,
          direction: SortDirection.ascending,
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different fields are not equal', () {
        const a = SortCriterion(
          field: SortField.name,
          direction: SortDirection.ascending,
        );
        const b = SortCriterion(
          field: SortField.startDate,
          direction: SortDirection.ascending,
        );

        expect(a, isNot(b));
      });

      test('different directions are not equal', () {
        const a = SortCriterion(
          field: SortField.name,
          direction: SortDirection.ascending,
        );
        const b = SortCriterion(
          field: SortField.name,
          direction: SortDirection.descending,
        );

        expect(a, isNot(b));
      });
    });
  });

  group('SortPreferences', () {
    group('constructor', () {
      test('creates with default criteria', () {
        const prefs = SortPreferences();

        expect(prefs.criteria.length, 4);
        expect(prefs.criteria[0].field, SortField.deadlineDate);
        expect(prefs.criteria[1].field, SortField.startDate);
        expect(prefs.criteria[2].field, SortField.createdDate);
        expect(prefs.criteria[3].field, SortField.name);
      });

      test('creates with custom criteria', () {
        const prefs = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(field: SortField.updatedDate),
          ],
        );

        expect(prefs.criteria.length, 2);
        expect(prefs.criteria[0].field, SortField.name);
        expect(prefs.criteria[1].field, SortField.updatedDate);
      });
    });

    group('fromJson', () {
      test('parses valid JSON', () {
        final prefs = SortPreferences.fromJson(const {
          'criteria': [
            {'field': 'name', 'direction': 'ascending'},
            {'field': 'deadlineDate', 'direction': 'descending'},
          ],
        });

        expect(prefs.criteria.length, 2);
        expect(prefs.criteria[0].field, SortField.name);
        expect(prefs.criteria[1].field, SortField.deadlineDate);
        expect(prefs.criteria[1].direction, SortDirection.descending);
      });

      test('returns defaults when criteria is null', () {
        final prefs = SortPreferences.fromJson(const {});

        expect(prefs.criteria.length, 4);
        expect(prefs.criteria[0].field, SortField.deadlineDate);
      });

      test('returns defaults when criteria is empty', () {
        final prefs = SortPreferences.fromJson(const {'criteria': <dynamic>[]});

        expect(prefs.criteria.length, 4);
        expect(prefs.criteria[0].field, SortField.deadlineDate);
      });
    });

    group('toJson', () {
      test('serializes to correct format', () {
        const prefs = SortPreferences(
          criteria: [
            SortCriterion(
              field: SortField.name,
              direction: SortDirection.descending,
            ),
          ],
        );

        final json = prefs.toJson();

        expect(json, {
          'criteria': [
            {'field': 'name', 'direction': 'descending'},
          ],
        });
      });

      test('round-trip serialization preserves values', () {
        const original = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.startDate),
            SortCriterion(
              field: SortField.name,
              direction: SortDirection.descending,
            ),
          ],
        );

        final json = original.toJson();
        final restored = SortPreferences.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('updates criteria', () {
        const original = SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        );

        final copy = original.copyWith(
          criteria: [SortCriterion(field: SortField.deadlineDate)],
        );

        expect(copy.criteria.length, 1);
        expect(copy.criteria[0].field, SortField.deadlineDate);
      });

      test('returns equivalent when no parameters', () {
        const original = SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        );

        final copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('sanitizedCriteria', () {
      test('filters out unavailable fields', () {
        const prefs = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.startDate),
          ],
        );

        final sanitized = prefs.sanitizedCriteria([
          SortField.name,
          SortField.startDate,
        ]);

        expect(sanitized.length, 2);
        expect(sanitized[0].field, SortField.name);
        expect(sanitized[1].field, SortField.startDate);
      });

      test('removes duplicate fields', () {
        const prefs = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(
              field: SortField.name,
              direction: SortDirection.descending,
            ),
          ],
        );

        final sanitized = prefs.sanitizedCriteria([SortField.name]);

        expect(sanitized.length, 1);
        expect(sanitized[0].field, SortField.name);
        // Should keep the first one
        expect(sanitized[0].direction, SortDirection.ascending);
      });

      test('returns first available field when all filtered', () {
        const prefs = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.deadlineDate),
          ],
        );

        final sanitized = prefs.sanitizedCriteria([
          SortField.name,
          SortField.startDate,
        ]);

        expect(sanitized.length, 1);
        expect(sanitized[0].field, SortField.name);
      });

      test('returns name when available fields empty', () {
        const prefs = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.deadlineDate),
          ],
        );

        final sanitized = prefs.sanitizedCriteria([]);

        expect(sanitized.length, 1);
        expect(sanitized[0].field, SortField.name);
      });
    });

    group('equality', () {
      test('equal instances are equal', () {
        const a = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(field: SortField.deadlineDate),
          ],
        );
        const b = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(field: SortField.deadlineDate),
          ],
        );

        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different criteria are not equal', () {
        const a = SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        );
        const b = SortPreferences(
          criteria: [SortCriterion(field: SortField.deadlineDate)],
        );

        expect(a, isNot(b));
      });

      test('different length criteria are not equal', () {
        const a = SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        );
        const b = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(field: SortField.deadlineDate),
          ],
        );

        expect(a, isNot(b));
      });

      test('same order matters for equality', () {
        const a = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.name),
            SortCriterion(field: SortField.deadlineDate),
          ],
        );
        const b = SortPreferences(
          criteria: [
            SortCriterion(field: SortField.deadlineDate),
            SortCriterion(field: SortField.name),
          ],
        );

        expect(a, isNot(b));
      });

      test('identical returns true for same instance', () {
        const a = SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        );

        expect(a == a, isTrue);
      });

      test('equals returns false for different type', () {
        const a = SortPreferences(
          criteria: [SortCriterion(field: SortField.name)],
        );

        // ignore: unrelated_type_equality_checks
        expect(a == 'not a SortPreferences', isFalse);
      });
    });
  });
}
