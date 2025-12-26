import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';

part 'reviews_list_bloc.freezed.dart';

// Events
@freezed
class ReviewsListEvent with _$ReviewsListEvent {
  const factory ReviewsListEvent.loadAll() = _LoadAll;
  const factory ReviewsListEvent.loadDue() = _LoadDue;
  const factory ReviewsListEvent.deleteReview(String reviewId) = _DeleteReview;
}

// State
@freezed
abstract class ReviewsListState with _$ReviewsListState {
  const factory ReviewsListState({
    @Default([]) List<Review> reviews,
    @Default(true) bool isLoading,
    String? error,
  }) = _ReviewsListState;
}

// BLoC
class ReviewsListBloc extends Bloc<ReviewsListEvent, ReviewsListState> {
  ReviewsListBloc(this._repository) : super(const ReviewsListState()) {
    on<_LoadAll>(_onLoadAll);
    on<_LoadDue>(_onLoadDue);
    on<_DeleteReview>(_onDeleteReview);

    // Automatically load all reviews on initialization
    add(const ReviewsListEvent.loadAll());
  }
  final ReviewsRepository _repository;

  Future<void> _onLoadAll(_LoadAll event, Emitter emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final reviews = await _repository.getAllReviews();
      emit(state.copyWith(reviews: reviews, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onLoadDue(_LoadDue event, Emitter emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final reviews = await _repository.getDueReviews();
      emit(state.copyWith(reviews: reviews, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onDeleteReview(_DeleteReview event, Emitter emit) async {
    try {
      await _repository.deleteReview(event.reviewId);
      final updatedReviews = state.reviews
          .where((r) => r.id != event.reviewId)
          .toList();
      emit(state.copyWith(reviews: updatedReviews));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
