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

/// Persisted sync anomalies for diagnostics and follow-up fixes.
class SyncIssues extends Table {
  @override
  String get tableName => 'sync_issues';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get userId => text().named('user_id')();
  TextColumn get status => text().named('status')();
  TextColumn get severity => text().named('severity')();
  TextColumn get category => text().named('category')();
  TextColumn get fingerprint => text().named('fingerprint')();
  TextColumn get issueCode => text().named('issue_code')();
  TextColumn get title => text().named('title')();
  TextColumn get message => text().named('message')();
  TextColumn get correlationId => text().nullable().named('correlation_id')();
  TextColumn get syncSessionId => text().nullable().named('sync_session_id')();
  TextColumn get clientId => text().nullable().named('client_id')();
  TextColumn get operation => text().nullable().named('operation')();
  TextColumn get entityType => text().nullable().named('entity_type')();
  TextColumn get entityId => text().nullable().named('entity_id')();
  TextColumn get remoteCode => text().nullable().named('remote_code')();
  TextColumn get remoteMessage => text().nullable().named('remote_message')();
  TextColumn get details => text().named('details')();
  DateTimeColumn get firstSeenAt => dateTime().named('first_seen_at')();
  DateTimeColumn get lastSeenAt => dateTime().named('last_seen_at')();
  IntColumn get occurrenceCount => integer().named('occurrence_count')();
  DateTimeColumn get resolvedAt => dateTime().nullable().named('resolved_at')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}
