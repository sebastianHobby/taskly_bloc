import 'package:drift/drift.dart';
import 'package:taskly_bloc/data/drift/drift_database.dart' as drift_db;
import 'package:taskly_bloc/data/drift/features/attention_tables.drift.dart'
    as drift_attention;
import 'package:taskly_bloc/data/drift/features/shared_enums.dart'
    as drift_enums;
import 'package:taskly_bloc/domain/models/attention/attention_resolution.dart'
    as domain_resolution;
import 'package:taskly_bloc/domain/models/attention/attention_rule.dart'
    as domain_rule;

/// Converts between Drift database entities and domain models
class AttentionConverter {
  // ==========================================================================
  // AttentionRule Conversion
  // ==========================================================================

  /// Convert Drift entity to domain model
  static domain_rule.AttentionRule ruleToDomain(
    drift_db.AttentionRule data,
  ) {
    return domain_rule.AttentionRule(
      id: data.id,
      ruleKey: data.ruleKey,
      ruleType: _parseRuleType(data.ruleType),
      triggerType: _parseTriggerType(data.triggerType),
      triggerConfig: data.triggerConfig,
      entitySelector: data.entitySelector,
      severity: _parseSeverity(data.severity),
      displayConfig: data.displayConfig,
      resolutionActions: data.resolutionActions,
      active: data.active,
      source: _parseSource(data.source),
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    );
  }

  /// Convert domain model to Drift companion for insert/update
  static drift_db.AttentionRulesCompanion ruleToCompanion(
    domain_rule.AttentionRule rule, {
    bool forUpdate = false,
  }) {
    return drift_db.AttentionRulesCompanion(
      id: Value(rule.id),
      ruleKey: Value(rule.ruleKey),
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

  // ==========================================================================
  // AttentionResolution Conversion
  // ==========================================================================

  /// Convert Drift entity to domain model
  static domain_resolution.AttentionResolution resolutionToDomain(
    drift_db.AttentionResolution data,
  ) {
    return domain_resolution.AttentionResolution(
      id: data.id,
      ruleId: data.ruleId,
      entityId: data.entityId,
      entityType: _parseEntityType(data.entityType),
      resolvedAt: data.resolvedAt,
      resolutionAction: _parseResolutionAction(data.resolutionAction),
      actionDetails: data.actionDetails,
      createdAt: data.createdAt,
    );
  }

  /// Convert domain model to Drift companion for insert
  static drift_db.AttentionResolutionsCompanion resolutionToCompanion(
    domain_resolution.AttentionResolution resolution,
  ) {
    return drift_db.AttentionResolutionsCompanion.insert(
      id: Value(resolution.id),
      ruleId: resolution.ruleId,
      entityId: resolution.entityId,
      entityType: resolution.entityType.name,
      resolvedAt: Value(resolution.resolvedAt),
      resolutionAction: _mapResolutionAction(resolution.resolutionAction),
      actionDetails: Value(resolution.actionDetails),
      createdAt: Value(resolution.createdAt),
    );
  }

  // ==========================================================================
  // Private Parsers (Drift → Domain)
  // ==========================================================================

  /// Rule type: problem, review, workflowStep, allocationWarning
  static domain_rule.AttentionRuleType _parseRuleType(
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

  static domain_rule.AttentionTriggerType _parseTriggerType(
    drift_attention.AttentionTriggerType value,
  ) {
    switch (value) {
      case drift_attention.AttentionTriggerType.realtime:
        return domain_rule.AttentionTriggerType.realtime;
      case drift_attention.AttentionTriggerType.scheduled:
        return domain_rule.AttentionTriggerType.scheduled;
    }
  }

  /// Severity: info, warning, critical
  static domain_rule.AttentionSeverity _parseSeverity(
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

  /// Source: system_template, user_created, imported
  static domain_rule.AttentionEntitySource _parseSource(
    drift_enums.EntitySource value,
  ) {
    switch (value) {
      case drift_enums.EntitySource.system_template:
        return domain_rule.AttentionEntitySource.systemTemplate;
      case drift_enums.EntitySource.user_created:
        return domain_rule.AttentionEntitySource.userCreated;
      case drift_enums.EntitySource.imported:
        return domain_rule.AttentionEntitySource.imported;
    }
  }

  static domain_resolution.AttentionEntityType _parseEntityType(String value) {
    return domain_resolution.AttentionEntityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown entity type: $value'),
    );
  }

  /// Resolution action: reviewed, skipped, snoozed, dismissed
  static domain_resolution.AttentionResolutionAction _parseResolutionAction(
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

  // ==========================================================================
  // Private Mappers (Domain → Drift)
  // ==========================================================================

  static drift_attention.AttentionRuleType _mapRuleType(
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

  static drift_attention.AttentionTriggerType _mapTriggerType(
    domain_rule.AttentionTriggerType type,
  ) {
    switch (type) {
      case domain_rule.AttentionTriggerType.realtime:
        return drift_attention.AttentionTriggerType.realtime;
      case domain_rule.AttentionTriggerType.scheduled:
        return drift_attention.AttentionTriggerType.scheduled;
    }
  }

  static drift_attention.AttentionSeverity _mapSeverity(
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

  static drift_enums.EntitySource _mapSource(
    domain_rule.AttentionEntitySource source,
  ) {
    switch (source) {
      case domain_rule.AttentionEntitySource.systemTemplate:
        return drift_enums.EntitySource.system_template;
      case domain_rule.AttentionEntitySource.userCreated:
        return drift_enums.EntitySource.user_created;
      case domain_rule.AttentionEntitySource.imported:
        return drift_enums.EntitySource.imported;
    }
  }

  static drift_attention.AttentionResolutionAction _mapResolutionAction(
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
}
