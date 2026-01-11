import 'package:freezed_annotation/freezed_annotation.dart';

part 'action.freezed.dart';
part 'action.g.dart';

/// Actions that can be performed during workflow screen reviews
@freezed
sealed class Action with _$Action {
  /// Mark item as reviewed, updates lastReviewedAt timestamp
  const factory Action.markReviewed({
    String? notes,
  }) = MarkReviewedAction;

  /// Skip item in this review cycle (no timestamp update)
  const factory Action.skip({
    String? reason,
  }) = SkipAction;

  factory Action.fromJson(Map<String, dynamic> json) => _$ActionFromJson(json);
}
