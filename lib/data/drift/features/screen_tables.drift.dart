import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/converters/json_converters.dart';

/// Screen types for unified screen system
enum ScreenType { list, dashboard, focus, workflow }

/// Screen categories for organizing navigation
enum ScreenCategory { workspace, wellbeing, settings }

/// Source/origin of a screen definition
enum ScreenSource { systemTemplate, userDefined }

/// Unified screen system - all screens are composed of sections
@DataClassName('ScreenDefinitionEntity')
class ScreenDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  // Screen type - nullable to handle corrupted/partial sync data gracefully
  TextColumn get screenType => textEnum<ScreenType>().nullable()();
  TextColumn get screenKey =>
      text()(); // Stable per-user identifier like 'today', 'inbox'
  TextColumn get name => text()();
  TextColumn get iconName => text().nullable()();

  /// Source of the screen (system template vs user-defined).
  /// Replaces the old isSystem boolean for more expressiveness.
  TextColumn get screenSource => textEnum<ScreenSource>()
      .withDefault(const Constant('userDefined'))
      .nullable()();
  TextColumn get category => textEnum<ScreenCategory>()
      .withDefault(const Constant('workspace'))
      .nullable()();

  // Sections configuration (stored as JSON text) - DR-017
  TextColumn get sectionsConfig =>
      text().map(sectionsConfigConverter).nullable()();

  // Support blocks configuration (stored as JSON text) - DR-018
  TextColumn get supportBlocksConfig =>
      text().map(supportBlocksConfigConverter).nullable()();

  // Workflow-specific (NULL for non-workflow screens)
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
    {screenKey}, // Unique per-device; Supabase enforces userId+screenKey
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
