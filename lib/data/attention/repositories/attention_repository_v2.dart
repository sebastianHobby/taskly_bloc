import 'package:drift/drift.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';
import 'package:taskly_bloc/data/infrastructure/drift/drift_database.dart';
import 'package:taskly_bloc/data/infrastructure/drift/features/attention_tables.drift.dart'
    as drift_attention;
import 'package:taskly_bloc/data/infrastructure/drift/features/shared_enums.dart'
    as drift_shared;
import 'package:taskly_bloc/domain/attention/contracts/attention_repository_contract.dart';
import 'package:taskly_bloc/domain/attention/model/attention_resolution.dart'
    as domain_resolution;
import 'package:taskly_bloc/domain/attention/model/attention_rule.dart'
    as domain_rule;
import 'package:taskly_bloc/domain/attention/model/attention_rule_runtime_state.dart'
    as domain_runtime;

/// Drift-based repository for the new attention bounded context.
///
/// This is not wired into the UI yet (Phase 05 cutover).
class AttentionRepositoryV2 implements AttentionRepositoryContract {
  AttentionRepositoryV2({required AppDatabase db}) : _db = db;

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
          (rows) => rows.map(_ruleToDomain).toList(growable: false),
        );
  }

  @override
  Stream<List<domain_rule.AttentionRule>> watchActiveRules() {
    return (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.active.equals(true))).watch().map(
      (rows) => rows.map(_ruleToDomain).toList(growable: false),
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
      (rows) => rows.map(_ruleToDomain).toList(growable: false),
    );
  }

  @override
  Stream<List<domain_rule.AttentionRule>> watchRulesByTypes(
    List<domain_rule.AttentionRuleType> types,
  ) {
    final driftTypes = types.map(_mapRuleType).toList(growable: false);
    return (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.ruleType.isInValues(driftTypes))).watch().map(
      (rows) => rows.map(_ruleToDomain).toList(growable: false),
    );
  }

  @override
  Future<domain_rule.AttentionRule?> getRuleById(String id) async {
    final row = await (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();

    return row != null ? _ruleToDomain(row) : null;
  }

  @override
  Future<domain_rule.AttentionRule?> getRuleByKey(String ruleKey) async {
    final row = await (_db.select(
      _db.attentionRules,
    )..where((tbl) => tbl.ruleKey.equals(ruleKey))).getSingleOrNull();

    return row != null ? _ruleToDomain(row) : null;
  }

  @override
  Future<void> upsertRule(domain_rule.AttentionRule rule) async {
    try {
      await _db
          .into(_db.attentionRules)
          .insertOnConflictUpdate(
            _ruleToCompanion(rule, forUpdate: true),
          );
      talker.repositoryLog('AttentionV2', 'Upserted rule: ${rule.id}');
    } catch (e, stackTrace) {
      talker.operationFailed(
        '[AttentionV2] Failed to upsert rule',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<void> updateRuleActive(String ruleId, bool active) async {
    await (_db.update(_db.attentionRules)..where((t) => t.id.equals(ruleId)))
        .write(AttentionRulesCompanion(active: Value(active)));
  }

  @override
  Future<void> updateRuleTriggerConfig(
    String ruleId,
    Map<String, dynamic> triggerConfig,
  ) async {
    await (_db.update(_db.attentionRules)..where((t) => t.id.equals(ruleId)))
        .write(AttentionRulesCompanion(triggerConfig: Value(triggerConfig)));
  }

  @override
  Future<void> updateRuleSeverity(
    String ruleId,
    domain_rule.AttentionSeverity severity,
  ) async {
    await (_db.update(
      _db.attentionRules,
    )..where((t) => t.id.equals(ruleId))).write(
      AttentionRulesCompanion(severity: Value(_mapSeverity(severity))),
    );
  }

  @override
  Future<void> deleteRule(String ruleId) async {
    await (_db.delete(
      _db.attentionRules,
    )..where((t) => t.id.equals(ruleId))).go();
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
          (rows) => rows.map(_resolutionToDomain).toList(growable: false),
        );
  }

  @override
  Stream<List<domain_resolution.AttentionResolution>> watchResolutionsForEntity(
    String entityId,
    domain_resolution.AttentionEntityType entityType,
  ) {
    final entityTypeValue = _entityTypeToStorage(entityType);
    return (_db.select(_db.attentionResolutions)
          ..where((tbl) => tbl.entityId.equals(entityId))
          ..where((tbl) => tbl.entityType.equals(entityTypeValue))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.resolvedAt)]))
        .watch()
        .map(
          (rows) => rows.map(_resolutionToDomain).toList(growable: false),
        );
  }

  @override
  Future<domain_resolution.AttentionResolution?> getLatestResolution(
    String ruleId,
    String entityId,
  ) async {
    final row =
        await (_db.select(_db.attentionResolutions)
              ..where((tbl) => tbl.ruleId.equals(ruleId))
              ..where((tbl) => tbl.entityId.equals(entityId))
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.resolvedAt)])
              ..limit(1))
            .getSingleOrNull();

    return row != null ? _resolutionToDomain(row) : null;
  }

  @override
  Future<void> recordResolution(
    domain_resolution.AttentionResolution resolution,
  ) async {
    await _db
        .into(_db.attentionResolutions)
        .insert(
          _resolutionToCompanion(resolution),
          mode: InsertMode.insertOrReplace,
        );
  }

  // ==========================================================================
  // Runtime state
  // ==========================================================================

  @override
  Stream<List<domain_runtime.AttentionRuleRuntimeState>>
  watchRuntimeStateForRule(
    String ruleId,
  ) {
    return (_db.select(_db.attentionRuleRuntimeStates)
          ..where((tbl) => tbl.ruleId.equals(ruleId))
          ..orderBy([(tbl) => OrderingTerm.desc(tbl.updatedAt)]))
        .watch()
        .map(
          (rows) => rows.map(_runtimeStateToDomain).toList(growable: false),
        );
  }

  @override
  Future<domain_runtime.AttentionRuleRuntimeState?> getRuntimeState({
    required String ruleId,
    required domain_resolution.AttentionEntityType? entityType,
    required String? entityId,
  }) async {
    _validateEntityPair(entityType: entityType, entityId: entityId);

    final query = _db.select(_db.attentionRuleRuntimeStates)
      ..where((tbl) => tbl.ruleId.equals(ruleId));

    if (entityType == null) {
      query
        ..where((tbl) => tbl.entityType.isNull())
        ..where((tbl) => tbl.entityId.isNull());
    } else {
      query
        ..where(
          (tbl) => tbl.entityType.equals(_entityTypeToStorage(entityType)),
        )
        ..where((tbl) => tbl.entityId.equals(entityId!));
    }

    final row = await query.getSingleOrNull();
    return row != null ? _runtimeStateToDomain(row) : null;
  }

  @override
  Future<void> upsertRuntimeState(
    domain_runtime.AttentionRuleRuntimeState state,
  ) async {
    _validateEntityPair(entityType: state.entityType, entityId: state.entityId);

    await _db
        .into(_db.attentionRuleRuntimeStates)
        .insertOnConflictUpdate(
          _runtimeStateToCompanion(state, forUpdate: true),
        );
  }

  // ==========================================================================
  // Mappers
  // ==========================================================================

  domain_rule.AttentionRule _ruleToDomain(AttentionRule row) {
    return domain_rule.AttentionRule(
      id: row.id,
      ruleKey: row.ruleKey,
      domain: row.domain,
      category: row.category,
      ruleType: _parseRuleType(row.ruleType),
      triggerType: _parseTriggerType(row.triggerType),
      triggerConfig: row.triggerConfig,
      entitySelector: row.entitySelector,
      severity: _parseSeverity(row.severity),
      displayConfig: row.displayConfig,
      resolutionActions: row.resolutionActions,
      active: row.active,
      source: _parseSource(row.source),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  AttentionRulesCompanion _ruleToCompanion(
    domain_rule.AttentionRule rule, {
    required bool forUpdate,
  }) {
    return AttentionRulesCompanion(
      id: Value(rule.id),
      ruleKey: Value(rule.ruleKey),
      domain: Value(rule.domain),
      category: Value(rule.category),
      ruleType: Value(_mapRuleType(rule.ruleType)),
      triggerType: Value(_mapTriggerType(rule.triggerType)),
      triggerConfig: Value(rule.triggerConfig),
      entitySelector: Value(rule.entitySelector),
      severity: Value(_mapSeverity(rule.severity)),
      displayConfig: Value(rule.displayConfig),
      resolutionActions: Value(rule.resolutionActions),
      active: Value(rule.active),
      source: Value(_mapSource(rule.source)),
      createdAt: forUpdate ? const Value.absent() : Value(rule.createdAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  domain_resolution.AttentionResolution _resolutionToDomain(
    AttentionResolution row,
  ) {
    return domain_resolution.AttentionResolution(
      id: row.id,
      ruleId: row.ruleId,
      entityId: row.entityId,
      entityType: _parseEntityType(row.entityType),
      resolvedAt: row.resolvedAt,
      resolutionAction: _parseResolutionAction(row.resolutionAction),
      actionDetails: row.actionDetails,
      createdAt: row.createdAt,
    );
  }

  AttentionResolutionsCompanion _resolutionToCompanion(
    domain_resolution.AttentionResolution resolution,
  ) {
    return AttentionResolutionsCompanion.insert(
      id: Value(resolution.id),
      ruleId: resolution.ruleId,
      entityId: resolution.entityId,
      entityType: _entityTypeToStorage(resolution.entityType),
      resolvedAt: Value(resolution.resolvedAt),
      resolutionAction: _mapResolutionAction(resolution.resolutionAction),
      actionDetails: Value(resolution.actionDetails),
      createdAt: Value(resolution.createdAt),
    );
  }

  domain_runtime.AttentionRuleRuntimeState _runtimeStateToDomain(
    AttentionRuleRuntimeState row,
  ) {
    return domain_runtime.AttentionRuleRuntimeState(
      id: row.id,
      ruleId: row.ruleId,
      entityType: row.entityType != null
          ? _parseEntityType(row.entityType!)
          : null,
      entityId: row.entityId,
      stateHash: row.stateHash,
      dismissedStateHash: row.dismissedStateHash,
      lastEvaluatedAt: row.lastEvaluatedAt,
      nextEvaluateAfter: row.nextEvaluateAfter,
      metadata: row.metadata,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  AttentionRuleRuntimeStatesCompanion _runtimeStateToCompanion(
    domain_runtime.AttentionRuleRuntimeState state, {
    required bool forUpdate,
  }) {
    return AttentionRuleRuntimeStatesCompanion(
      id: Value(state.id),
      ruleId: Value(state.ruleId),
      entityType: Value(
        state.entityType != null
            ? _entityTypeToStorage(state.entityType!)
            : null,
      ),
      entityId: Value(state.entityId),
      stateHash: Value(state.stateHash),
      dismissedStateHash: Value(state.dismissedStateHash),
      lastEvaluatedAt: Value(state.lastEvaluatedAt),
      nextEvaluateAfter: Value(state.nextEvaluateAfter),
      metadata: Value(state.metadata),
      createdAt: forUpdate ? const Value.absent() : Value(state.createdAt),
      updatedAt: Value(DateTime.now()),
    );
  }

  // ==========================================================================
  // Enum + value mapping helpers
  // ==========================================================================

  domain_rule.AttentionRuleType _parseRuleType(
    drift_attention.AttentionRuleType value,
  ) {
    switch (value) {
      case drift_attention.AttentionRuleType.problem:
        return domain_rule.AttentionRuleType.problem;
      case drift_attention.AttentionRuleType.review:
        return domain_rule.AttentionRuleType.review;
      case drift_attention.AttentionRuleType.workflowStep:
        return domain_rule.AttentionRuleType.workflowStep;
      case drift_attention.AttentionRuleType.allocationWarning:
        return domain_rule.AttentionRuleType.allocationWarning;
    }
  }

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

  domain_rule.AttentionTriggerType _parseTriggerType(
    drift_attention.AttentionTriggerType value,
  ) {
    switch (value) {
      case drift_attention.AttentionTriggerType.realtime:
        return domain_rule.AttentionTriggerType.realtime;
      case drift_attention.AttentionTriggerType.scheduled:
        return domain_rule.AttentionTriggerType.scheduled;
    }
  }

  drift_attention.AttentionTriggerType _mapTriggerType(
    domain_rule.AttentionTriggerType type,
  ) {
    switch (type) {
      case domain_rule.AttentionTriggerType.realtime:
        return drift_attention.AttentionTriggerType.realtime;
      case domain_rule.AttentionTriggerType.scheduled:
        return drift_attention.AttentionTriggerType.scheduled;
    }
  }

  domain_rule.AttentionSeverity _parseSeverity(
    drift_attention.AttentionSeverity value,
  ) {
    switch (value) {
      case drift_attention.AttentionSeverity.info:
        return domain_rule.AttentionSeverity.info;
      case drift_attention.AttentionSeverity.warning:
        return domain_rule.AttentionSeverity.warning;
      case drift_attention.AttentionSeverity.critical:
        return domain_rule.AttentionSeverity.critical;
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

  domain_rule.AttentionEntitySource _parseSource(
    drift_shared.EntitySource value,
  ) {
    switch (value) {
      case drift_shared.EntitySource.system_template:
        return domain_rule.AttentionEntitySource.systemTemplate;
      case drift_shared.EntitySource.user_created:
        return domain_rule.AttentionEntitySource.userCreated;
      case drift_shared.EntitySource.imported:
        return domain_rule.AttentionEntitySource.imported;
    }
  }

  drift_shared.EntitySource _mapSource(
    domain_rule.AttentionEntitySource source,
  ) {
    switch (source) {
      case domain_rule.AttentionEntitySource.systemTemplate:
        return drift_shared.EntitySource.system_template;
      case domain_rule.AttentionEntitySource.userCreated:
        return drift_shared.EntitySource.user_created;
      case domain_rule.AttentionEntitySource.imported:
        return drift_shared.EntitySource.imported;
    }
  }

  domain_resolution.AttentionEntityType _parseEntityType(String value) {
    return switch (value) {
      'task' => domain_resolution.AttentionEntityType.task,
      'project' => domain_resolution.AttentionEntityType.project,
      'journal' => domain_resolution.AttentionEntityType.journal,
      'value' => domain_resolution.AttentionEntityType.value,
      'tracker' => domain_resolution.AttentionEntityType.tracker,
      'review_session' ||
      'reviewSession' => domain_resolution.AttentionEntityType.reviewSession,
      _ => throw ArgumentError('Unknown entity type: $value'),
    };
  }

  String _entityTypeToStorage(
    domain_resolution.AttentionEntityType entityType,
  ) {
    return switch (entityType) {
      domain_resolution.AttentionEntityType.task => 'task',
      domain_resolution.AttentionEntityType.project => 'project',
      domain_resolution.AttentionEntityType.journal => 'journal',
      domain_resolution.AttentionEntityType.value => 'value',
      domain_resolution.AttentionEntityType.tracker => 'tracker',
      domain_resolution.AttentionEntityType.reviewSession => 'review_session',
    };
  }

  domain_resolution.AttentionResolutionAction _parseResolutionAction(
    drift_attention.AttentionResolutionAction value,
  ) {
    switch (value) {
      case drift_attention.AttentionResolutionAction.reviewed:
        return domain_resolution.AttentionResolutionAction.reviewed;
      case drift_attention.AttentionResolutionAction.skipped:
        return domain_resolution.AttentionResolutionAction.skipped;
      case drift_attention.AttentionResolutionAction.snoozed:
        return domain_resolution.AttentionResolutionAction.snoozed;
      case drift_attention.AttentionResolutionAction.dismissed:
        return domain_resolution.AttentionResolutionAction.dismissed;
    }
  }

  drift_attention.AttentionResolutionAction _mapResolutionAction(
    domain_resolution.AttentionResolutionAction action,
  ) {
    switch (action) {
      case domain_resolution.AttentionResolutionAction.reviewed:
        return drift_attention.AttentionResolutionAction.reviewed;
      case domain_resolution.AttentionResolutionAction.skipped:
        return drift_attention.AttentionResolutionAction.skipped;
      case domain_resolution.AttentionResolutionAction.snoozed:
        return drift_attention.AttentionResolutionAction.snoozed;
      case domain_resolution.AttentionResolutionAction.dismissed:
        return drift_attention.AttentionResolutionAction.dismissed;
    }
  }

  void _validateEntityPair({
    required domain_resolution.AttentionEntityType? entityType,
    required String? entityId,
  }) {
    final hasType = entityType != null;
    final hasId = entityId != null;
    if (hasType != hasId) {
      throw ArgumentError(
        'entityType and entityId must be both null or both non-null.',
      );
    }
  }
}
