import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/converters/json_converters.dart';

/// Screen types for generic screen system
enum ScreenType { collection, workflow }

/// Entity types for screens
enum EntityType { task, project, label, goal }

/// Screen categories for organizing navigation
enum ScreenCategory { workspace, wellbeing, settings }

/// Generic screen system - defines both collection and workflow screens
@DataClassName('ScreenDefinitionEntity')
class ScreenDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get screenType => textEnum<ScreenType>()();
  TextColumn get screenKey =>
      text()(); // Stable per-user identifier like 'today', 'inbox'
  TextColumn get name => text()();
  TextColumn get iconName => text().nullable()();
  BoolColumn get isSystem => boolean().withDefault(
    const Constant(false),
  )(); // System screens can't be deleted
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get category => textEnum<ScreenCategory>()
      .withDefault(const Constant('workspace'))
      .nullable()();

  // EntitySelector configuration (stored as JSON text)
  TextColumn get entityType => textEnum<EntityType>().nullable()();
  TextColumn get selectorConfig =>
      text().map(entitySelectorConverter).nullable()();

  // DisplayConfig (stored as JSON text)
  TextColumn get displayConfig =>
      text().map(displayConfigConverter).nullable()();

  // Workflow-specific (NULL for collection screens)
  TextColumn get triggerConfig =>
      text().map(triggerConfigConverter).nullable()();

  // Denormalized trigger fields for server-driven scheduling
  TextColumn get triggerType => text().nullable()();
  DateTimeColumn get nextTriggerAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {userId, screenKey},
  ];
}

/// Notifications enqueued by the server (pg_cron) and synced via PowerSync.
@DataClassName('PendingNotificationEntity')
class PendingNotifications extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();

  /// Screen key (e.g., 'inbox', 'today') - references system or custom screens.
  TextColumn get screenKey => text()();
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
