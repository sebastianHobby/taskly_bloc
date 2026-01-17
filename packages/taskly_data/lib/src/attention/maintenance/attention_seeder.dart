import 'package:drift/drift.dart';
import 'package:taskly_core/logging.dart';
import 'package:taskly_data/src/infrastructure/drift/drift_database.dart';
import 'package:taskly_data/src/infrastructure/drift/features/attention_tables.drift.dart'
    as drift_attention;
import 'package:taskly_data/src/infrastructure/drift/features/shared_enums.dart';
import 'package:taskly_data/src/id/id_generator.dart';
import 'package:taskly_domain/attention.dart';
import 'package:taskly_domain/attention.dart' as domain;

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
            bucket: _mapBucket(template.bucket),
            evaluator: template.evaluator,
            evaluatorParams: template.evaluatorParams,
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
    // Always attempt seeding: deterministic IDs + insertOrIgnore means this
    // will only insert missing templates and will not overwrite user edits.
    await seedSystemRules();
  }

  drift_attention.AttentionBucket _mapBucket(domain.AttentionBucket bucket) {
    switch (bucket) {
      case domain.AttentionBucket.action:
        return drift_attention.AttentionBucket.action;
      case domain.AttentionBucket.review:
        return drift_attention.AttentionBucket.review;
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
