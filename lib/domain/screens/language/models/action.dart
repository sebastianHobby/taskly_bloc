import 'package:freezed_annotation/freezed_annotation.dart';

part 'action.freezed.dart';
part 'action.g.dart';

/// Actions that can be performed during screen reviews.
@freezed
sealed class Action with _$Action {
  /// Mark an item as reviewed.
  const factory Action.markReviewed({
    String? notes,
  }) = MarkReviewedAction;

  /// Skip an item in this review cycle.
  const factory Action.skip({
    String? reason,
  }) = SkipAction;

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);
}
