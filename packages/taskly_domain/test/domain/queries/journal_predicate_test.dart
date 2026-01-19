@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';

import 'package:taskly_domain/src/journal/model/mood_rating.dart';
import 'package:taskly_domain/src/queries/journal_predicate.dart';
import 'package:taskly_domain/src/queries/task_predicate.dart'
    show DateOperator, RelativeComparison;

void main() {
  testSafe('JournalPredicate.fromJson throws on unknown type', () async {
    expect(
      () => JournalPredicate.fromJson(const <String, dynamic>{'type': 'nope'}),
      throwsArgumentError,
    );
  });

  testSafe('JournalIdPredicate JSON roundtrip', () async {
    const p = JournalIdPredicate(id: 'j1');
    final decoded = JournalPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('JournalDatePredicate JSON roundtrip (between)', () async {
    final p = JournalDatePredicate(
      operator: DateOperator.between,
      startDate: DateTime.utc(2026, 1, 1),
      endDate: DateTime.utc(2026, 1, 31),
    );

    final decoded = JournalPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe(
    'JournalDatePredicate.fromJson uses defaults and parses date',
    () async {
      final decoded = JournalDatePredicate.fromJson(const <String, dynamic>{
        'type': 'date',
        'date': '2026-01-02T05:00:00Z',
      });

      expect(decoded.operator, DateOperator.on);
      expect(decoded.date, DateTime.parse('2026-01-02T05:00:00Z'));
    },
  );

  testSafe('JournalDatePredicate JSON roundtrip (relative)', () async {
    const p = JournalDatePredicate(
      operator: DateOperator.relative,
      relativeComparison: RelativeComparison.onOrBefore,
      relativeDays: 3,
    );

    final decoded = JournalPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('JournalMoodPredicate JSON roundtrip', () async {
    const p = JournalMoodPredicate(
      operator: MoodOperator.greaterThanOrEqual,
      value: MoodRating.good,
    );

    final decoded = JournalPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('JournalMoodPredicate.fromJson handles missing value', () async {
    final decoded = JournalMoodPredicate.fromJson(const <String, dynamic>{
      'type': 'mood',
      'operator': 'isNotNull',
    });

    expect(decoded.operator, MoodOperator.isNotNull);
    expect(decoded.value, isNull);
  });

  testSafe('JournalTextPredicate JSON roundtrip', () async {
    const p = JournalTextPredicate(
      operator: TextOperator.contains,
      value: 'hello',
    );

    final decoded = JournalPredicate.fromJson(p.toJson());
    expect(decoded, equals(p));
  });

  testSafe('JournalTextPredicate.fromJson uses default operator', () async {
    final decoded = JournalTextPredicate.fromJson(const <String, dynamic>{
      'type': 'text',
      'value': 'hello',
    });

    expect(decoded.operator, TextOperator.contains);
    expect(decoded.value, 'hello');
  });
}
