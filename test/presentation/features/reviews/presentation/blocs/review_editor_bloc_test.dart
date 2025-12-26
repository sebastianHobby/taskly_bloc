import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/blocs/review_editor/review_editor_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fixtures/test_data.dart';
import '../../../../../mocks/wellbeing_reviews_mocks.dart';

void main() {
  late MockReviewsRepository mockRepository;
  late ReviewEditorBloc bloc;

  setUpAll(() {
    registerFallbackValue(TestData.review());
  });

  setUp(() {
    mockRepository = MockReviewsRepository();
  });

  tearDown(() {
    bloc.close();
  });

  Future<void> pumpEventQueue() async {
    await Future<void>.delayed(Duration.zero);
  }

  group('ReviewEditorBloc - Initial State', () {
    test('initial state has no review and is not loading', () {
      // Act
      bloc = ReviewEditorBloc(mockRepository);

      // Assert
      expect(bloc.state.review, isNull);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.isSaving, false);
      expect(bloc.state.isSaved, false);
      expect(bloc.state.error, isNull);
    });
  });

  group('ReviewEditorBloc - Load Event', () {
    test('emits loading then loaded state with review', () async {
      // Arrange
      final testReview = TestData.review(id: 'review-1');
      when(
        () => mockRepository.getReview(any()),
      ).thenAnswer((_) async => testReview);

      bloc = ReviewEditorBloc(mockRepository);

      // Act
      bloc.add(const ReviewEditorEvent.load('review-1'));

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewEditorState>(
            (state) => state.isLoading && state.review == null,
          ),
          predicate<ReviewEditorState>(
            (state) =>
                !state.isLoading &&
                state.review != null &&
                state.review!.id == 'review-1',
          ),
        ]),
      );
    });

    test('emits error state when repository throws exception', () async {
      // Arrange
      when(
        () => mockRepository.getReview(any()),
      ).thenThrow(Exception('Database error'));

      bloc = ReviewEditorBloc(mockRepository);

      // Act
      bloc.add(const ReviewEditorEvent.load('review-1'));

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewEditorState>((state) => state.isLoading),
          predicate<ReviewEditorState>(
            (state) => !state.isLoading && state.error != null,
          ),
        ]),
      );
    });

    test('handles null review from repository', () async {
      // Arrange
      when(() => mockRepository.getReview(any())).thenAnswer((_) async => null);

      bloc = ReviewEditorBloc(mockRepository);

      // Act
      bloc.add(const ReviewEditorEvent.load('review-1'));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.review, isNull);
      expect(bloc.state.isLoading, false);
    });

    test('loads different reviews with different IDs', () async {
      // Arrange
      final review1 = TestData.review(id: 'review-1', name: 'Review 1');
      final review2 = TestData.review(id: 'review-2', name: 'Review 2');

      when(
        () => mockRepository.getReview('review-1'),
      ).thenAnswer((_) async => review1);
      when(
        () => mockRepository.getReview('review-2'),
      ).thenAnswer((_) async => review2);

      bloc = ReviewEditorBloc(mockRepository);

      // Act & Assert
      bloc.add(const ReviewEditorEvent.load('review-1'));
      await pumpEventQueue();
      expect(bloc.state.review?.id, 'review-1');

      bloc.add(const ReviewEditorEvent.load('review-2'));
      await pumpEventQueue();
      expect(bloc.state.review?.id, 'review-2');
    });

    test('calls repository with correct review ID', () async {
      // Arrange
      when(
        () => mockRepository.getReview(any()),
      ).thenAnswer((_) async => TestData.review());

      bloc = ReviewEditorBloc(mockRepository);

      // Act
      bloc.add(const ReviewEditorEvent.load('specific-id'));
      await pumpEventQueue();

      // Assert
      verify(() => mockRepository.getReview('specific-id')).called(1);
    });
  });

  group('ReviewEditorBloc - UpdateReview Event', () {
    test('updates review in state', () async {
      // Arrange
      final originalReview = TestData.review(id: 'review-1', name: 'Original');
      final updatedReview = TestData.review(id: 'review-1', name: 'Updated');

      when(
        () => mockRepository.getReview(any()),
      ).thenAnswer((_) async => originalReview);

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(const ReviewEditorEvent.load('review-1'));
      await pumpEventQueue();

      // Act
      bloc.add(ReviewEditorEvent.updateReview(updatedReview));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.review?.name, 'Updated');
    });

    test('sets isSaved to false when review is updated', () async {
      // Arrange
      final review = TestData.review();
      when(
        () => mockRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(const ReviewEditorEvent.load('review-1'));
      await pumpEventQueue();

      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();
      expect(bloc.state.isSaved, true);

      // Act - Update review
      final updatedReview = TestData.review(name: 'Changed');
      bloc.add(ReviewEditorEvent.updateReview(updatedReview));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.isSaved, false);
    });

    test('handles multiple consecutive updates', () async {
      // Arrange
      bloc = ReviewEditorBloc(mockRepository);
      final review1 = TestData.review(name: 'Name 1');
      final review2 = TestData.review(name: 'Name 2');
      final review3 = TestData.review(name: 'Name 3');

      // Act
      bloc.add(ReviewEditorEvent.updateReview(review1));
      await pumpEventQueue();
      bloc.add(ReviewEditorEvent.updateReview(review2));
      await pumpEventQueue();
      bloc.add(ReviewEditorEvent.updateReview(review3));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.review?.name, 'Name 3');
    });

    test('maintains error state when updating review', () async {
      // Arrange
      when(() => mockRepository.getReview(any())).thenThrow(Exception('Error'));

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(const ReviewEditorEvent.load('review-1'));
      await pumpEventQueue();

      expect(bloc.state.error, isNotNull);

      // Act
      final updatedReview = TestData.review();
      bloc.add(ReviewEditorEvent.updateReview(updatedReview));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.error, isNotNull); // Error persists
      expect(bloc.state.review, isNotNull); // But review is updated
    });
  });

  group('ReviewEditorBloc - Save Event', () {
    test('emits saving then saved state', () async {
      // Arrange
      final review = TestData.review();
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(ReviewEditorEvent.updateReview(review));

      // Act
      bloc.add(const ReviewEditorEvent.save());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewEditorState>(
            (state) => state.review != null && !state.isSaved,
          ),
          predicate<ReviewEditorState>(
            (state) => state.isSaving && !state.isSaved,
          ),
          predicate<ReviewEditorState>(
            (state) => !state.isSaving && state.isSaved,
          ),
        ]),
      );
    });

    test('calls repository with correct review', () async {
      // Arrange
      final testReview = TestData.review(id: 'review-1', name: 'Test');
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(ReviewEditorEvent.updateReview(testReview));
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert
      verify(() => mockRepository.saveReview(testReview)).called(1);
    });

    test('emits error state when save fails', () async {
      // Arrange
      final review = TestData.review();
      when(
        () => mockRepository.saveReview(any()),
      ).thenThrow(Exception('Save failed'));

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(ReviewEditorEvent.updateReview(review));

      // Act
      bloc.add(const ReviewEditorEvent.save());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewEditorState>((state) => !state.isSaved),
          predicate<ReviewEditorState>((state) => state.isSaving),
          predicate<ReviewEditorState>(
            (state) => !state.isSaving && !state.isSaved && state.error != null,
          ),
        ]),
      );
    });

    test('does nothing when review is null', () async {
      // Arrange
      bloc = ReviewEditorBloc(mockRepository);

      // Act
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert
      verifyNever(() => mockRepository.saveReview(any()));
      expect(bloc.state.isSaving, false);
      expect(bloc.state.isSaved, false);
    });

    test('clears error on successful save after previous error', () async {
      // Arrange
      final review = TestData.review();
      when(
        () => mockRepository.saveReview(any()),
      ).thenThrow(Exception('Error'));

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(ReviewEditorEvent.updateReview(review));
      await pumpEventQueue();

      // First save fails
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();
      expect(bloc.state.error, isNotNull);

      // Reset stub for successful call
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      // Act - Second save succeeds
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.error, isNull);
      expect(bloc.state.isSaved, true);
    });

    test('can save multiple times', () async {
      // Arrange
      final review = TestData.review();
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(ReviewEditorEvent.updateReview(review));
      await pumpEventQueue();

      // Act - First save
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();
      expect(bloc.state.isSaved, true);

      // Modify review
      final updatedReview = TestData.review(name: 'Changed');
      bloc.add(ReviewEditorEvent.updateReview(updatedReview));
      await pumpEventQueue();
      expect(bloc.state.isSaved, false);

      // Act - Second save
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.isSaved, true);
      verify(() => mockRepository.saveReview(any())).called(2);
    });
  });

  group('ReviewEditorBloc - Complex Workflows', () {
    test('load -> update -> save workflow', () async {
      // Arrange
      final originalReview = TestData.review(id: 'review-1', name: 'Original');
      final updatedReview = TestData.review(id: 'review-1', name: 'Updated');

      when(
        () => mockRepository.getReview(any()),
      ).thenAnswer((_) async => originalReview);
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);

      // Act
      bloc.add(const ReviewEditorEvent.load('review-1'));
      await pumpEventQueue();
      expect(bloc.state.review?.name, 'Original');

      bloc.add(ReviewEditorEvent.updateReview(updatedReview));
      await pumpEventQueue();
      expect(bloc.state.review?.name, 'Updated');

      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.isSaved, true);
      verify(() => mockRepository.saveReview(updatedReview)).called(1);
    });

    test(
      'handles load error followed by manual review entry and save',
      () async {
        // Arrange
        when(
          () => mockRepository.getReview(any()),
        ).thenThrow(Exception('Not found'));
        when(
          () => mockRepository.saveReview(any()),
        ).thenAnswer((_) async => {});

        bloc = ReviewEditorBloc(mockRepository);

        // Act - Load fails
        bloc.add(const ReviewEditorEvent.load('review-1'));
        await pumpEventQueue();
        expect(bloc.state.error, isNotNull);

        // Manually set review
        final newReview = TestData.review(id: 'review-1', name: 'New');
        bloc.add(ReviewEditorEvent.updateReview(newReview));
        await pumpEventQueue();
        expect(bloc.state.review, isNotNull);

        // Save succeeds
        bloc.add(const ReviewEditorEvent.save());
        await pumpEventQueue();

        // Assert
        expect(bloc.state.isSaved, true);
      },
    );

    test('multiple updates followed by single save', () async {
      // Arrange
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);

      // Act - Multiple updates
      bloc.add(ReviewEditorEvent.updateReview(TestData.review(name: 'V1')));
      await pumpEventQueue();
      bloc.add(ReviewEditorEvent.updateReview(TestData.review(name: 'V2')));
      await pumpEventQueue();
      bloc.add(ReviewEditorEvent.updateReview(TestData.review(name: 'V3')));
      await pumpEventQueue();

      // Single save
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert
      verify(() => mockRepository.saveReview(any())).called(1);
      expect(bloc.state.review?.name, 'V3');
    });

    test('load -> update -> save -> load another workflow', () async {
      // Arrange
      final review1 = TestData.review(id: 'review-1', name: 'Review 1');
      final review2 = TestData.review(id: 'review-2', name: 'Review 2');

      when(
        () => mockRepository.getReview('review-1'),
      ).thenAnswer((_) async => review1);
      when(
        () => mockRepository.getReview('review-2'),
      ).thenAnswer((_) async => review2);
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);

      // Act - First review workflow
      bloc.add(const ReviewEditorEvent.load('review-1'));
      await pumpEventQueue();
      bloc.add(
        ReviewEditorEvent.updateReview(review1.copyWith(name: 'Modified 1')),
      );
      await pumpEventQueue();
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();
      expect(bloc.state.isSaved, true);

      // Load second review
      bloc.add(const ReviewEditorEvent.load('review-2'));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.review?.id, 'review-2');
      expect(bloc.state.isLoading, false);
    });

    test('save -> update -> save workflow resets isSaved flag', () async {
      // Arrange
      final review = TestData.review();
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(ReviewEditorEvent.updateReview(review));
      await pumpEventQueue();

      // Act - First save
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();
      expect(bloc.state.isSaved, true);

      // Update
      bloc.add(
        ReviewEditorEvent.updateReview(review.copyWith(name: 'Changed')),
      );
      await pumpEventQueue();
      expect(bloc.state.isSaved, false);

      // Second save
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.isSaved, true);
    });
  });

  group('ReviewEditorBloc - State Flags', () {
    test('isLoading is true only during load', () async {
      // Arrange
      when(
        () => mockRepository.getReview(any()),
      ).thenAnswer((_) async => TestData.review());

      bloc = ReviewEditorBloc(mockRepository);

      // Initial
      expect(bloc.state.isLoading, false);

      // Act
      bloc.add(const ReviewEditorEvent.load('review-1'));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.isLoading, false);
    });

    test('isSaving is true only during save', () async {
      // Arrange
      final review = TestData.review();
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(ReviewEditorEvent.updateReview(review));
      await pumpEventQueue();

      // Initial
      expect(bloc.state.isSaving, false);

      // Act
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.isSaving, false);
      expect(bloc.state.isSaved, true);
    });

    test('isSaved persists until review is updated', () async {
      // Arrange
      final review = TestData.review();
      when(() => mockRepository.saveReview(any())).thenAnswer((_) async => {});

      bloc = ReviewEditorBloc(mockRepository);
      bloc.add(ReviewEditorEvent.updateReview(review));
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewEditorEvent.save());
      await pumpEventQueue();

      // Assert - isSaved persists
      expect(bloc.state.isSaved, true);
      await pumpEventQueue();
      expect(bloc.state.isSaved, true);

      // Update review - isSaved is cleared
      bloc.add(
        ReviewEditorEvent.updateReview(review.copyWith(name: 'Changed')),
      );
      await pumpEventQueue();
      expect(bloc.state.isSaved, false);
    });
  });
}
