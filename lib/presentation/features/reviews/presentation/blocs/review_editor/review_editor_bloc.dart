import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';

part 'review_editor_bloc.freezed.dart';

// Events
@freezed
class ReviewEditorEvent with _$ReviewEditorEvent {
  const factory ReviewEditorEvent.load(String reviewId) = _Load;
  const factory ReviewEditorEvent.updateReview(Review review) = _UpdateReview;
  const factory ReviewEditorEvent.save() = _Save;
}

// State
@freezed
abstract class ReviewEditorState with _$ReviewEditorState {
  const factory ReviewEditorState({
    Review? review,
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default(false) bool isSaved,
    String? error,
  }) = _ReviewEditorState;
}

// BLoC
class ReviewEditorBloc extends Bloc<ReviewEditorEvent, ReviewEditorState> {
  ReviewEditorBloc(this._repository) : super(const ReviewEditorState()) {
    on<_Load>(_onLoad);
    on<_UpdateReview>(_onUpdateReview);
    on<_Save>(_onSave);
  }
  final ReviewsRepository _repository;

  Future<void> _onLoad(_Load event, Emitter emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final review = await _repository.getReview(event.reviewId);
      emit(state.copyWith(review: review, isLoading: false));
    } catch (e) {
      emit(state.copyWith(error: e.toString(), isLoading: false));
    }
  }

  Future<void> _onUpdateReview(_UpdateReview event, Emitter emit) async {
    emit(state.copyWith(review: event.review, isSaved: false));
  }

  Future<void> _onSave(_Save event, Emitter emit) async {
    final review = state.review;
    if (review == null) return;

    emit(state.copyWith(isSaving: true, error: null));
    try {
      await _repository.saveReview(review);
      emit(state.copyWith(isSaving: false, isSaved: true));
    } catch (e) {
      emit(
        state.copyWith(
          error: e.toString(),
          isSaving: false,
          isSaved: false,
        ),
      );
    }
  }
}
