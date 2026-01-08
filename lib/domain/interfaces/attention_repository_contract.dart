import 'package:taskly_bloc/domain/models/attention/attention_resolution.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart';

/// Repository contract for attention system data access
///
/// IMPORTANT: No userId parameters - filtering handled by Supabase RLS
abstract class AttentionRepositoryContract {
  // ===== Rules =====

  /// Watch all attention rules (automatically filtered by authenticated user)
  Stream<List<AttentionRule>> watchAllRules();

  /// Watch active rules only
  Stream<List<AttentionRule>> watchActiveRules();

  /// Watch rules by type (problem, review, allocationWarning)
  Stream<List<AttentionRule>> watchRulesByType(AttentionRuleType type);

  /// Watch rules by multiple types
  Stream<List<AttentionRule>> watchRulesByTypes(List<AttentionRuleType> types);

  /// Get rule by ID
  Future<AttentionRule?> getRuleById(String id);

  /// Get rule by key (for deterministic lookups)
  Future<AttentionRule?> getRuleByKey(String ruleKey);

  /// Create or update rule
  Future<void> upsertRule(AttentionRule rule);

  /// Update rule active status
  Future<void> updateRuleActive(String ruleId, bool active);

  /// Update rule trigger config (frequency, thresholds)
  Future<void> updateRuleTriggerConfig(
    String ruleId,
    Map<String, dynamic> triggerConfig,
  );

  /// Update rule severity (only for problem rules - reviews always info)
  Future<void> updateRuleSeverity(String ruleId, AttentionSeverity severity);

  /// Delete rule (only user-created rules)
  Future<void> deleteRule(String ruleId);

  // ===== Resolutions =====

  /// Watch resolutions for a specific rule
  Stream<List<AttentionResolution>> watchResolutionsForRule(String ruleId);

  /// Watch resolutions for an entity
  Stream<List<AttentionResolution>> watchResolutionsForEntity(
    String entityId,
    AttentionEntityType entityType,
  );

  /// Get latest resolution for rule + entity combination
  Future<AttentionResolution?> getLatestResolution(
    String ruleId,
    String entityId,
  );

  /// Record resolution (resolved, snoozed, dismissed)
  Future<void> recordResolution(AttentionResolution resolution);

  /// Check if entity was recently resolved for a rule
  Future<bool> wasRecentlyResolved(
    String ruleId,
    String entityId, {
    Duration within = const Duration(hours: 24),
  });

  /// Check if entity was dismissed (for state-hash based reset)
  Future<bool> wasDismissed(
    String ruleId,
    String entityId,
    String? currentStateHash,
  );
}
