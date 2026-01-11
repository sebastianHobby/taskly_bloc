import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/drift/features/attention_tables.drift.dart'
    as drift_attention;
import 'package:taskly_bloc/data/drift/features/shared_enums.dart';
import 'package:taskly_bloc/data/id/id_generator.dart';
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart'
    as domain;
import 'package:taskly_bloc/domain/models/attention/system_attention_rules.dart';

/// Seeds system attention rules to database
///
/// Pattern matches screen seeding:
/// - Uses deterministic UUID v5 for idempotent seeding
/// - insertOrIgnore for safe re-runs
/// - Reads templates, writes to database
class AttentionSeeder {
  AttentionSeeder({
    required AppDatabase db,
    required IdGenerator idGenerator,
  }) : _db = db,
       _idGenerator = idGenerator;
  final AppDatabase _db;
  final IdGenerator _idGenerator;

  /// Seed all system attention rules
  ///
  /// IMPORTANT: This writes to database ONCE on first launch
  /// After that, users customize via database - templates are not consulted
  ///
  /// Uses deterministic IDs so re-running is safe (no duplicates)
  Future<void> seedSystemRules() async {
    talker.info('[AttentionSeeder] Seeding system attention rules');

    try {
      await _db.transaction(() async {
        for (final template in SystemAttentionRules.all) {
          await _seedRule(template);
        }
      });

      talker.info(
        '[AttentionSeeder] Successfully seeded '
        '${SystemAttentionRules.all.length} rules',
      );
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[AttentionSeeder] Failed to seed attention rules',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  Future<void> _seedRule(AttentionRuleTemplate template) async {
    // Deterministic ID: namespace='attention_rules', name=ruleKey
    // Same rule key always generates same ID
    final id = _idGenerator.attentionRuleId(ruleKey: template.ruleKey);

    await _db
        .into(_db.attentionRules)
        .insert(
          AttentionRulesCompanion.insert(
            id: Value(id),
            ruleKey: template.ruleKey,
            domain: template.domain,
            category: template.category,
            ruleType: _mapRuleType(template.ruleType),
            triggerType: _mapTriggerType(template.triggerType),
            triggerConfig: template.triggerConfig,
            entitySelector: template.entitySelector,
            severity: _mapSeverity(template.severity),
            displayConfig: template.displayConfig,
            resolutionActions: template.resolutionActions,
            source: const Value(EntitySource.system_template),
          ),
          mode: InsertMode.insertOrIgnore, // Skip if already exists
        );
  }

  /// Check if user has any rules (determines if seeding needed)
  Future<bool> hasInitializedRules() async {
    final count = await _db.attentionRules.count().getSingle();
    return count > 0;
  }

  /// Idempotent initialization - safe to call multiple times
  Future<void> ensureSeeded() async {
    await _migrateLegacyRuleTypeValues();

    // Always attempt seeding: deterministic IDs + insertOrIgnore means this
    // will only insert missing templates and will not overwrite user edits.
    await seedSystemRules();
  }

  Future<void> _migrateLegacyRuleTypeValues() async {
    // Legacy versions stored enum names as snake_case.
    // Supabase enum values are camelCase (workflowStep, allocationWarning).
    // Normalize locally so PowerSync uploads don't fail.
    try {
      await _db.customStatement(
        "UPDATE attention_rules SET rule_type='workflowStep' WHERE rule_type='workflow_step'",
      );
      await _db.customStatement(
        "UPDATE attention_rules SET rule_type='allocationWarning' WHERE rule_type='allocation_warning'",
      );
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[AttentionSeeder] Failed to migrate legacy rule_type values',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // Map domain enum to Drift enum
  drift_attention.AttentionRuleType _mapRuleType(
    domain.AttentionRuleType type,
  ) {
    switch (type) {
      case domain.AttentionRuleType.problem:
        return drift_attention.AttentionRuleType.problem;
      case domain.AttentionRuleType.review:
        return drift_attention.AttentionRuleType.review;
      case domain.AttentionRuleType.workflowStep:
        return drift_attention.AttentionRuleType.workflowStep;
      case domain.AttentionRuleType.allocationWarning:
        return drift_attention.AttentionRuleType.allocationWarning;
    }
  }

  drift_attention.AttentionTriggerType _mapTriggerType(
    domain.AttentionTriggerType type,
  ) {
    switch (type) {
      case domain.AttentionTriggerType.realtime:
        return drift_attention.AttentionTriggerType.realtime;
      case domain.AttentionTriggerType.scheduled:
        return drift_attention.AttentionTriggerType.scheduled;
    }
  }

  drift_attention.AttentionSeverity _mapSeverity(
    domain.AttentionSeverity severity,
  ) {
    switch (severity) {
      case domain.AttentionSeverity.info:
        return drift_attention.AttentionSeverity.info;
      case domain.AttentionSeverity.warning:
        return drift_attention.AttentionSeverity.warning;
      case domain.AttentionSeverity.critical:
        return drift_attention.AttentionSeverity.critical;
    }
  }
}
