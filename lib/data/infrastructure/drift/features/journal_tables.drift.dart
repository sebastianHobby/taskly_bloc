import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;

@DataClassName('JournalEntryEntity')
class JournalEntries extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get entryDate => dateTime()();
  DateTimeColumn get entryTime => dateTime()();
  TextColumn get journalText => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Supabase: occurred_at (timestamp with time zone)
  DateTimeColumn get occurredAt => dateTime().clientDefault(DateTime.now)();

  /// Supabase: local_date (date)
  DateTimeColumn get localDate => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}
