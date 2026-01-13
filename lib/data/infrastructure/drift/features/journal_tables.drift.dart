import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;

@DataClassName('JournalEntryEntity')
class JournalEntries extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get entryDate => dateTime()();
  DateTimeColumn get entryTime => dateTime()();
  IntColumn get moodRating => integer().nullable().customConstraint(
    'CHECK (mood_rating BETWEEN 1 AND 5)',
  )();
  TextColumn get journalText => text().nullable()();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
