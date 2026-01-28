import 'package:taskly_domain/src/telemetry/operation_context.dart';
import 'package:taskly_domain/src/values/model/value_weekly_rating.dart';

abstract class ValueRatingsRepositoryContract {
  Stream<List<ValueWeeklyRating>> watchAll({int weeks = 4});

  Future<List<ValueWeeklyRating>> getAll({int weeks = 4});

  Future<List<ValueWeeklyRating>> getForValue(
    String valueId, {
    int weeks = 4,
  });

  Future<void> upsertWeeklyRating({
    required String valueId,
    required DateTime weekStartUtc,
    required int rating,
    OperationContext? context,
  });
}
