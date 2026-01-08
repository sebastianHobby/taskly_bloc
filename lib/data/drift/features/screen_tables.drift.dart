import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/converters/json_converters.dart';
import 'package:taskly_bloc/data/drift/features/shared_enums.dart';

/// Unified screen definitions table.
///
/// Stores both system-seeded screen templates and user-created screens.
/// System screens are seeded on first launch with source='system_template'.
/// User-created screens have source='user_created'.
///
/// This table supports:
/// - System screens (inbox, my_day, scheduled, etc.)
/// - User-created custom screens (via ScreenCreatorPage)
/// - Focus-optimized screens
/// - Future: Imported/shared screens (source='imported')
@DataClassName('ScreenDefinitionEntity')
class ScreenDefinitions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get screenKey =>
      text()(); // Stable per-user identifier like 'my_health_tasks'
  TextColumn get name => text()();
  TextColumn get iconName => text().nullable()();

  /// Entity source: system_template, user_created, or imported
  TextColumn get source =>
      textEnum<EntitySource>().withDefault(const Constant('user_created'))();

  /// Whether this screen is active/visible in navigation
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Sort order for navigation display (lower = earlier)
  IntColumn get sortOrder => integer().nullable()();

  /// Content configuration (sections) stored as JSON.
  /// Structure: { "sections": [...] }
  TextColumn get contentConfig =>
      text().map(contentConfigConverter).nullable()();

  /// Actions configuration (FAB + AppBar) stored as JSON.
  /// Structure: { "fabOperations": [...], "appBarActions": [...], "settingsRoute": "..." }
  /// NULL for screens without custom actions.
  TextColumn get actionsConfig =>
      text().map(actionsConfigConverter).nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {screenKey}, // Unique per-device; Supabase enforces userId+screenKey
  ];

  @override
  String get tableName => 'screen_definitions';
}

/// Per-user preferences for screen visibility and ordering.
///
/// Notes:
/// - `id` is the single UUID primary key (PowerSync requirement).
/// - `user_id` is synced/managed by backend/RLS; the app does not use it.
/// - `screen_key` identifies both system screens (by key) and custom screens
///   (by their screenKey).
@DataClassName('ScreenPreferenceEntity')
class ScreenPreferencesTable extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();

  /// Synced from server; not used in app logic.
  TextColumn get userId => text().nullable()();

  /// Screen identity key (system screenKey or custom screenKey).
  TextColumn get screenKey => text()();

  /// Whether the screen is visible in navigation.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// Sort order for navigation display (lower = earlier).
  IntColumn get sortOrder => integer().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {screenKey},
  ];

  @override
  String get tableName => 'screen_preferences';
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
  TextColumn get status => text().clientDefault(() => 'pending')();

  /// Optional JSON payload.
  TextColumn get payload => text().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
  DateTimeColumn get seenAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
