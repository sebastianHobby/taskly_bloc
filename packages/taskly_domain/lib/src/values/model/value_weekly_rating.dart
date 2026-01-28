import 'package:meta/meta.dart';

@immutable
final class ValueWeeklyRating {
  const ValueWeeklyRating({
    required this.id,
    required this.valueId,
    required this.weekStartUtc,
    required this.rating,
    required this.createdAtUtc,
    required this.updatedAtUtc,
  });

  final String id;
  final String valueId;
  final DateTime weekStartUtc;
  final int rating;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
}
