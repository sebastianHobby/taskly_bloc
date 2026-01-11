import 'package:freezed_annotation/freezed_annotation.dart';

part 'attention_rule.freezed.dart';
part 'attention_rule.g.dart';

/// Rule type determines how the attention system categorizes rules.
enum AttentionRuleType {
  @JsonValue('problem')
  problem,

  @JsonValue('review')
  review,

  @JsonValue('allocationWarning')
  allocationWarning,
}

/// Trigger type determines when a rule activates.
enum AttentionTriggerType {
  @JsonValue('realtime')
  realtime,

  @JsonValue('scheduled')
  scheduled,
}

/// Severity indicates urgency level.
enum AttentionSeverity {
  @JsonValue('info')
  info,

  @JsonValue('warning')
  warning,

  @JsonValue('critical')
  critical,
}

/// Entity source for tracking origin of rules.
enum AttentionEntitySource {
  @JsonValue('systemTemplate')
  systemTemplate,

  @JsonValue('userCreated')
  userCreated,

  @JsonValue('imported')
  imported,
}

/// Domain model for attention rules.
@freezed
abstract class AttentionRule with _$AttentionRule {
  const factory AttentionRule({
    required String id,
    required String ruleKey,

    /// Stable grouping axes (persisted).
    required String domain,
    required String category,

    required AttentionRuleType ruleType,
    required AttentionTriggerType triggerType,
    required Map<String, dynamic> triggerConfig,
    required Map<String, dynamic> entitySelector,
    required AttentionSeverity severity,
    required Map<String, dynamic> displayConfig,
    required List<String> resolutionActions,
    required bool active,
    required AttentionEntitySource source,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _AttentionRule;

  factory AttentionRule.fromJson(Map<String, dynamic> json) =>
      _$AttentionRuleFromJson(json);
}
