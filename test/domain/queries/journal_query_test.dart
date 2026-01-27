@Tags(['unit'])
library;

import '../../helpers/test_imports.dart';
import 'package:taskly_domain/queries.dart';
import 'package:taskly_domain/journal.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('JournalPredicate', () {
    testSafe('round-trips json for id/date/mood/text', () async {
      const idPred = JournalIdPredicate(id: 'j1');
      final datePred = JournalDatePredicate(
        operator: DateOperator.on,
        date: DateTime(2025, 1, 1),
      );
      final moodPred = JournalMoodPredicate(
        operator: MoodOperator.greaterThanOrEqual,
        value: MoodRating.good,
      );
      const textPred = JournalTextPredicate(
        operator: TextOperator.contains,
        value: 'hello',
      );

      expect(JournalPredicate.fromJson(idPred.toJson()), idPred);
      expect(JournalPredicate.fromJson(datePred.toJson()), datePred);
      expect(JournalPredicate.fromJson(moodPred.toJson()), moodPred);
      expect(JournalPredicate.fromJson(textPred.toJson()), textPred);
    });
  });

  group('JournalQuery', () {
    testSafe('factory methods set filters', () async {
      final forDate = JournalQuery.forDate(DateTime(2025, 1, 10));
      expect(forDate.hasDateFilter, isTrue);

      final recent = JournalQuery.recent(
        todayDayKeyUtc: DateTime(2025, 1, 10),
        days: 7,
      );
      expect(recent.hasDateFilter, isTrue);
    });

    testSafe('serializes and deserializes', () async {
      final query = JournalQuery.forDate(DateTime(2025, 1, 10));
      final json = query.toJson();
      final roundTrip = JournalQuery.fromJson(json);

      expect(roundTrip, query);
    });
  });
}
