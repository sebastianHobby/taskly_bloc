import 'package:freezed_annotation/freezed_annotation.dart';

part 'attention_resolution.freezed.dart';
part 'attention_resolution.g.dart';

/// Entity types that can have attention resolutions.
enum AttentionEntityType {
  @JsonValue('task')
  task,

  @JsonValue('project')
  project,

  @JsonValue('journal')
  journal,

  @JsonValue('value')
  value,

  @JsonValue('tracker')
  tracker,

  @JsonValue('review_session')
  reviewSession,
}

/// Resolution actions users can take.
enum AttentionResolutionAction {
  @JsonValue('reviewed')
  reviewed,

  @JsonValue('skipped')
  skipped,

  @JsonValue('snoozed')
  snoozed,

  @JsonValue('dismissed')
  dismissed,
}

@freezed
abstract class AttentionResolution with _$AttentionResolution {
  const factory AttentionResolution({
    required String id,
    required String ruleId,
    required String entityId,
    required AttentionEntityType entityType,
    required DateTime resolvedAt,
    required AttentionResolutionAction resolutionAction,
    required DateTime createdAt,
    Map<String, dynamic>? actionDetails,
  }) = _AttentionResolution;

  factory AttentionResolution.fromJson(Map<String, dynamic> json) =>
      _$AttentionResolutionFromJson(json);
}
