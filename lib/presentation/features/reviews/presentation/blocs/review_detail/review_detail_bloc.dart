import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/domain/contracts/task_repository_contract.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/services/review_action_service.dart';

part 'review_detail_bloc.freezed.dart';

// Events
@freezed
class ReviewDetailEvent with _$ReviewDetailEvent {
  const factory ReviewDetailEvent.load(String reviewId) = _Load;
  const factory ReviewDetailEvent.loadEntities() = _LoadEntities;
  const factory ReviewDetailEvent.executeAction({
    required String entityId,
    required ReviewAction action,
  }) = _ExecuteAction;
  const factory ReviewDetailEvent.completeReview() = _CompleteReview;
}

// State
@freezed
abstract class ReviewDetailState with _$ReviewDetailState {
  const factory ReviewDetailState({
    Review? review,
    @Default([]) List<Task> tasks,
    @Default([]) List<Project> projects,
    @Default({}) Map<String, ReviewAction> actions,
    @Default(true) bool isLoading,
    @Default(false) bool isExecutingActions,
    String? error,
  }) = _ReviewDetailState;
}

// BLoC
class ReviewDetailBloc extends Bloc<ReviewDetailEvent, ReviewDetailState> {
  ReviewDetailBloc(
    this._reviewsRepository,
    this._actionService,
    this._taskRepository,
  ) : super(const ReviewDetailState()) {
    on<_Load>(_onLoad);
    on<_LoadEntities>(_onLoadEntities);
    on<_ExecuteAction>(_onExecuteAction);
    on<_CompleteReview>(_onCompleteReview);
  }
  final ReviewsRepository _reviewsRepository;
  final ReviewActionService _actionService;
  final TaskRepositoryContract _taskRepository;

  Future<void> _onLoad(_Load event, Emitter emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final review = await _reviewsRepository.getReview(event.reviewId);
      if (review != null) {
        emit(state.copyWith(review: review, isLoading: false));
        add(const ReviewDetailEvent.loadEntities());
      } else {
        emit(
          state.copyWith(
            error: 'Review not found',
            isLoading: false,
          ),
        );
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onLoadEntities(_LoadEntities event, Emitter emit) async {
    final review = state.review;
    if (review == null) return;

    try {
      if (review.query.entityType == EntityType.task) {
        // Load tasks matching the query
        // TODO: Implement query filtering based on ReviewQuery
        final tasks = await _taskRepository.watchAll().first;
        emit(state.copyWith(tasks: tasks));
      } else if (review.query.entityType == EntityType.project) {
        // Load projects matching the query
        // TODO: Implement when ProjectRepository is available
        emit(state.copyWith(projects: []));
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onExecuteAction(_ExecuteAction event, Emitter emit) async {
    final updatedActions = Map<String, ReviewAction>.from(state.actions);
    updatedActions[event.entityId] = event.action;
    emit(state.copyWith(actions: updatedActions));
  }

  Future<void> _onCompleteReview(_CompleteReview event, Emitter emit) async {
    final review = state.review;
    if (review == null) return;

    emit(state.copyWith(isExecutingActions: true, error: null));

    try {
      // Execute all actions
      for (final entry in state.actions.entries) {
        final entityId = entry.key;
        final action = entry.value;

        if (review.query.entityType == EntityType.task) {
          final task = state.tasks.firstWhere((t) => t.id == entityId);
          await _actionService.executeTaskAction(task, action);
        } else if (review.query.entityType == EntityType.project) {
          final project = state.projects.firstWhere((p) => p.id == entityId);
          await _actionService.executeProjectAction(project, action);
        }
      }

      // Mark review as completed
      final now = DateTime.now();
      await _reviewsRepository.completeReview(review.id, now);

      // Calculate next due date based on RRULE
      // TODO: Implement RRULE calculation
      final nextDueDate = now.add(const Duration(days: 7));
      await _reviewsRepository.updateNextDueDate(review.id, nextDueDate);

      emit(
        state.copyWith(
          isExecutingActions: false,
          actions: {},
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: e.toString(),
          isExecutingActions: false,
        ),
      );
    }
  }
}
