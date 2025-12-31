import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/converters/json_converters.dart';

/// Screen types for generic screen system
enum ScreenType { collection, workflow }

/// Entity types for screens
enum EntityType { task, project, label, goal }

/// Screen categories for organizing navigation
enum ScreenCategory { workspace, wellbeing, settings }

/// Workflow session status
enum WorkflowStatus { inProgress, completed, abandoned }

/// Workflow action types
enum WorkflowAction { reviewed, skipped }

/// Generic screen system - defines both collection and workflow screens
@DataClassName('ScreenDefinitionEntity')
class ScreenDefinitions extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get screenType => textEnum<ScreenType>()();
  TextColumn get screenId =>
      text()(); // Unique identifier like 'today', 'inbox'
  TextColumn get name => text()();
  TextColumn get iconName => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(
    const Constant(false),
  )(); // System screens can't be deleted
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get category => textEnum<ScreenCategory>().withDefault(
    const Constant('workspace'),
  )();

  // EntitySelector configuration (stored as JSON text)
  TextColumn get entityType => textEnum<EntityType>()();
  TextColumn get selectorConfig => text().map(entitySelectorConverter)();

  // DisplayConfig (stored as JSON text)
  TextColumn get displayConfig => text().map(displayConfigConverter)();

  // Workflow-specific (NULL for collection screens)
  TextColumn get triggerConfig =>
      text().map(triggerConfigConverter).nullable()();
  TextColumn get completionCriteria =>
      text().map(completionCriteriaConverter).nullable()();

  // Denormalized trigger fields for server-driven scheduling
  TextColumn get triggerType => text().nullable()();
  DateTimeColumn get nextTriggerAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Notifications enqueued by the server (pg_cron) and synced via PowerSync.
@DataClassName('PendingNotificationEntity')
class PendingNotifications extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get screenDefinitionId => text().customConstraint(
    'NOT NULL REFERENCES screen_definitions(id) ON DELETE CASCADE',
  )();
  DateTimeColumn get scheduledFor => dateTime()();

  /// 'pending' | 'delivered' | 'dismissed' | etc.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Optional JSON payload.
  TextColumn get payload => text().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get seenAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks individual workflow execution sessions
@DataClassName('WorkflowSessionEntity')
class WorkflowSessions extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get screenId => text().customConstraint(
    'NOT NULL REFERENCES screen_definitions(id) ON DELETE CASCADE',
  )();
  TextColumn get status =>
      textEnum<WorkflowStatus>().withDefault(const Constant('inProgress'))();
  DateTimeColumn get startedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get totalItems => integer().withDefault(const Constant(0))();
  IntColumn get itemsReviewed => integer().withDefault(const Constant(0))();
  IntColumn get itemsSkipped => integer().withDefault(const Constant(0))();
  TextColumn get sessionNotes => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks per-item review actions within a workflow session
@DataClassName('WorkflowItemReviewEntity')
class WorkflowItemReviews extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get sessionId => text().customConstraint(
    'NOT NULL REFERENCES workflow_sessions(id) ON DELETE CASCADE',
  )();
  TextColumn get entityId => text()(); // Task, project, or label being reviewed
  TextColumn get entityType => textEnum<EntityType>()();
  TextColumn get action => textEnum<WorkflowAction>()();
  TextColumn get reviewNotes => text().nullable()();
  DateTimeColumn get reviewedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  TextColumn get userId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Soft gate warnings and user acknowledgments
@DataClassName('ProblemAcknowledgmentEntity')
class ProblemAcknowledgments extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get problemType =>
      text()(); // 'excluded_urgent_task', 'overdue_high_priority', etc.
  TextColumn get entityId => text()();
  TextColumn get entityType => textEnum<EntityType>()();
  DateTimeColumn get acknowledgedAt => dateTime().clientDefault(DateTime.now)();
  TextColumn get resolutionAction =>
      text().nullable()(); // 'dismissed', 'fixed', 'snoozed'
  DateTimeColumn get snoozeUntil => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}
