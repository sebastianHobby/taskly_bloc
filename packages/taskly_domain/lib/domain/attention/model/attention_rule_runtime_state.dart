import 'package:freezed_annotation/freezed_annotation.dart';
import 'attention_resolution.dart';

part 'attention_rule_runtime_state.freezed.dart';
part 'attention_rule_runtime_state.g.dart';

/// Engine-owned runtime state for a rule (optionally scoped to an entity).
@freezed
abstract class AttentionRuleRuntimeState with _$AttentionRuleRuntimeState {
  const factory AttentionRuleRuntimeState({
    required String id,
    required String ruleId,
    required DateTime createdAt,
    required DateTime updatedAt,
    AttentionEntityType? entityType,
    String? entityId,

    String? stateHash,
    String? dismissedStateHash,
    DateTime? lastEvaluatedAt,
    DateTime? nextEvaluateAfter,

    @Default(<String, dynamic>{}) Map<String, dynamic> metadata,
  }) = _AttentionRuleRuntimeState;

  factory AttentionRuleRuntimeState.fromJson(Map<String, dynamic> json) =>
      _$AttentionRuleRuntimeStateFromJson(json);
}
