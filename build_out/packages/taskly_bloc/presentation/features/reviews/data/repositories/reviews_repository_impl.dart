import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_query.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/repositories/reviews_repository.dart';

class ReviewsRepositoryImpl implements ReviewsRepository {
  ReviewsRepositoryImpl(this._db);
  final AppDatabase _db;

  @override
  Future<List<Review>> getAllReviews() async {
    final query = _db.select(_db.reviews)
      ..where((r) => r.deletedAt.isNull())
      ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]);

    final results = await query.get();
    return results.map(_mapToReview).toList();
  }

  @override
  Future<List<Review>> getDueReviews() async {
    final now = DateTime.now();
    final query = _db.select(_db.reviews)
      ..where(
        (r) => r.deletedAt.isNull() & r.nextDueDate.isSmallerOrEqualValue(now),
      )
      ..orderBy([(r) => OrderingTerm.asc(r.nextDueDate)]);

    final results = await query.get();
    return results.map(_mapToReview).toList();
  }

  @override
  Future<Review?> getReview(String id) async {
    final query = _db.select(_db.reviews)
      ..where((r) => r.id.equals(id) & r.deletedAt.isNull());

    final result = await query.getSingleOrNull();
    return result != null ? _mapToReview(result) : null;
  }

  @override
  Future<void> saveReview(Review review) async {
    final companion = ReviewsCompanion(
      id: Value(review.id.isEmpty ? _generateId() : review.id),
      name: Value(review.name),
      description: Value(review.description),
      query: Value(jsonEncode(review.query.toJson())),
      rrule: Value(review.rrule),
      nextDueDate: Value(review.nextDueDate),
      lastCompletedAt: Value(review.lastCompletedAt),
      createdAt: Value(review.createdAt),
      updatedAt: Value(DateTime.now()),
      deletedAt: Value(review.deletedAt),
    );

    await _db.into(_db.reviews).insertOnConflictUpdate(companion);
  }

  @override
  Future<void> deleteReview(String reviewId) async {
    await (_db.update(_db.reviews)..where((r) => r.id.equals(reviewId))).write(
      ReviewsCompanion(deletedAt: Value(DateTime.now())),
    );
  }

  @override
  Future<void> completeReview(String reviewId, DateTime completedAt) async {
    await (_db.update(_db.reviews)..where((r) => r.id.equals(reviewId))).write(
      ReviewsCompanion(
        lastCompletedAt: Value(completedAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateNextDueDate(String reviewId, DateTime nextDueDate) async {
    await (_db.update(_db.reviews)..where((r) => r.id.equals(reviewId))).write(
      ReviewsCompanion(
        nextDueDate: Value(nextDueDate),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Review _mapToReview(ReviewEntity entity) {
    return Review(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      query: ReviewQuery.fromJson(
        jsonDecode(entity.query) as Map<String, dynamic>,
      ),
      rrule: entity.rrule,
      nextDueDate: entity.nextDueDate,
      lastCompletedAt: entity.lastCompletedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      deletedAt: entity.deletedAt,
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
