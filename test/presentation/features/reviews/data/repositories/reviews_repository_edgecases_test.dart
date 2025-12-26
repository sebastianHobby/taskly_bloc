import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/presentation/features/reviews/data/repositories/reviews_repository_impl.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';

import '../../../../../fixtures/test_data.dart';
import '../../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ReviewsRepository repository;

  setUp(() async {
    db = await createTestDatabase();
    repository = ReviewsRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('ReviewsRepository - Edge Cases', () {
    test('handles empty database gracefully', () async {
      final reviews = await repository.getAllReviews();
      expect(reviews, isEmpty);

      final dueReviews = await repository.getDueReviews();
      expect(dueReviews, isEmpty);
    });

    test('getReview with empty string returns null', () async {
      final result = await repository.getReview('');
      expect(result, isNull);
    });

    test('deleteReview on non-existent review does not throw', () async {
      expect(
        () => repository.deleteReview('non-existent'),
        returnsNormally,
      );
    });

    test('completeReview on non-existent review does not throw', () async {
      expect(
        () => repository.completeReview('non-existent', DateTime.now()),
        returnsNormally,
      );
    });

    test('updateNextDueDate on non-existent review does not throw', () async {
      expect(
        () => repository.updateNextDueDate('non-existent', DateTime.now()),
        returnsNormally,
      );
    });

    test('handles review with very long RRULE', () async {
      const longRrule =
          'FREQ=YEARLY;BYMONTH=1,2,3,4,5,6,7,8,9,10,11,12;'
          'BYDAY=MO,TU,WE,TH,FR,SA,SU;BYMONTHDAY=1,2,3,4,5,6,7,8,9,10,'
          '11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31';

      final review = TestData.review(
        id: 'review-1',
        rrule: longRrule,
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.rrule, longRrule);
    });

    test('handles review with special characters in name', () async {
      final review = TestData.review(
        id: 'review-1',
        name: "Review with 'quotes' and \"double quotes\" and \$pecial ch@rs!",
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.name, review.name);
    });

    test('handles review with very long description', () async {
      final longDescription = 'A' * 10000; // 10,000 character description

      final review = TestData.review(
        id: 'review-1',
        description: longDescription,
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.description, longDescription);
    });

    test('handles null description', () async {
      final review = TestData.review(
        id: 'review-1',
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.description, isNull);
    });

    test('handles review with past due date', () async {
      final pastDate = DateTime(2020);
      final review = TestData.review(
        id: 'review-1',
        nextDueDate: pastDate,
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.nextDueDate, pastDate);
    });

    test('handles review with far future due date', () async {
      final futureDate = DateTime(2099, 12, 31);
      final review = TestData.review(
        id: 'review-1',
        nextDueDate: futureDate,
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.nextDueDate, futureDate);
    });

    test('handles multiple rapid updates to same review', () async {
      await repository.saveReview(
        TestData.review(id: 'review-1', name: 'Original'),
      );

      // Rapid updates
      for (var i = 0; i < 10; i++) {
        await repository.saveReview(
          TestData.review(id: 'review-1', name: 'Update $i'),
        );
      }

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.name, 'Update 9');
    });

    test('handles review with complex nested query', () async {
      final review = TestData.review(
        id: 'review-1',
        query: TestData.reviewQuery(
          projectIds: List.generate(50, (i) => 'project-$i'),
          labelIds: List.generate(50, (i) => 'label-$i'),
        ),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.query.projectIds!.length, 50);
      expect(retrieved.query.labelIds!.length, 50);
    });

    test('saveReview with empty id generates new id', () async {
      final review = TestData.review(
        id: '',
        name: 'Auto-generated ID',
      );

      await repository.saveReview(review);

      final allReviews = await repository.getAllReviews();
      expect(allReviews.length, 1);
      expect(allReviews[0].id, isNotEmpty);
      expect(allReviews[0].name, 'Auto-generated ID');
    });

    test('handles UTC and local time zones correctly', () async {
      final utcDate = DateTime.utc(2025, 1, 20, 12);
      final localDate = DateTime(2025, 1, 20, 12);

      await repository.saveReview(
        TestData.review(id: 'review-1', nextDueDate: utcDate),
      );
      await repository.saveReview(
        TestData.review(id: 'review-2', nextDueDate: localDate),
      );

      final review1 = await repository.getReview('review-1');
      final review2 = await repository.getReview('review-2');

      expect(review1!.nextDueDate, utcDate);
      expect(review2!.nextDueDate, localDate);
    });

    test(
      'deleted review cannot be retrieved even with direct ID query',
      () async {
        await repository.saveReview(
          TestData.review(id: 'review-1'),
        );

        await repository.deleteReview('review-1');

        final retrieved = await repository.getReview('review-1');
        expect(retrieved, isNull);
      },
    );

    test('deleting already deleted review does not cause error', () async {
      await repository.saveReview(
        TestData.review(id: 'review-1'),
      );

      await repository.deleteReview('review-1');
      // Delete again
      expect(
        () => repository.deleteReview('review-1'),
        returnsNormally,
      );
    });

    test('handles concurrent operations on same review', () async {
      await repository.saveReview(
        TestData.review(id: 'review-1', name: 'Original'),
      );

      // Simulate concurrent operations
      await Future.wait([
        repository.completeReview('review-1', DateTime.now()),
        repository.updateNextDueDate('review-1', DateTime(2025, 2)),
        repository.saveReview(
          TestData.review(id: 'review-1', name: 'Concurrent Update'),
        ),
      ]);

      // Should not throw error and review should exist
      final review = await repository.getReview('review-1');
      expect(review, isNotNull);
    });

    test('preserves createdAt when updating review', () async {
      final createdAt = DateTime(2025);
      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          name: 'Original',
          createdAt: createdAt,
        ),
      );

      await Future.delayed(const Duration(milliseconds: 10));

      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          name: 'Updated',
          createdAt: createdAt,
        ),
      );

      final review = await repository.getReview('review-1');
      expect(review!.createdAt, createdAt);
      expect(review.name, 'Updated');
    });

    test('getAllReviews handles large number of reviews efficiently', () async {
      // Create 100 reviews
      for (var i = 0; i < 100; i++) {
        await repository.saveReview(
          TestData.review(
            id: 'review-$i',
            name: 'Review $i',
            nextDueDate: DateTime(2025).add(Duration(days: i)),
          ),
        );
      }

      final reviews = await repository.getAllReviews();
      expect(reviews.length, 100);

      // Should be ordered by due date
      for (var i = 0; i < reviews.length - 1; i++) {
        expect(
          reviews[i].nextDueDate.isBefore(reviews[i + 1].nextDueDate) ||
              reviews[i].nextDueDate.isAtSameMomentAs(
                reviews[i + 1].nextDueDate,
              ),
          isTrue,
          reason: 'Reviews should be ordered by nextDueDate',
        );
      }
    });
  });
}
