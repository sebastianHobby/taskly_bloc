import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/presentation/features/reviews/domain/models/review_action_type.dart';

part 'review_action.freezed.dart';
part 'review_action.g.dart';

@freezed
abstract class ReviewAction with _$ReviewAction {
  const factory ReviewAction({
    required ReviewActionType type,
    Map<String, dynamic>? updateData,
    String? notes,
  }) = _ReviewAction;

  factory ReviewAction.fromJson(Map<String, dynamic> json) =>
      _$ReviewActionFromJson(json);
}
