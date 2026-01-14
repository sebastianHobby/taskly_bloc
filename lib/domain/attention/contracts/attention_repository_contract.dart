import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart';
import 'package:taskly_bloc/domain/attention/model/attention_rule_runtime_state.dart';

/// Repository contract for attention system data access.
///
/// IMPORTANT: No userId parameters - filtering is handled by Supabase RLS and
/// PowerSync buckets. The app should not rely on `user_id`.
abstract class AttentionRepositoryContract {
  // ===== Rules =====
  Stream<List<AttentionRule>> watchAllRules();
  Stream<List<AttentionRule>> watchActiveRules();
  Stream<List<AttentionRule>> watchRulesByBucket(AttentionBucket bucket);
  Stream<List<AttentionRule>> watchRulesByBuckets(
    List<AttentionBucket> buckets,
  );

  Future<AttentionRule?> getRuleById(String id);
  Future<AttentionRule?> getRuleByKey(String ruleKey);

  Future<void> upsertRule(AttentionRule rule);
  Future<void> updateRuleActive(String ruleId, bool active);
  Future<void> updateRuleEvaluatorParams(
    String ruleId,
    Map<String, dynamic> evaluatorParams,
  );
  Future<void> updateRuleSeverity(String ruleId, AttentionSeverity severity);
  Future<void> deleteRule(String ruleId);

  // ===== Resolutions (audit trail) =====
  Stream<List<AttentionResolution>> watchResolutionsForRule(String ruleId);
  Stream<List<AttentionResolution>> watchResolutionsForEntity(
    String entityId,
    AttentionEntityType entityType,
  );
  Future<AttentionResolution?> getLatestResolution(
    String ruleId,
    String entityId,
  );
  Future<void> recordResolution(AttentionResolution resolution);

  // ===== Runtime state (engine semantics) =====
  Stream<List<AttentionRuleRuntimeState>> watchRuntimeStateForRule(
    String ruleId,
  );

  Future<AttentionRuleRuntimeState?> getRuntimeState({
    required String ruleId,
    required AttentionEntityType? entityType,
    required String? entityId,
  });

  Future<void> upsertRuntimeState(AttentionRuleRuntimeState state);
}
