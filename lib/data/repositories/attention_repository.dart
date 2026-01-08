import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart';
import 'package:taskly_bloc/data/drift/features/attention_tables.drift.dart'
    as drift_attention;
import 'package:taskly_bloc/data/mappers/attention_converter.dart';
import 'package:taskly_bloc/domain/interfaces/attention_repository_contract.dart';
import 'package:taskly_bloc/domain/models/attention/attention_resolution.dart'
    as domain_resolution;
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart'
    as domain_rule;

/// Drift-based implementation of attention repository
///
/// IMPORTANT: No userId filtering needed - handled by Supabase RLS + PowerSync
class AttentionRepository implements AttentionRepositoryContract {
  AttentionRepository({required AppDatabase db}) : _db = db;
  final AppDatabase _db;

  // ==========================================================================
  // Rules
  // ==========================================================================

  @override
  Stream<List<domain_rule.AttentionRule>> watchAllRules() {
    return _db
        .select(_db.attentionRules)
        .watch()
        .map(
          (rows) => rows
              .map<domain_rule.AttentionRule>(AttentionConverter.ruleToDomain)
              .toList(),
        );
  }

  @override
  Stream<List<domain_rule.AttentionRule>> watchActiveRules() {
    return (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.active.equals(true))).watch().map(
      (rows) => rows
          .map<domain_rule.AttentionRule>(AttentionConverter.ruleToDomain)
          .toList(),
    );
  }

  @override
  Stream<List<domain_rule.AttentionRule>> watchRulesByType(
    domain_rule.AttentionRuleType type,
  ) {
    final driftType = _mapRuleType(type);
    return (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.ruleType.equalsValue(driftType))).watch().map(
      (rows) => rows
          .map<domain_rule.AttentionRule>(AttentionConverter.ruleToDomain)
          .toList(),
    );
  }

  @override
  Stream<List<domain_rule.AttentionRule>> watchRulesByTypes(
    List<domain_rule.AttentionRuleType> types,
  ) {
    final driftTypes = types.map(_mapRuleType).toList();
    return (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.ruleType.isInValues(driftTypes))).watch().map(
      (rows) => rows
          .map<domain_rule.AttentionRule>(AttentionConverter.ruleToDomain)
          .toList(),
    );
  }

  @override
  Future<domain_rule.AttentionRule?> getRuleById(String id) async {
    final row = await (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    return row != null ? AttentionConverter.ruleToDomain(row) : null;
  }

  @override
  Future<domain_rule.AttentionRule?> getRuleByKey(String ruleKey) async {
    final row = await (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.ruleKey.equals(ruleKey))).getSingleOrNull();

    return row != null ? AttentionConverter.ruleToDomain(row) : null;
  }

  @override
  Future<void> upsertRule(domain_rule.AttentionRule rule) async {
    try {
      await _db
          .into(_db.attentionRules)
          .insertOnConflictUpdate(
            AttentionConverter.ruleToCompanion(rule),
          );

      talker.repositoryLog('Attention', 'Upserted rule: ${rule.ruleKey}');
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[Attention] Failed to upsert rule: ${rule.ruleKey}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateRuleActive(String ruleId, bool active) async {
    try {
      await (_db.update(
        _db.attentionRules,
      )..where((tbl) => tbl.id.equals(ruleId))).write(
        AttentionRulesCompanion(
          active: Value(active),
          updatedAt: Value(DateTime.now()),
        ),
      );

      talker.repositoryLog(
        'Attention',
        'Updated rule $ruleId active status: $active',
      );
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[Attention] Failed to update rule active status',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateRuleTriggerConfig(
    String ruleId,
    Map<String, dynamic> triggerConfig,
  ) async {
    try {
      await (_db.update(
        _db.attentionRules,
      )..where((tbl) => tbl.id.equals(ruleId))).write(
        AttentionRulesCompanion(
          triggerConfig: Value(triggerConfig),
          updatedAt: Value(DateTime.now()),
        ),
      );

      talker.repositoryLog('Attention', 'Updated rule $ruleId trigger config');
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[Attention] Failed to update trigger config',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateRuleSeverity(
    String ruleId,
    domain_rule.AttentionSeverity severity,
  ) async {
    try {
      // Note: Caller should validate this is a problem rule (reviews always info)
      await (_db.update(
        _db.attentionRules,
      )..where((tbl) => tbl.id.equals(ruleId))).write(
        AttentionRulesCompanion(
          severity: Value(_mapSeverity(severity)),
          updatedAt: Value(DateTime.now()),
        ),
      );

      talker.repositoryLog(
        'Attention',
        'Updated rule $ruleId severity: ${severity.name}',
      );
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[Attention] Failed to update severity',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteRule(String ruleId) async {
    try {
      // Check if system template (cannot delete)
      final rule = await getRuleById(ruleId);
      if (rule?.source == domain_rule.AttentionEntitySource.systemTemplate) {
        throw Exception('Cannot delete system template rules');
      }

      await (_db.delete(
        _db.attentionRules,
      )..where((tbl) => tbl.id.equals(ruleId))).go();

      talker.repositoryLog('Attention', 'Deleted rule: $ruleId');
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[Attention] Failed to delete rule',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  // ==========================================================================
  // Resolutions
  // ==========================================================================

  @override
  Stream<List<domain_resolution.AttentionResolution>> watchResolutionsForRule(
    String ruleId,
  ) {
    return (_db.select(_db.attentionResolutions)
          ..where((tbl) => tbl.ruleId.equals(ruleId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.resolvedAt)]))
        .watch()
        .map(
          (rows) => rows
              .map<domain_resolution.AttentionResolution>(
                AttentionConverter.resolutionToDomain,
              )
              .toList(),
        );
  }

  @override
  Stream<List<domain_resolution.AttentionResolution>> watchResolutionsForEntity(
    String entityId,
    domain_resolution.AttentionEntityType entityType,
  ) {
    return (_db.select(_db.attentionResolutions)
          ..where(
            (tbl) =>
                tbl.entityId.equals(entityId) &
                tbl.entityType.equals(entityType.name),
          )
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.resolvedAt)]))
        .watch()
        .map(
          (rows) => rows
              .map<domain_resolution.AttentionResolution>(
                AttentionConverter.resolutionToDomain,
              )
              .toList(),
        );
  }

  @override
  Future<domain_resolution.AttentionResolution?> getLatestResolution(
    String ruleId,
    String entityId,
  ) async {
    final row =
        await (_db.select(_db.attentionResolutions)
              ..where(
                (tbl) =>
                    tbl.ruleId.equals(ruleId) & tbl.entityId.equals(entityId),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.resolvedAt)])
              ..limit(1))
            .getSingleOrNull();

    return row != null ? AttentionConverter.resolutionToDomain(row) : null;
  }

  @override
  Future<void> recordResolution(
    domain_resolution.AttentionResolution resolution,
  ) async {
    try {
      await _db
          .into(_db.attentionResolutions)
          .insert(
            AttentionConverter.resolutionToCompanion(resolution),
          );

      talker.repositoryLog(
        'Attention',
        'Recorded resolution: ${resolution.id}',
      );
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[Attention] Failed to record resolution',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<bool> wasRecentlyResolved(
    String ruleId,
    String entityId, {
    Duration within = const Duration(hours: 24),
  }) async {
    final cutoff = DateTime.now().subtract(within);

    final count =
        await (_db.selectOnly(_db.attentionResolutions)
              ..addColumns([_db.attentionResolutions.id])
              ..where(
                _db.attentionResolutions.ruleId.equals(ruleId) &
                    _db.attentionResolutions.entityId.equals(entityId) &
                    _db.attentionResolutions.resolvedAt.isBiggerOrEqualValue(
                      cutoff,
                    ),
              )
              ..limit(1))
            .getSingleOrNull();

    return count != null;
  }

  @override
  Future<bool> wasDismissed(
    String ruleId,
    String entityId,
    String? currentStateHash,
  ) async {
    // Get the latest resolution for this rule + entity
    final resolution = await getLatestResolution(ruleId, entityId);

    if (resolution == null) return false;
    if (resolution.resolutionAction !=
        domain_resolution.AttentionResolutionAction.dismissed) {
      return false;
    }

    // If state hash matches, still dismissed
    // If state hash changed, entity changed - should resurface
    final storedHash = resolution.actionDetails?['state_hash'] as String?;
    return storedHash == currentStateHash;
  }

  // ==========================================================================
  // Private Mappers
  // ==========================================================================

  drift_attention.AttentionRuleType _mapRuleType(
    domain_rule.AttentionRuleType type,
  ) {
    switch (type) {
      case domain_rule.AttentionRuleType.problem:
        return drift_attention.AttentionRuleType.problem;
      case domain_rule.AttentionRuleType.review:
        return drift_attention.AttentionRuleType.review;
      case domain_rule.AttentionRuleType.workflowStep:
        return drift_attention.AttentionRuleType.workflowStep;
      case domain_rule.AttentionRuleType.allocationWarning:
        return drift_attention.AttentionRuleType.allocationWarning;
    }
  }

  drift_attention.AttentionSeverity _mapSeverity(
    domain_rule.AttentionSeverity severity,
  ) {
    switch (severity) {
      case domain_rule.AttentionSeverity.info:
        return drift_attention.AttentionSeverity.info;
      case domain_rule.AttentionSeverity.warning:
        return drift_attention.AttentionSeverity.warning;
      case domain_rule.AttentionSeverity.critical:
        return drift_attention.AttentionSeverity.critical;
    }
  }
}
