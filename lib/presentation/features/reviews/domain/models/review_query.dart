import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/features/analytics/domain/models/entity_type.dart';

part 'review_query.freezed.dart';
part 'review_query.g.dart';

@freezed
abstract class ReviewQuery with _$ReviewQuery {
  const factory ReviewQuery({
    required EntityType entityType,
    List<String>? projectIds,
    List<String>? labelIds,
    List<String>? valueIds,
    bool? includeCompleted,
    bool? includeArchived,
    DateTime? completedBefore,
    DateTime? completedAfter,
    DateTime? createdBefore,
    DateTime? createdAfter,
    int? limit,
  }) = _ReviewQuery;

  factory ReviewQuery.fromJson(Map<String, dynamic> json) =>
      _$ReviewQueryFromJson(json);
}
