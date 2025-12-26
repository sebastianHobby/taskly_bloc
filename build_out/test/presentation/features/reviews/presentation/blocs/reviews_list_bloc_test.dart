import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/blocs/reviews_list/reviews_list_bloc.dart';

import '../../../../../fixtures/test_data.dart';
import '../../../../../mocks/wellbeing_reviews_mocks.dart';

void main() {
  late MockReviewsRepository mockRepository;
  late ReviewsListBloc bloc;

  setUp(() {
    mockRepository = MockReviewsRepository();
  });

  tearDown(() {
    bloc.close();
  });

  group('ReviewsListBloc - Initialization', () {
    test('initial state has empty reviews list and is loading', () {
      // Arrange
      when(() => mockRepository.getAllReviews()).thenAnswer((_) async => []);

      // Act
      bloc = ReviewsListBloc(mockRepository);

      // Assert
      expect(bloc.state.reviews, isEmpty);
      expect(bloc.state.isLoading, true);
      expect(bloc.state.error, isNull);
    });

    test('automatically loads all reviews on initialization', () async {
      // Arrange
      final testReviews = [
        TestData.review(),
        TestData.review(id: 'review-2', name: 'Another Review'),
      ];
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);

      // Act
      bloc = ReviewsListBloc(mockRepository);
      await Future<void>.delayed(Duration.zero); // Let the event process

      // Assert
      verify(() => mockRepository.getAllReviews()).called(1);
    });
  });

  group('ReviewsListBloc - LoadAll Event', () {
    test('emits loading then loaded state with reviews', () async {
      // Arrange
      final testReviews = [
        TestData.review(id: 'review-1', name: 'Weekly Review'),
        TestData.review(id: 'review-2', name: 'Monthly Review'),
      ];
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue(); // Process initialization

      // Act
      bloc.add(const ReviewsListEvent.loadAll());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewsListState>(
            (state) => state.isLoading && state.error == null,
          ),
          predicate<ReviewsListState>(
            (state) =>
                !state.isLoading &&
                state.reviews.length == 2 &&
                state.error == null,
          ),
        ]),
      );
    });

    test('emits error state when repository throws exception', () async {
      // Arrange
      when(
        () => mockRepository.getAllReviews(),
      ).thenThrow(Exception('Database error'));

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadAll());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewsListState>((state) => state.isLoading),
          predicate<ReviewsListState>(
            (state) =>
                !state.isLoading &&
                state.error != null &&
                state.error!.contains('Database error'),
          ),
        ]),
      );
    });

    test('handles empty repository successfully', () async {
      // Arrange
      when(() => mockRepository.getAllReviews()).thenAnswer((_) async => []);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadAll());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewsListState>((state) => state.isLoading),
          predicate<ReviewsListState>(
            (state) => !state.isLoading && state.reviews.isEmpty,
          ),
        ]),
      );
    });

    test('loads multiple reviews maintaining order', () async {
      // Arrange
      final testReviews = List.generate(
        10,
        (i) => TestData.review(
          id: 'review-$i',
          name: 'Review $i',
        ),
      );
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadAll());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews.length, 10);
      expect(bloc.state.reviews[0].name, 'Review 0');
      expect(bloc.state.reviews[9].name, 'Review 9');
    });
  });

  group('ReviewsListBloc - LoadDue Event', () {
    test('emits loading then loaded state with only due reviews', () async {
      // Arrange
      final dueReviews = [
        TestData.review(id: 'review-1', name: 'Due Review'),
      ];
      when(() => mockRepository.getAllReviews()).thenAnswer((_) async => []);
      when(
        () => mockRepository.getDueReviews(),
      ).thenAnswer((_) async => dueReviews);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadDue());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewsListState>((state) => state.isLoading),
          predicate<ReviewsListState>(
            (state) =>
                !state.isLoading &&
                state.reviews.length == 1 &&
                state.reviews[0].id == 'review-1',
          ),
        ]),
      );
    });

    test('filters out non-due reviews', () async {
      // Arrange
      final now = DateTime.now();
      final dueReview = TestData.review(
        id: 'review-1',
        name: 'Due Review',
        nextDueDate: now.subtract(const Duration(days: 1)),
      );
      when(() => mockRepository.getAllReviews()).thenAnswer((_) async => []);
      when(
        () => mockRepository.getDueReviews(),
      ).thenAnswer((_) async => [dueReview]);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadDue());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews.length, 1);
      expect(bloc.state.reviews[0].id, 'review-1');
    });

    test('returns empty list when no reviews are due', () async {
      // Arrange
      when(() => mockRepository.getAllReviews()).thenAnswer((_) async => []);
      when(() => mockRepository.getDueReviews()).thenAnswer((_) async => []);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadDue());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews, isEmpty);
      expect(bloc.state.isLoading, false);
    });

    test('emits error state when getDueReviews fails', () async {
      // Arrange
      when(() => mockRepository.getAllReviews()).thenAnswer((_) async => []);
      when(
        () => mockRepository.getDueReviews(),
      ).thenThrow(Exception('Failed to fetch due reviews'));

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadDue());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewsListState>((state) => state.isLoading),
          predicate<ReviewsListState>(
            (state) =>
                !state.isLoading &&
                state.error != null &&
                state.error!.contains('Failed to fetch due reviews'),
          ),
        ]),
      );
    });
  });

  group('ReviewsListBloc - DeleteReview Event', () {
    test('removes review from state after successful deletion', () async {
      // Arrange
      final testReviews = [
        TestData.review(id: 'review-1', name: 'Review 1'),
        TestData.review(id: 'review-2', name: 'Review 2'),
        TestData.review(id: 'review-3', name: 'Review 3'),
      ];
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);
      when(
        () => mockRepository.deleteReview(any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.deleteReview('review-2'));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews.length, 2);
      expect(bloc.state.reviews.any((r) => r.id == 'review-2'), false);
      expect(bloc.state.reviews.any((r) => r.id == 'review-1'), true);
      expect(bloc.state.reviews.any((r) => r.id == 'review-3'), true);
      verify(() => mockRepository.deleteReview('review-2')).called(1);
    });

    test('does not change state if review not found', () async {
      // Arrange
      final testReviews = [
        TestData.review(id: 'review-1', name: 'Review 1'),
      ];
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);
      when(
        () => mockRepository.deleteReview(any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      final initialReviews = bloc.state.reviews;

      // Act
      bloc.add(const ReviewsListEvent.deleteReview('non-existent'));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews.length, initialReviews.length);
      verify(() => mockRepository.deleteReview('non-existent')).called(1);
    });

    test('emits error state when deletion fails', () async {
      // Arrange
      final testReviews = [
        TestData.review(id: 'review-1', name: 'Review 1'),
      ];
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);
      when(
        () => mockRepository.deleteReview(any()),
      ).thenThrow(Exception('Deletion failed'));

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.deleteReview('review-1'));

      // Assert
      await expectLater(
        bloc.stream,
        emits(
          predicate<ReviewsListState>(
            (state) =>
                state.error != null && state.error!.contains('Deletion failed'),
          ),
        ),
      );

      // Review should still be in the list since deletion failed
      expect(bloc.state.reviews.any((r) => r.id == 'review-1'), true);
    });

    test('can delete all reviews one by one', () async {
      // Arrange
      final testReviews = [
        TestData.review(id: 'review-1', name: 'Review 1'),
        TestData.review(id: 'review-2', name: 'Review 2'),
      ];
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);
      when(
        () => mockRepository.deleteReview(any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.deleteReview('review-1'));
      await pumpEventQueue();
      bloc.add(const ReviewsListEvent.deleteReview('review-2'));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews, isEmpty);
      verify(() => mockRepository.deleteReview('review-1')).called(1);
      verify(() => mockRepository.deleteReview('review-2')).called(1);
    });
  });

  group('ReviewsListBloc - Multiple Events', () {
    test('handles rapid consecutive loadAll events', () async {
      // Arrange
      final testReviews = [TestData.review()];
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadAll());
      bloc.add(const ReviewsListEvent.loadAll());
      bloc.add(const ReviewsListEvent.loadAll());
      await pumpEventQueue();

      // Assert - should handle all events
      verify(
        () => mockRepository.getAllReviews(),
      ).called(greaterThanOrEqualTo(3));
    });

    test('can switch between loadAll and loadDue', () async {
      // Arrange
      final allReviews = [
        TestData.review(id: 'review-1'),
        TestData.review(id: 'review-2'),
      ];
      final dueReviews = [TestData.review(id: 'review-1')];

      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => allReviews);
      when(
        () => mockRepository.getDueReviews(),
      ).thenAnswer((_) async => dueReviews);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadAll());
      await pumpEventQueue();
      expect(bloc.state.reviews.length, 2);

      bloc.add(const ReviewsListEvent.loadDue());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews.length, 1);
    });

    test('loadAll after delete shows updated list', () async {
      // Arrange
      var reviewsList = [
        TestData.review(id: 'review-1'),
        TestData.review(id: 'review-2'),
      ];

      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => reviewsList);
      when(() => mockRepository.deleteReview('review-1')).thenAnswer((_) async {
        reviewsList = [TestData.review(id: 'review-2')];
      });

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.deleteReview('review-1'));
      await pumpEventQueue();

      bloc.add(const ReviewsListEvent.loadAll());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews.length, 1);
      expect(bloc.state.reviews[0].id, 'review-2');
    });
  });

  group('ReviewsListBloc - State Validation', () {
    test('clears error on successful operation after error', () async {
      // Arrange
      when(() => mockRepository.getAllReviews()).thenThrow(Exception('Error'));

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // First call causes error
      bloc.add(const ReviewsListEvent.loadAll());
      await pumpEventQueue();
      expect(bloc.state.error, isNotNull);

      // Reset stub for successful call
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => [TestData.review()]);

      // Act - Second call succeeds
      bloc.add(const ReviewsListEvent.loadAll());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.error, isNull);
      expect(bloc.state.reviews.length, 1);
    });

    test('maintains reviews in state when delete fails', () async {
      // Arrange
      final testReviews = [TestData.review(id: 'review-1')];
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => testReviews);
      when(
        () => mockRepository.deleteReview(any()),
      ).thenThrow(Exception('Failed'));

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      final initialLength = bloc.state.reviews.length;

      // Act
      bloc.add(const ReviewsListEvent.deleteReview('review-1'));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.reviews.length, initialLength);
      expect(bloc.state.error, isNotNull);
    });

    test('isLoading is false after operation completes', () async {
      // Arrange
      when(
        () => mockRepository.getAllReviews(),
      ).thenAnswer((_) async => [TestData.review()]);

      bloc = ReviewsListBloc(mockRepository);
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewsListEvent.loadAll());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.isLoading, false);
    });
  });
}

/// Helper to process all pending microtasks
Future<void> pumpEventQueue() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
}
