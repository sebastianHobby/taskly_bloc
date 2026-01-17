import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;

/// Server-enqueued notifications synced via PowerSync.
class PendingNotifications extends Table {
  @override
  String get tableName => 'pending_notifications';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();

  /// Owning user. Filtered by Supabase RLS + PowerSync bucket rules.
  TextColumn get userId => text().nullable().named('user_id')();

  /// When the notification should be delivered.
  DateTimeColumn get scheduledFor => dateTime().named('scheduled_for')();

  /// Current status (e.g. 'pending', 'delivered').
  TextColumn get status => text().named('status')();

  /// JSON payload encoded as text.
  TextColumn get payload => text().nullable().named('payload')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();

  DateTimeColumn get deliveredAt =>
      dateTime().nullable().named('delivered_at')();

  DateTimeColumn get seenAt => dateTime().nullable().named('seen_at')();

  /// Screen identifier for routing.
  TextColumn get screenKey => text().named('screen_key')();

  @override
  Set<Column> get primaryKey => {id};
}
