import 'package:taskly_domain/src/interfaces/value_ratings_repository_contract.dart';
import 'package:taskly_domain/src/telemetry/operation_context.dart';

final class ValueRatingsWriteService {
  ValueRatingsWriteService({
    required ValueRatingsRepositoryContract repository,
  }) : _repository = repository;

  final ValueRatingsRepositoryContract _repository;

  Future<void> recordWeeklyRatings({
    required DateTime weekStartUtc,
    required Map<String, int> ratingsByValueId,
    OperationContext? context,
  }) async {
    for (final entry in ratingsByValueId.entries) {
      final rating = entry.value;
      if (rating <= 0) continue;
      await _repository.upsertWeeklyRating(
        valueId: entry.key,
        weekStartUtc: weekStartUtc,
        rating: rating,
        context: context,
      );
    }
  }
}
