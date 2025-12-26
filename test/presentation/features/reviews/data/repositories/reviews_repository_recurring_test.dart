import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/presentation/features/reviews/data/repositories/reviews_repository_impl.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';

import '../../../../../fixtures/test_data.dart';
import '../../../../../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late ReviewsRepository repository;

  setUp(() async {
    db = createTestDb();
    repository = ReviewsRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ReviewsRepository - Recurring Reviews', () {
    test('daily recurring review maintains RRULE', () async {
      const dailyRRule = 'FREQ=DAILY';
      final review = TestData.review(
        id: 'review-1',
        name: 'Daily Review',
        rrule: dailyRRule,
        nextDueDate: DateTime(2025, 1, 20),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, dailyRRule);
    });

    test('weekly recurring review with specific day', () async {
      const weeklyRRule = 'FREQ=WEEKLY;BYDAY=MO';
      final review = TestData.review(
        id: 'review-1',
        name: 'Weekly Monday Review',
        rrule: weeklyRRule,
        nextDueDate: DateTime(2025, 1, 20), // Monday
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, weeklyRRule);
    });

    test('monthly recurring review with specific date', () async {
      const monthlyRRule = 'FREQ=MONTHLY;BYMONTHDAY=15';
      final review = TestData.review(
        id: 'review-1',
        name: 'Monthly Mid-month Review',
        rrule: monthlyRRule,
        nextDueDate: DateTime(2025, 1, 15),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, monthlyRRule);
    });

    test('yearly recurring review', () async {
      const yearlyRRule = 'FREQ=YEARLY;BYMONTH=1;BYMONTHDAY=1';
      final review = TestData.review(
        id: 'review-1',
        name: 'Yearly Review',
        rrule: yearlyRRule,
        nextDueDate: DateTime(2025),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, yearlyRRule);
    });

    test('recurring review with interval', () async {
      const intervalRRule = 'FREQ=DAILY;INTERVAL=3';
      final review = TestData.review(
        id: 'review-1',
        name: 'Every 3 Days Review',
        rrule: intervalRRule,
        nextDueDate: DateTime(2025, 1, 20),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, intervalRRule);
    });

    test('recurring review with count limit', () async {
      const countRRule = 'FREQ=WEEKLY;COUNT=10';
      final review = TestData.review(
        id: 'review-1',
        name: 'Limited Count Review',
        rrule: countRRule,
        nextDueDate: DateTime(2025, 1, 20),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, countRRule);
    });

    test('recurring review with until date', () async {
      const untilRRule = 'FREQ=DAILY;UNTIL=20251231T235959Z';
      final review = TestData.review(
        id: 'review-1',
        name: 'Time-Limited Review',
        rrule: untilRRule,
        nextDueDate: DateTime(2025, 1, 20),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, untilRRule);
    });

    test('recurring review with multiple weekdays', () async {
      const weekdaysRRule = 'FREQ=WEEKLY;BYDAY=MO,WE,FR';
      final review = TestData.review(
        id: 'review-1',
        name: 'MWF Review',
        rrule: weekdaysRRule,
        nextDueDate: DateTime(2025, 1, 20), // Monday
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, weekdaysRRule);
    });

    test('recurring review tracks completions correctly', () async {
      final review = TestData.review(
        id: 'review-1',
        rrule: 'FREQ=DAILY',
        nextDueDate: DateTime(2025, 1, 20),
      );

      await repository.saveReview(review);

      // Complete the review
      final completedAt = DateTime(2025, 1, 20, 10);
      await repository.completeReview('review-1', completedAt);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.lastCompletedAt, completedAt);
      expect(retrieved.rrule, 'FREQ=DAILY');
    });

    test('completing recurring review updates next due date', () async {
      final review = TestData.review(
        id: 'review-1',
        rrule: 'FREQ=DAILY',
        nextDueDate: DateTime(2025, 1, 20),
      );

      await repository.saveReview(review);

      // Complete and update next due date
      await repository.completeReview('review-1', DateTime(2025, 1, 20, 10));
      await repository.updateNextDueDate('review-1', DateTime(2025, 1, 21));

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.nextDueDate, DateTime(2025, 1, 21));
      expect(retrieved.rrule, 'FREQ=DAILY');
    });

    test('multiple recurring reviews with different frequencies', () async {
      await repository.saveReview(
        TestData.review(
          id: 'daily',
          name: 'Daily',
          rrule: 'FREQ=DAILY',
          nextDueDate: DateTime(2025, 1, 20),
        ),
      );

      await repository.saveReview(
        TestData.review(
          id: 'weekly',
          name: 'Weekly',
          nextDueDate: DateTime(2025, 1, 27),
        ),
      );

      await repository.saveReview(
        TestData.review(
          id: 'monthly',
          name: 'Monthly',
          rrule: 'FREQ=MONTHLY',
          nextDueDate: DateTime(2025, 2, 20),
        ),
      );

      final reviews = await repository.getAllReviews();
      expect(reviews.length, 3);

      final daily = reviews.firstWhere((r) => r.id == 'daily');
      final weekly = reviews.firstWhere((r) => r.id == 'weekly');
      final monthly = reviews.firstWhere((r) => r.id == 'monthly');

      expect(daily.rrule, 'FREQ=DAILY');
      expect(weekly.rrule, 'FREQ=WEEKLY');
      expect(monthly.rrule, 'FREQ=MONTHLY');
    });

    test('getDueReviews filters by due date for recurring reviews', () async {
      final now = DateTime.now();

      await repository.saveReview(
        TestData.review(
          id: 'due-today',
          rrule: 'FREQ=DAILY',
          nextDueDate: now.subtract(const Duration(hours: 3)), // Due before now
        ),
      );

      await repository.saveReview(
        TestData.review(
          id: 'due-tomorrow',
          rrule: 'FREQ=DAILY',
          nextDueDate: now.add(const Duration(days: 1)), // Due after now
        ),
      );

      final dueReviews = await repository.getDueReviews();
      expect(dueReviews.length, 1);
      expect(dueReviews[0].id, 'due-today');
    });

    test('recurring review history with multiple completions', () async {
      final review = TestData.review(
        id: 'review-1',
        rrule: 'FREQ=DAILY',
        nextDueDate: DateTime(2025, 1, 20),
      );

      await repository.saveReview(review);

      // Complete multiple times
      await repository.completeReview('review-1', DateTime(2025, 1, 20, 10));
      await repository.updateNextDueDate('review-1', DateTime(2025, 1, 21));

      await repository.completeReview('review-1', DateTime(2025, 1, 21, 10));
      await repository.updateNextDueDate('review-1', DateTime(2025, 1, 22));

      await repository.completeReview('review-1', DateTime(2025, 1, 22, 10));
      await repository.updateNextDueDate('review-1', DateTime(2025, 1, 23));

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.lastCompletedAt, DateTime(2025, 1, 22, 10));
      expect(retrieved.nextDueDate, DateTime(2025, 1, 23));
    });

    test('recurring review with workday pattern', () async {
      const workdaysRRule = 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
      final review = TestData.review(
        id: 'review-1',
        name: 'Workday Review',
        rrule: workdaysRRule,
        nextDueDate: DateTime(2025, 1, 20), // Monday
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, workdaysRRule);
    });

    test('recurring review with custom start date', () async {
      const rruleWithStart =
          'FREQ=MONTHLY;BYMONTHDAY=1;DTSTART=20250101T090000Z';
      final review = TestData.review(
        id: 'review-1',
        name: 'Monthly from Jan 1st',
        rrule: rruleWithStart,
        nextDueDate: DateTime(2025, 1, 1, 9),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, rruleWithStart);
    });

    test('recurring review with timezone information', () async {
      const rruleWithTZ =
          'FREQ=DAILY;DTSTART;TZID=America/New_York:20250120T090000';
      final review = TestData.review(
        id: 'review-1',
        name: 'Timezone-aware Review',
        rrule: rruleWithTZ,
        nextDueDate: DateTime(2025, 1, 20, 9),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, rruleWithTZ);
    });

    test('recurring review with last day of month pattern', () async {
      const lastDayRRule = 'FREQ=MONTHLY;BYMONTHDAY=-1';
      final review = TestData.review(
        id: 'review-1',
        name: 'End of Month Review',
        rrule: lastDayRRule,
        nextDueDate: DateTime(2025, 1, 31),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, lastDayRRule);
    });

    test('recurring review with quarter pattern', () async {
      const quarterRRule = 'FREQ=MONTHLY;INTERVAL=3;BYMONTHDAY=1';
      final review = TestData.review(
        id: 'review-1',
        name: 'Quarterly Review',
        rrule: quarterRRule,
        nextDueDate: DateTime(2025),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, quarterRRule);
    });

    test('recurring review completion does not affect other reviews', () async {
      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          rrule: 'FREQ=DAILY',
          nextDueDate: DateTime(2025, 1, 20),
        ),
      );

      await repository.saveReview(
        TestData.review(
          id: 'review-2',
          rrule: 'FREQ=DAILY',
          nextDueDate: DateTime(2025, 1, 20),
        ),
      );

      // Complete review-1
      await repository.completeReview('review-1', DateTime(2025, 1, 20, 10));
      await repository.updateNextDueDate('review-1', DateTime(2025, 1, 21));

      // review-2 should be unaffected
      final review2 = await repository.getReview('review-2');
      expect(review2!.lastCompletedAt, isNull);
      expect(review2.nextDueDate, DateTime(2025, 1, 20));
    });

    test('updating RRULE preserves review history', () async {
      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          rrule: 'FREQ=DAILY',
          nextDueDate: DateTime(2025, 1, 20),
        ),
      );

      final completedAt = DateTime(2025, 1, 20, 10);
      await repository.completeReview('review-1', completedAt);

      // Get current review and update RRULE
      final current = await repository.getReview('review-1');
      final updated = current!.copyWith(
        rrule: 'FREQ=WEEKLY',
        nextDueDate: DateTime(2025, 1, 27),
      );
      await repository.saveReview(updated);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, 'FREQ=WEEKLY');
      expect(retrieved.lastCompletedAt, completedAt);
    });
  });
}
