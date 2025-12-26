import 'package:flutter_test/flutter_test.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/presentation/blocs/review_detail/review_detail_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../fixtures/test_data.dart';
import '../../../../../mocks/wellbeing_reviews_mocks.dart';
import '../../../../../mocks/repository_mocks.dart';

void main() {
  late MockReviewsRepository mockReviewsRepository;
  late MockReviewActionService mockActionService;
  late MockTaskRepository mockTaskRepository;
  late ReviewDetailBloc bloc;

  setUpAll(() {
    // Register fallback values for custom types
    registerFallbackValue(TestData.task());
    registerFallbackValue(TestData.project());
    registerFallbackValue(const ReviewAction(type: ReviewActionType.complete));
    registerFallbackValue(TestData.review());
    registerFallbackValue(const TaskQuery());
  });

  setUp(() {
    mockReviewsRepository = MockReviewsRepository();
    mockActionService = MockReviewActionService();
    mockTaskRepository = MockTaskRepository();
  });

  tearDown(() {
    bloc.close();
  });

  Future<void> pumpEventQueue() async {
    await Future<void>.delayed(Duration.zero);
  }

  group('ReviewDetailBloc - Initial State', () {
    test('initial state has no data and is loading', () {
      // Act
      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Assert
      expect(bloc.state.review, isNull);
      expect(bloc.state.tasks, isEmpty);
      expect(bloc.state.projects, isEmpty);
      expect(bloc.state.actions, isEmpty);
      expect(bloc.state.isLoading, true);
      expect(bloc.state.isExecutingActions, false);
      expect(bloc.state.error, isNull);
    });
  });

  group('ReviewDetailBloc - Load Event', () {
    test('emits loading then loaded state with review', () async {
      // Arrange
      final testReview = TestData.review(id: 'review-1');
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => testReview);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.load('review-1'));

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewDetailState>(
            (state) => state.isLoading && state.review == null,
          ),
          predicate<ReviewDetailState>(
            (state) =>
                !state.isLoading &&
                state.review != null &&
                state.review!.id == 'review-1',
          ),
        ]),
      );
    });

    test('automatically loads entities after loading review', () async {
      // Arrange
      final testReview = TestData.review();
      final testTasks = [TestData.task(id: 'task-1')];

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => testReview);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value(testTasks));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      await pumpEventQueue(); // Wait for loadEntities event

      // Assert
      expect(bloc.state.tasks, isNotEmpty);
    });

    test('emits error state when review not found', () async {
      // Arrange
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => null);

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.load('nonexistent-id'));

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewDetailState>((state) => state.isLoading),
          predicate<ReviewDetailState>(
            (state) =>
                !state.isLoading &&
                state.error != null &&
                state.error!.contains('not found'),
          ),
        ]),
      );
    });

    test('emits error state when repository throws exception', () async {
      // Arrange
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenThrow(Exception('Database error'));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.load('review-1'));

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewDetailState>((state) => state.isLoading),
          predicate<ReviewDetailState>(
            (state) => !state.isLoading && state.error != null,
          ),
        ]),
      );
    });

    test('calls repository with correct review ID', () async {
      // Arrange
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => TestData.review());
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.load('specific-review-id'));
      await pumpEventQueue();

      // Assert
      verify(
        () => mockReviewsRepository.getReview('specific-review-id'),
      ).called(1);
    });
  });

  group('ReviewDetailBloc - LoadEntities Event', () {
    test('loads tasks when review query is for tasks', () async {
      // Arrange
      final testReview = TestData.review();
      final testTasks = [
        TestData.task(id: 'task-1', name: 'Task 1'),
        TestData.task(id: 'task-2', name: 'Task 2'),
      ];

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => testReview);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value(testTasks));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      await pumpEventQueue(); // Wait for automatic loadEntities

      // Assert
      expect(bloc.state.tasks.length, 2);
      expect(bloc.state.tasks[0].id, 'task-1');
      expect(bloc.state.tasks[1].id, 'task-2');
    });

    test('handles empty task list', () async {
      // Arrange
      final testReview = TestData.review();

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => testReview);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      await pumpEventQueue();

      // Assert
      expect(bloc.state.tasks, isEmpty);
      expect(bloc.state.error, isNull);
    });

    test('handles error when loading entities fails', () async {
      // Arrange
      final testReview = TestData.review();

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => testReview);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.error(Exception('Failed to load tasks')));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      await pumpEventQueue();
      await pumpEventQueue(); // Allow error to propagate

      // Assert
      expect(bloc.state.error, isNotNull);
    });

    test('does nothing if review is null', () async {
      // Arrange
      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.loadEntities());
      await pumpEventQueue();

      // Assert
      verifyNever(() => mockTaskRepository.watchAll(any()));
      expect(bloc.state.tasks, isEmpty);
    });
  });

  group('ReviewDetailBloc - ExecuteAction Event', () {
    test('adds action to state for entity', () async {
      // Arrange
      final review = TestData.review();
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();

      // Act
      const action = ReviewAction(type: ReviewActionType.complete);
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: action,
        ),
      );
      await pumpEventQueue();

      // Assert
      expect(bloc.state.actions.containsKey('task-1'), true);
      expect(bloc.state.actions['task-1']?.type, ReviewActionType.complete);
    });

    test('can set different actions for different entities', () async {
      // Arrange
      final review = TestData.review();
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();

      // Act
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: ReviewAction(type: ReviewActionType.complete),
        ),
      );
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-2',
          action: ReviewAction(type: ReviewActionType.skip),
        ),
      );
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-3',
          action: ReviewAction(type: ReviewActionType.delete),
        ),
      );
      await pumpEventQueue();

      // Assert
      expect(bloc.state.actions.length, 3);
      expect(bloc.state.actions['task-1']?.type, ReviewActionType.complete);
      expect(bloc.state.actions['task-2']?.type, ReviewActionType.skip);
      expect(bloc.state.actions['task-3']?.type, ReviewActionType.delete);
    });

    test('can update action for same entity', () async {
      // Arrange
      final review = TestData.review();
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();

      // Act - First action
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: ReviewAction(type: ReviewActionType.complete),
        ),
      );
      await pumpEventQueue();
      expect(bloc.state.actions['task-1']?.type, ReviewActionType.complete);

      // Act - Update action
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: ReviewAction(type: ReviewActionType.skip),
        ),
      );
      await pumpEventQueue();

      // Assert
      expect(bloc.state.actions.length, 1);
      expect(bloc.state.actions['task-1']?.type, ReviewActionType.skip);
    });

    test('preserves actions for other entities when updating one', () async {
      // Arrange
      final review = TestData.review();
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();

      // Set multiple actions
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: ReviewAction(type: ReviewActionType.complete),
        ),
      );
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-2',
          action: ReviewAction(type: ReviewActionType.skip),
        ),
      );
      await pumpEventQueue();

      // Act - Update one
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: ReviewAction(type: ReviewActionType.delete),
        ),
      );
      await pumpEventQueue();

      // Assert
      expect(bloc.state.actions.length, 2);
      expect(bloc.state.actions['task-1']?.type, ReviewActionType.delete);
      expect(bloc.state.actions['task-2']?.type, ReviewActionType.skip);
    });
  });

  group('ReviewDetailBloc - CompleteReview Event', () {
    test('executes all actions for tasks', () async {
      // Arrange
      final review = TestData.review();
      final tasks = [
        TestData.task(id: 'task-1'),
        TestData.task(id: 'task-2'),
      ];

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value(tasks));
      when(
        () => mockActionService.executeTaskAction(any(), any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockReviewsRepository.completeReview(any(), any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      await pumpEventQueue();

      // Set actions
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: ReviewAction(type: ReviewActionType.complete),
        ),
      );
      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-2',
          action: ReviewAction(type: ReviewActionType.skip),
        ),
      );
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewDetailEvent.completeReview());
      await pumpEventQueue();

      // Assert
      verify(() => mockActionService.executeTaskAction(any(), any())).called(2);
    });

    test('marks review as completed', () async {
      // Arrange
      final review = TestData.review();

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockReviewsRepository.completeReview(any(), any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockReviewsRepository.updateNextDueDate(any(), any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewDetailEvent.completeReview());
      await pumpEventQueue();

      // Assert
      verify(
        () => mockReviewsRepository.completeReview(any(), any()),
      ).called(1);
      verify(
        () => mockReviewsRepository.updateNextDueDate(any(), any()),
      ).called(1);
    });

    test('emits executing actions state during execution', () async {
      // Arrange
      final review = TestData.review();

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockReviewsRepository.completeReview(any(), any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewDetailEvent.completeReview());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewDetailState>(
            (state) => state.isExecutingActions && state.error == null,
          ),
          predicate<ReviewDetailState>(
            (state) => !state.isExecutingActions,
          ),
        ]),
      );
    });

    test('emits error when action execution fails', () async {
      // Arrange
      final review = TestData.review();
      final tasks = [TestData.task(id: 'task-1')];

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value(tasks));
      when(
        () => mockActionService.executeTaskAction(any(), any()),
      ).thenThrow(Exception('Action failed'));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      await pumpEventQueue();

      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: ReviewAction(type: ReviewActionType.complete),
        ),
      );
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewDetailEvent.completeReview());

      // Assert
      await expectLater(
        bloc.stream,
        emitsInOrder([
          predicate<ReviewDetailState>((state) => state.isExecutingActions),
          predicate<ReviewDetailState>(
            (state) => !state.isExecutingActions && state.error != null,
          ),
        ]),
      );
    });

    test('does nothing when review is null', () async {
      // Arrange
      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // Act
      bloc.add(const ReviewDetailEvent.completeReview());
      await pumpEventQueue();

      // Assert
      verifyNever(() => mockActionService.executeTaskAction(any(), any()));
    });

    test('handles empty actions map', () async {
      // Arrange
      final review = TestData.review();

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));
      when(
        () => mockReviewsRepository.completeReview(any(), any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();

      // Act - No actions set
      bloc.add(const ReviewDetailEvent.completeReview());
      await pumpEventQueue();

      // Assert
      verifyNever(() => mockActionService.executeTaskAction(any(), any()));
      verify(
        () => mockReviewsRepository.completeReview(any(), any()),
      ).called(1);
      verify(
        () => mockReviewsRepository.updateNextDueDate(any(), any()),
      ).called(1);
    });

    test('calls executeTaskAction with correct parameters', () async {
      // Arrange
      final review = TestData.review();
      final task = TestData.task(id: 'task-1');
      const action = ReviewAction(type: ReviewActionType.complete);

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([task]));
      when(
        () => mockActionService.executeTaskAction(any(), any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockReviewsRepository.completeReview(any(), any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      await pumpEventQueue();

      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: action,
        ),
      );
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewDetailEvent.completeReview());
      await pumpEventQueue();

      // Assert
      verify(() => mockActionService.executeTaskAction(task, action)).called(1);
    });
  });

  group('ReviewDetailBloc - State Transitions', () {
    test('clears error on successful load after previous error', () async {
      // Arrange
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenThrow(Exception('Error'));

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );

      // First load fails
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      expect(bloc.state.error, isNotNull);

      // Reset stub for successful call
      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => TestData.review());
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value([]));

      // Act - Second load succeeds
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();

      // Assert
      expect(bloc.state.error, isNull);
      expect(bloc.state.review, isNotNull);
    });

    test('maintains loaded data when executing actions', () async {
      // Arrange
      final review = TestData.review();
      final tasks = [TestData.task()];

      when(
        () => mockReviewsRepository.getReview(any()),
      ).thenAnswer((_) async => review);
      when(
        () => mockTaskRepository.watchAll(any()),
      ).thenAnswer((_) => Stream.value(tasks));
      when(
        () => mockActionService.executeTaskAction(any(), any()),
      ).thenAnswer((_) async => {});
      when(
        () => mockReviewsRepository.completeReview(any(), any()),
      ).thenAnswer((_) async => {});

      bloc = ReviewDetailBloc(
        mockReviewsRepository,
        mockActionService,
        mockTaskRepository,
      );
      bloc.add(const ReviewDetailEvent.load('review-1'));
      await pumpEventQueue();
      await pumpEventQueue();

      bloc.add(
        const ReviewDetailEvent.executeAction(
          entityId: 'task-1',
          action: ReviewAction(type: ReviewActionType.complete),
        ),
      );
      await pumpEventQueue();

      // Act
      bloc.add(const ReviewDetailEvent.completeReview());
      await pumpEventQueue();

      // Assert
      expect(bloc.state.review, isNotNull);
      expect(bloc.state.tasks, isNotEmpty);
    });
  });
}
