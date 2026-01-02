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

@DataClassName('TrackerEntity')
class Trackers extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get responseType => text().withLength(min: 1, max: 50)();
  TextColumn get responseConfig => text().clientDefault(() => '{}')(); // JSON
  TextColumn get entryScope => text().withLength(min: 1, max: 50)();
  IntColumn get sortOrder => integer().clientDefault(() => 0)();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {userId, name},
  ];
}

@DataClassName('TrackerResponseEntity')
class TrackerResponses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  TextColumn get journalEntryId => text()();
  TextColumn get trackerId => text()();
  TextColumn get responseValue => text()(); // JSON
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {journalEntryId, trackerId},
  ];
}

@DataClassName('DailyTrackerResponseEntity')
class DailyTrackerResponses extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()();
  DateTimeColumn get responseDate =>
      dateTime()(); // Date only (time component ignored)
  TextColumn get trackerId => text()();
  TextColumn get responseValue => text()(); // JSON
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {responseDate, trackerId}, // One response per tracker per day
  ];
}
