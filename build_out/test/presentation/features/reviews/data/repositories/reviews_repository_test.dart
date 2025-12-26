import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
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

  group('ReviewsRepository - Basic CRUD', () {
    test('saveReview creates new review', () async {
      final review = TestData.review(
        id: 'review-1',
        name: 'Weekly Project Review',
        rrule: 'FREQ=WEEKLY;BYDAY=FR',
        nextDueDate: DateTime(2025, 1, 24),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'review-1');
      expect(retrieved.name, 'Weekly Project Review');
      expect(retrieved.rrule, 'FREQ=WEEKLY;BYDAY=FR');
      expect(retrieved.nextDueDate, DateTime(2025, 1, 24));
    });

    test('saveReview updates existing review', () async {
      final review = TestData.review(
        id: 'review-1',
        name: 'Initial Name',
      );
      await repository.saveReview(review);

      final updated = review.copyWith(name: 'Updated Name');
      await repository.saveReview(updated);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.name, 'Updated Name');
    });

    test('getReview returns null for non-existent review', () async {
      final result = await repository.getReview('non-existent');
      expect(result, isNull);
    });

    test(
      'getAllReviews returns all active reviews ordered by due date',
      () async {
        await repository.saveReview(
          TestData.review(
            id: 'review-1',
            name: 'Review 1',
            nextDueDate: DateTime(2025, 1, 25),
          ),
        );
        await repository.saveReview(
          TestData.review(
            id: 'review-2',
            name: 'Review 2',
            nextDueDate: DateTime(2025, 1, 20),
          ),
        );
        await repository.saveReview(
          TestData.review(
            id: 'review-3',
            name: 'Review 3',
            nextDueDate: DateTime(2025, 1, 30),
          ),
        );

        final reviews = await repository.getAllReviews();

        expect(reviews.length, 3);
        expect(reviews[0].id, 'review-2'); // Earliest due date first
        expect(reviews[1].id, 'review-1');
        expect(reviews[2].id, 'review-3');
      },
    );

    test('getAllReviews excludes deleted reviews', () async {
      await repository.saveReview(
        TestData.review(id: 'review-1', name: 'Active'),
      );
      await repository.saveReview(
        TestData.review(id: 'review-2', name: 'Will be deleted'),
      );

      await repository.deleteReview('review-2');

      final reviews = await repository.getAllReviews();
      expect(reviews.length, 1);
      expect(reviews[0].id, 'review-1');
    });

    test('getDueReviews returns only reviews due now or earlier', () async {
      final now = DateTime.now();

      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          name: 'Overdue',
          nextDueDate: now.subtract(const Duration(days: 2)),
        ),
      );
      await repository.saveReview(
        TestData.review(
          id: 'review-2',
          name: 'Due Now',
          nextDueDate: now.subtract(const Duration(seconds: 1)),
        ),
      );
      await repository.saveReview(
        TestData.review(
          id: 'review-3',
          name: 'Future',
          nextDueDate: now.add(const Duration(days: 2)),
        ),
      );

      final dueReviews = await repository.getDueReviews();

      // Should include overdue and recently due reviews
      expect(
        dueReviews.any((r) => r.id == 'review-1' || r.id == 'review-2'),
        isTrue,
      );
      // Should not include future reviews
      expect(dueReviews.every((r) => r.id != 'review-3'), isTrue);
    });

    test('deleteReview soft deletes review', () async {
      await repository.saveReview(
        TestData.review(id: 'review-1', name: 'To Delete'),
      );

      await repository.deleteReview('review-1');

      final retrieved = await repository.getReview('review-1');
      expect(retrieved, isNull);

      final allReviews = await repository.getAllReviews();
      expect(allReviews.any((r) => r.id == 'review-1'), isFalse);
    });
  });

  group('ReviewsRepository - Complete and Update Due Date', () {
    test('completeReview updates lastCompletedAt', () async {
      await repository.saveReview(
        TestData.review(
          id: 'review-1',
        ),
      );

      final completedAt = DateTime(2025, 1, 20, 10);
      await repository.completeReview('review-1', completedAt);

      final review = await repository.getReview('review-1');
      expect(review!.lastCompletedAt, completedAt);
    });

    test('updateNextDueDate updates nextDueDate', () async {
      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          nextDueDate: DateTime(2025, 1, 20),
        ),
      );

      final newDueDate = DateTime(2025, 1, 27);
      await repository.updateNextDueDate('review-1', newDueDate);

      final review = await repository.getReview('review-1');
      expect(review!.nextDueDate, newDueDate);
    });

    test('complete review workflow: complete and update due date', () async {
      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          name: 'Weekly Review',
          nextDueDate: DateTime(2025, 1, 20),
        ),
      );

      // Complete the review
      final completedAt = DateTime(2025, 1, 20, 14, 30);
      await repository.completeReview('review-1', completedAt);

      // Update next due date (would be calculated from RRULE in real app)
      final nextDue = DateTime(2025, 1, 27);
      await repository.updateNextDueDate('review-1', nextDue);

      final review = await repository.getReview('review-1');
      expect(review!.lastCompletedAt, completedAt);
      expect(review.nextDueDate, nextDue);
    });
  });

  group('ReviewsRepository - Query Persistence', () {
    test('saves and retrieves review with complex query', () async {
      final review = TestData.review(
        id: 'review-1',
        name: 'Project Review',
        query: TestData.reviewQuery(
          entityType: EntityType.project,
          labelIds: ['label-1', 'label-2'],
          includeCompleted: false,
          createdBefore: DateTime(2025),
        ),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.query.entityType, EntityType.project);
      expect(retrieved.query.labelIds, ['label-1', 'label-2']);
      expect(retrieved.query.includeCompleted, false);
      expect(retrieved.query.createdBefore, DateTime(2025));
    });

    test('saves review with task query', () async {
      final review = TestData.review(
        id: 'review-1',
        query: TestData.reviewQuery(
          projectIds: ['project-1'],
          completedAfter: DateTime(2024, 12),
        ),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.query.entityType, EntityType.task);
      expect(retrieved.query.projectIds, ['project-1']);
      expect(retrieved.query.completedAfter, DateTime(2024, 12));
    });

    test('saves review with label query', () async {
      final review = TestData.review(
        id: 'review-1',
        query: TestData.reviewQuery(
          entityType: EntityType.label,
          valueIds: ['value-1', 'value-2'],
        ),
      );

      await repository.saveReview(review);

      final retrieved = await repository.getReview('review-1');
      expect(retrieved!.query.entityType, EntityType.label);
      expect(retrieved.query.valueIds, ['value-1', 'value-2']);
    });
  });

  group('ReviewsRepository - Multiple Reviews', () {
    test('handles multiple reviews with different RRULES', () async {
      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          name: 'Daily Standup',
          rrule: 'FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR',
        ),
      );
      await repository.saveReview(
        TestData.review(
          id: 'review-2',
          name: 'Weekly Review',
          rrule: 'FREQ=WEEKLY;BYDAY=FR',
        ),
      );
      await repository.saveReview(
        TestData.review(
          id: 'review-3',
          name: 'Monthly Planning',
          rrule: 'FREQ=MONTHLY;BYMONTHDAY=1',
        ),
      );

      final reviews = await repository.getAllReviews();
      expect(reviews.length, 3);

      final daily = reviews.firstWhere((r) => r.id == 'review-1');
      final weekly = reviews.firstWhere((r) => r.id == 'review-2');
      final monthly = reviews.firstWhere((r) => r.id == 'review-3');

      expect(daily.rrule, 'FREQ=DAILY;BYDAY=MO,TU,WE,TH,FR');
      expect(weekly.rrule, 'FREQ=WEEKLY;BYDAY=FR');
      expect(monthly.rrule, 'FREQ=MONTHLY;BYMONTHDAY=1');
    });

    test('updates multiple reviews independently', () async {
      await repository.saveReview(
        TestData.review(id: 'review-1', name: 'Review 1'),
      );
      await repository.saveReview(
        TestData.review(id: 'review-2', name: 'Review 2'),
      );

      await repository.completeReview('review-1', DateTime(2025, 1, 20));
      await repository.updateNextDueDate('review-2', DateTime(2025, 2));

      final review1 = await repository.getReview('review-1');
      final review2 = await repository.getReview('review-2');

      expect(review1!.lastCompletedAt, isNotNull);
      expect(review2!.lastCompletedAt, isNull);
      expect(review2.nextDueDate, DateTime(2025, 2));
    });
  });
}
