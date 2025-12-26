import 'package:taskly_bloc/presentation/features/reviews/domain/models/review.dart';

abstract class ReviewsRepository {
  /// Get all reviews for the authenticated user
  Future<List<Review>> getAllReviews();

  /// Get reviews due today or overdue
  Future<List<Review>> getDueReviews();

  /// Get a single review by ID
  Future<Review?> getReview(String id);

  /// Save a review (insert or update)
  Future<void> saveReview(Review review);

  /// Delete a review
  Future<void> deleteReview(String reviewId);

  /// Mark review as completed
  Future<void> completeReview(String reviewId, DateTime completedAt);

  /// Update next due date for a review
  Future<void> updateNextDueDate(String reviewId, DateTime nextDueDate);
}
