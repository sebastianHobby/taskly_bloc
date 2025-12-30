import 'package:freezed_annotation/freezed_annotation.dart';

part 'completion_criteria.freezed.dart';
part 'completion_criteria.g.dart';

/// Completion criteria for workflow screens
@freezed
abstract class CompletionCriteria with _$CompletionCriteria {
  /// All items must be reviewed or skipped
  const factory CompletionCriteria.allItemsReviewed() = AllItemsReviewed;

  /// Workflow completes after specific duration
  const factory CompletionCriteria.timeElapsed({
    required int minutes,
  }) = TimeElapsed;

  /// Minimum percentage of items reviewed
  const factory CompletionCriteria.percentageReviewed({
    @IntRange(1, 100) required int percentage,
  }) = PercentageReviewed;

  /// Manual completion only
  const factory CompletionCriteria.manual() = ManualCompletion;

  factory CompletionCriteria.fromJson(Map<String, dynamic> json) =>
      _$CompletionCriteriaFromJson(json);
}

class IntRange {
  const IntRange(this.min, this.max);
  final int min;
  final int max;
}
