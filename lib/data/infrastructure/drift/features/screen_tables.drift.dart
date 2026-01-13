import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;

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
