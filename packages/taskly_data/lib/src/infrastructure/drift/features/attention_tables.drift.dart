import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_data/src/infrastructure/drift/converters/json_converters.dart';
import 'package:taskly_data/src/infrastructure/drift/features/shared_enums.dart';

/// Attention bucket taxonomy (Action vs Review).
enum AttentionBucket { action, review }

/// Attention severity levels
enum AttentionSeverity { critical, warning, info }

/// Resolution actions for attention items
enum AttentionResolutionAction { reviewed, skipped, snoozed, dismissed }

/// Unified attention rules (replaces review_settings, soft_gates_settings, allocation_alerts_settings)
class AttentionRules extends Table {
  @override
  String get tableName => 'attention_rules';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();

  /// Unique identifier for the rule type (e.g., "task_overdue", "values_alignment_check")
  TextColumn get ruleKey => text().named('rule_key')();

  TextColumn get userId => text().nullable().named('user_id')();

  /// Stable grouping axes.
  TextColumn get bucket => textEnum<AttentionBucket>().named('bucket')();

  /// Stable evaluator key.
  TextColumn get evaluator => text().named('evaluator')();

  /// Evaluator params payload (jsonb in Supabase, TEXT in SQLite).
  TextColumn get evaluatorParams =>
      text().map(const JsonMapConverter()).named('evaluator_params')();

  /// Severity level: critical, warning, info
  TextColumn get severity => textEnum<AttentionSeverity>().named('severity')();

  /// Display configuration (title, description, icon, etc.)
  TextColumn get displayConfig =>
      text().map(const JsonMapConverter()).named('display_config')();

  /// Available resolution actions as JSON array.
  ///
  /// Stored as a JSON array string (e.g. ["reviewed","snoozed"]).
  TextColumn get resolutionActions =>
      text().map(const JsonStringListConverter()).named('resolution_actions')();

  /// Whether this rule is active
  BoolColumn get active =>
      boolean().clientDefault(() => true).named('active')();

  /// Entity source: system_template, user_created, or imported
  TextColumn get source => textEnum<EntitySource>()
      .clientDefault(() => EntitySource.user_created.name)
      .named('source')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Engine-owned runtime state for attention rules.
///
/// This table holds dismiss/snooze/state-hash semantics independent of the
/// immutable rule definition.
class AttentionRuleRuntimeStates extends Table {
  @override
  String get tableName => 'attention_rule_runtime_state';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();

  TextColumn get userId => text().nullable().named('user_id')();

  /// Foreign key to attention_rules.id
  TextColumn get ruleId =>
      text().named('rule_id').references(AttentionRules, #id)();

  /// Optional scope to an entity (must be paired with entityId).
  TextColumn get entityType => text().nullable().named('entity_type')();

  /// Optional scope to an entity (must be paired with entityType).
  TextColumn get entityId => text().nullable().named('entity_id')();

  /// Current evaluation state hash for the rule+entity.
  TextColumn get stateHash => text().nullable().named('state_hash')();

  /// If set, indicates the last dismissed state hash.
  TextColumn get dismissedStateHash =>
      text().nullable().named('dismissed_state_hash')();

  DateTimeColumn get lastEvaluatedAt =>
      dateTime().nullable().named('last_evaluated_at')();

  DateTimeColumn get nextEvaluateAfter =>
      dateTime().nullable().named('next_evaluate_after')();

  TextColumn get metadata =>
      text().map(const JsonMapConverter()).named('metadata')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();

  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {ruleId, entityType, entityId},
  ];
}

/// Attention resolutions (tracks when users resolve attention items, replaces last_reviewed_at columns)
class AttentionResolutions extends Table {
  @override
  String get tableName => 'attention_resolutions';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();

  TextColumn get userId => text().nullable().named('user_id')();

  /// Foreign key to attention_rules.id
  TextColumn get ruleId =>
      text().named('rule_id').references(AttentionRules, #id)();

  /// Entity that was resolved (task id, project id, etc.)
  TextColumn get entityId => text().named('entity_id')();

  /// Entity type: task, project, value, journal, tracker
  TextColumn get entityType => text().named('entity_type')();

  /// When the item was resolved
  DateTimeColumn get resolvedAt =>
      dateTime().clientDefault(DateTime.now).named('resolved_at')();

  /// How the user resolved it: reviewed, skipped, snoozed, dismissed
  TextColumn get resolutionAction =>
      textEnum<AttentionResolutionAction>().named('resolution_action')();

  /// Additional action details (notes, snooze_until, etc.) as JSON
  TextColumn get actionDetails =>
      text().map(const JsonMapConverter()).nullable().named('action_details')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}
