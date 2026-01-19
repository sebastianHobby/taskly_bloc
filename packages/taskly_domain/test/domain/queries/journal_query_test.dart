@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/journal/model/mood_rating.dart';
import 'package:taskly_domain/src/preferences/model/sort_preferences.dart';
import 'package:taskly_domain/src/queries/journal_predicate.dart';
import 'package:taskly_domain/src/queries/journal_query.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show DateOperator;

void main() {
  testSafe('JournalQuery.all uses default sort criteria', () async {
    final q = JournalQuery.all();
    expect(q.sortCriteria, hasLength(1));
    expect(q.sortCriteria.single.field, SortField.createdDate);
    expect(q.sortCriteria.single.direction, SortDirection.descending);
  });

  testSafe(
    'JournalQuery.byId hasIdFilter and builds shared predicate',
    () async {
      final q = JournalQuery.byId('j1');

      expect(q.hasIdFilter, isTrue);
      expect(
        q.filter.shared.single,
        equals(const JournalIdPredicate(id: 'j1')),
      );
    },
  );

  testSafe('JournalQuery.forDate uses dateOnly semantics', () async {
    final q = JournalQuery.forDate(DateTime.utc(2026, 1, 18, 10, 30));

    final p = q.filter.shared.whereType<JournalDatePredicate>().single;
    expect(p.operator, DateOperator.on);
    expect(p.date, DateTime.utc(2026, 1, 18));
    expect(q.hasDateFilter, isTrue);
  });

  testSafe('JournalQuery.dateRange uses between and dateOnly', () async {
    final q = JournalQuery.dateRange(
      startDate: DateTime.utc(2026, 1, 18, 10),
      endDate: DateTime.utc(2026, 1, 20, 23, 59),
    );

    final p = q.filter.shared.whereType<JournalDatePredicate>().single;
    expect(p.operator, DateOperator.between);
    expect(p.startDate, DateTime.utc(2026, 1, 18));
    expect(p.endDate, DateTime.utc(2026, 1, 20));
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

  testSafe('JournalQuery.moodAtLeast maps moodValue to MoodRating', () async {
    final q = JournalQuery.moodAtLeast(MoodOperator.greaterThanOrEqual, 4);

    final p = q.filter.shared.whereType<JournalMoodPredicate>().single;
    expect(p.operator, MoodOperator.greaterThanOrEqual);
    expect(p.value, MoodRating.fromValue(4));
  });

  testSafe('JournalQuery.search builds contains text predicate', () async {
    final q = JournalQuery.search('focus');

    final p = q.filter.shared.whereType<JournalTextPredicate>().single;
    expect(p.operator, TextOperator.contains);
    expect(p.value, 'focus');
  });

  testSafe('JournalQuery JSON roundtrip', () async {
    final q = JournalQuery.search('term').addPredicate(
      const JournalMoodPredicate(operator: MoodOperator.isNotNull),
    );

    final decoded = JournalQuery.fromJson(q.toJson());
    expect(decoded, equals(q));
  });

  testSafe('JournalQuery.copyWith replaces fields', () async {
    final base = JournalQuery.byId('j1');
    final updated = base.copyWith(
      sortCriteria: const [SortCriterion(field: SortField.createdDate)],
    );

    expect(updated.filter, base.filter);
    expect(updated.sortCriteria, isNot(equals(base.sortCriteria)));
  });
}
