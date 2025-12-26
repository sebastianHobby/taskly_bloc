import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_query.dart';

part 'review.freezed.dart';
part 'review.g.dart';

@freezed
abstract class Review with _$Review {
  @JsonSerializable(explicitToJson: true)
  const factory Review({
    required String id,
    required String name,
    required ReviewQuery query,
    required String rrule,
    required DateTime nextDueDate,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? description,
    DateTime? lastCompletedAt,
    DateTime? deletedAt,
  }) = _Review;

  factory Review.fromJson(Map<String, dynamic> json) => _$ReviewFromJson(json);
}
