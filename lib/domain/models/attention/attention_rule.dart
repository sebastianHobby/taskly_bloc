import 'package:freezed_annotation/freezed_annotation.dart';

part 'attention_rule.freezed.dart';
part 'attention_rule.g.dart';

/// Rule type determines how the attention system categorizes rules
enum AttentionRuleType {
  @JsonValue('problem')
  problem, // Problem detection (overdue, stale, idle)

  @JsonValue('review')
  review, // Periodic reviews (from ReviewSettings)

  @JsonValue('workflowStep')
  workflowStep, // Workflow step completion tracking

  @JsonValue('allocationWarning')
  allocationWarning, // Allocation alerts (excluded tasks)
}

/// Trigger type determines when a rule activates
enum AttentionTriggerType {
  @JsonValue('realtime')
  realtime, // Evaluated continuously based on entity state

  @JsonValue('scheduled')
  scheduled, // Evaluated at specific times/intervals
}

/// Severity indicates urgency level
enum AttentionSeverity {
  @JsonValue('info')
  info, // FYI, no action needed (reviews)

  @JsonValue('warning')
  warning, // Should address soon

  @JsonValue('critical')
  critical, // Needs immediate attention
}

/// Entity source for tracking origin of rules (matches ScreenDefinition pattern)
enum AttentionEntitySource {
  @JsonValue('systemTemplate')
  systemTemplate, // Seeded system defaults

  @JsonValue('userCreated')
  userCreated, // User-created rules (out of scope v1)

  @JsonValue('imported')
  imported, // Imported from external source (future feature)
}

/// Domain model for attention rules
/// Uses freezed for immutability, equality, copyWith, and JSON serialization
@freezed
abstract class AttentionRule with _$AttentionRule {
  const factory AttentionRule({
    required String id,
    required String ruleKey,
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
