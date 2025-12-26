import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/data/repositories/reviews_repository_impl.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/blocs/reviews_list/reviews_list_bloc.dart';

import '../fixtures/test_data.dart';
import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late ReviewsRepository repository;
  late ReviewsListBloc bloc;

  Future<ReviewsListState> waitForLoaded() =>
      bloc.stream.firstWhere((state) => !state.isLoading);

  Future<ReviewsListState> loadAll() async {
    bloc.add(const ReviewsListEvent.loadAll());
    return waitForLoaded();
  }

  Future<ReviewsListState> loadDue() async {
    bloc.add(const ReviewsListEvent.loadDue());
    return waitForLoaded();
  }

  setUp(() async {
    db = createTestDb();
    repository = ReviewsRepositoryImpl(db);
    bloc = ReviewsListBloc(repository);

    // Allow the bloc's initial auto-load to complete before each test.
    await waitForLoaded();
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  group('Reviews CRUD Integration', () {
    test('end-to-end: create review and load in bloc', () async {
      final review = TestData.review(
        id: 'review-1',
        name: 'Weekly Review',
        nextDueDate: DateTime(2025, 1, 24),
      );

      await repository.saveReview(review);

      final state = await loadAll();

      expect(state.reviews.length, 1);
      expect(state.reviews.first.id, 'review-1');
      expect(state.reviews.first.name, 'Weekly Review');
    });

    test('end-to-end: create multiple reviews and verify ordering', () async {
      final now = DateTime.now();

      await repository.saveReview(
        TestData.review(
          id: 'review-3',
          name: 'Future Review',
          nextDueDate: now.add(const Duration(days: 7)),
        ),
      );

      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          name: 'Overdue Review',
          nextDueDate: now.subtract(const Duration(days: 2)),
        ),
      );

      await repository.saveReview(
        TestData.review(
          id: 'review-2',
          name: 'Due Today',
          nextDueDate: now,
        ),
      );

      final state = await loadAll();

      expect(state.reviews.length, 3);
      expect(state.reviews[0].id, 'review-1');
      expect(state.reviews[1].id, 'review-2');
      expect(state.reviews[2].id, 'review-3');
    });

    test('end-to-end: delete review via bloc', () async {
      await repository.saveReview(
        TestData.review(id: 'review-1', name: 'Review 1'),
      );
      await repository.saveReview(
        TestData.review(id: 'review-2', name: 'Review 2'),
      );

      await loadAll();

      bloc.add(const ReviewsListEvent.deleteReview('review-1'));

      final state = await bloc.stream.firstWhere(
        (s) => s.reviews.length == 1 && s.reviews.first.id == 'review-2',
      );
      expect(state.error, isNull);

      final remaining = await repository.getAllReviews();
      expect(remaining.length, 1);
      expect(remaining[0].id, 'review-2');
    });

    test('end-to-end: load only due reviews', () async {
      final now = DateTime.now();

      await repository.saveReview(
        TestData.review(
          id: 'due-1',
          name: 'Overdue',
          nextDueDate: now.subtract(const Duration(days: 1)),
        ),
      );

      await repository.saveReview(
        TestData.review(
          id: 'future-1',
          name: 'Future',
          nextDueDate: now.add(const Duration(days: 7)),
        ),
      );

      final state = await loadDue();

      expect(state.reviews.length, 1);
      expect(state.reviews.first.id, 'due-1');
    });

    test('end-to-end: update review and reload', () async {
      await repository.saveReview(
        TestData.review(
          id: 'review-1',
          name: 'Original Name',
          rrule: 'FREQ=DAILY',
        ),
      );

      final initialState = await loadAll();
      expect(initialState.reviews.first.name, 'Original Name');

      final updated = initialState.reviews.first.copyWith(
        name: 'Updated Name',
        rrule: 'FREQ=WEEKLY',
      );
      await repository.saveReview(updated);

      final state = await loadAll();

      expect(state.reviews.length, 1);
      expect(state.reviews.first.name, 'Updated Name');
      expect(state.reviews.first.rrule, 'FREQ=WEEKLY');
    });

    test('end-to-end: complete review workflow', () async {
      final review = TestData.review(
        id: 'review-1',
        name: 'Review to Complete',
        nextDueDate: DateTime(2025, 1, 20),
      );

      await repository.saveReview(review);

      // Complete the review
      final completedAt = DateTime(2025, 1, 20, 10);
      await repository.completeReview('review-1', completedAt);

      // Update next due date
      await repository.updateNextDueDate('review-1', DateTime(2025, 1, 27));

      final state = await loadAll();
      final completedReview = state.reviews.first;

      expect(completedReview.lastCompletedAt, completedAt);
      expect(completedReview.nextDueDate, DateTime(2025, 1, 27));
    });

    test('end-to-end: handle multiple review types', () async {
      // Task review
      await repository.saveReview(
        TestData.review(
          id: 'task-review',
          name: 'Task Review',
          query: TestData.reviewQuery(
            projectIds: ['proj-1', 'proj-2'],
          ),
        ),
      );

      // Project review
      await repository.saveReview(
        TestData.review(
          id: 'project-review',
          name: 'Project Review',
          query: TestData.reviewQuery(
            entityType: EntityType.project,
          ),
        ),
      );

      // Label review
      await repository.saveReview(
        TestData.review(
          id: 'label-review',
          name: 'Label Review',
          query: TestData.reviewQuery(
            entityType: EntityType.label,
            labelIds: ['label-1'],
          ),
        ),
      );

      final state = await loadAll();
      expect(state.reviews.length, 3);

      final taskReview = state.reviews.firstWhere(
        (r) => r.id == 'task-review',
      );
      final projectReview = state.reviews.firstWhere(
        (r) => r.id == 'project-review',
      );
      final labelReview = state.reviews.firstWhere(
        (r) => r.id == 'label-review',
      );

      expect(taskReview.query.entityType, EntityType.task);
      expect(projectReview.query.entityType, EntityType.project);
      expect(labelReview.query.entityType, EntityType.label);
    });

    test('end-to-end: handle recurring reviews over time', () async {
      final startDate = DateTime(2025);

      // Create daily recurring review
      await repository.saveReview(
        TestData.review(
          id: 'daily-review',
          name: 'Daily Standup',
          rrule: 'FREQ=DAILY',
          nextDueDate: startDate,
        ),
      );

      // Simulate completing over several days
      for (var i = 0; i < 5; i++) {
        final completionDate = startDate.add(Duration(days: i));
        await repository.completeReview(
          'daily-review',
          completionDate.add(const Duration(hours: 10)),
        );
        await repository.updateNextDueDate(
          'daily-review',
          startDate.add(Duration(days: i + 1)),
        );
      }

      final state = await loadAll();
      final review = state.reviews.first;

      expect(
        review.nextDueDate,
        startDate.add(const Duration(days: 5)),
      );
      expect(
        review.lastCompletedAt,
        isNotNull,
      );
      expect(
        review.lastCompletedAt!.isAfter(
          startDate.add(const Duration(days: 4)),
        ),
        isTrue,
      );
    });

    test('end-to-end: error handling - load after repository error', () async {
      // Close the database to simulate error
      await db.close();

      final state = await loadAll();
      expect(state.error, isNotNull);
    });

    test('end-to-end: deleted reviews do not appear in lists', () async {
      // Create three reviews
      for (var i = 1; i <= 3; i++) {
        await repository.saveReview(
          TestData.review(id: 'review-$i', name: 'Review $i'),
        );
      }

      // Delete the middle one
      await repository.deleteReview('review-2');

      final state = await loadAll();
      expect(state.reviews.length, 2);
      expect(state.reviews.every((r) => r.id != 'review-2'), isTrue);

      // Also verify getDueReviews excludes deleted
      final dueState = await loadDue();
      expect(dueState.reviews.every((r) => r.id != 'review-2'), isTrue);
    });
  });
}
