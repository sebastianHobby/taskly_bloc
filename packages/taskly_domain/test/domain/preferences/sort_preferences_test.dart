@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/core.dart';

void main() {
  testSafe('SortCriterion.fromJson normalizes asc/desc aliases', () async {
    final asc = SortCriterion.fromJson(const <String, dynamic>{
      'field': 'name',
      'direction': 'asc',
    });
    expect(asc.direction, SortDirection.ascending);

    final desc = SortCriterion.fromJson(const <String, dynamic>{
      'field': 'name',
      'direction': 'desc',
    });
    expect(desc.direction, SortDirection.descending);
  });

  testSafe(
    'SortPreferences.fromJson falls back to defaultCriteria when empty',
    () async {
      final prefs = SortPreferences.fromJson(const <String, dynamic>{
        'criteria': <dynamic>[],
      });

      expect(prefs.criteria, SortPreferences.defaultCriteria);
    },
  );

  testSafe(
    'SortPreferences.sanitizedCriteria filters unavailable and removes duplicates',
    () async {
      const prefs = SortPreferences(
        criteria: [
          SortCriterion(field: SortField.deadlineDate),
          SortCriterion(field: SortField.deadlineDate),
          SortCriterion(field: SortField.name),
        ],
      );

      final sanitized = prefs.sanitizedCriteria(
        const [SortField.name],
      );

      expect(sanitized, [const SortCriterion(field: SortField.name)]);
    },
  );

  testSafe(
    'SortPreferences.sanitizedCriteria guarantees at least one criterion',
    () async {
      const prefs = SortPreferences(criteria: []);

      final sanitized = prefs.sanitizedCriteria(const []);
      expect(sanitized, [const SortCriterion(field: SortField.name)]);
    },
  );
}
