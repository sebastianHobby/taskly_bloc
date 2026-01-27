@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/preferences/model/sort_preferences.dart';
import 'package:taskly_domain/src/queries/journal_predicate.dart';
import 'package:taskly_domain/src/queries/journal_query.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show DateOperator;

void main() {
  testSafe('JournalQuery.forDate uses dateOnly semantics', () async {
    final q = JournalQuery.forDate(DateTime.utc(2026, 1, 18, 10, 30));

    final p = q.filter.shared.whereType<JournalDatePredicate>().single;
    expect(p.operator, DateOperator.on);
    expect(p.date, DateTime.utc(2026, 1, 18));
    expect(q.hasDateFilter, isTrue);
  });

  testSafe(
    'JournalQuery.recent uses onOrAfter with computed startDate',
    () async {
      final today = DateTime.utc(2026, 1, 18);
      final q = JournalQuery.recent(todayDayKeyUtc: today, days: 7);

      final p = q.filter.shared.whereType<JournalDatePredicate>().single;
      expect(p.operator, DateOperator.onOrAfter);
      expect(p.date, DateTime.utc(2026, 1, 11));
    },
  );

  testSafe('JournalQuery JSON roundtrip', () async {
    final q = JournalQuery.forDate(DateTime.utc(2026, 1, 18));

    final decoded = JournalQuery.fromJson(q.toJson());
    expect(decoded, equals(q));
  });

  testSafe('JournalQuery.copyWith replaces fields', () async {
    final base = JournalQuery.forDate(DateTime.utc(2026, 1, 18));
    final updated = base.copyWith(
      sortCriteria: const [SortCriterion(field: SortField.createdDate)],
    );

    expect(updated.filter, base.filter);
    expect(updated.sortCriteria, isNot(equals(base.sortCriteria)));
  });
}
