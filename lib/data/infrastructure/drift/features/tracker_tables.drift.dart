import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;

@DataClassName('TrackerDefinitionEntity')
class TrackerDefinitions extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();

  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();

  /// Supabase: scope in {entry, day, sleep_night}
  TextColumn get scope => text().withLength(min: 1, max: 50)();

  /// Supabase: text[] (stored as TEXT in SQLite)
  TextColumn get roles => text().clientDefault(() => '[]')();

  /// Supabase: value_type in {rating, quantity, choice, yes_no}
  TextColumn get valueType => text().withLength(min: 1, max: 50)();

  /// Supabase: jsonb
  TextColumn get config => text().clientDefault(() => '{}')();

  /// Supabase: jsonb
  TextColumn get goal => text().clientDefault(() => '{}')();

  BoolColumn get isActive => boolean().clientDefault(() => true)();
  IntColumn get sortOrder => integer().clientDefault(() => 0)();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  /// Supabase: source in {user, system}
  TextColumn get source => text().clientDefault(() => 'user')();
  TextColumn get systemKey => text().nullable()();

  /// Supabase: op_kind in {set, add}
  TextColumn get opKind => text().clientDefault(() => 'set')();

  /// Supabase: value_kind in {rating, number, boolean, single_choice}
  TextColumn get valueKind => text().nullable()();

  /// Supabase: unit_kind in {count, ml, mg, minutes, steps}
  TextColumn get unitKind => text().nullable()();

  Int64Column get minInt => int64().nullable()();
  Int64Column get maxInt => int64().nullable()();
  Int64Column get stepInt => int64().nullable()();

  TextColumn get linkedValueId => text().nullable()();

  BoolColumn get isOutcome => boolean().clientDefault(() => false)();
  BoolColumn get isInsightEnabled => boolean().clientDefault(() => false)();
  BoolColumn get higherIsBetter => boolean().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TrackerPreferenceEntity')
class TrackerPreferences extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get trackerId => text()();

  BoolColumn get isActive => boolean().clientDefault(() => true)();
  IntColumn get sortOrder => integer().clientDefault(() => 0)();
  BoolColumn get pinned => boolean().clientDefault(() => false)();
  BoolColumn get showInQuickAdd => boolean().clientDefault(() => false)();
  TextColumn get color => text().nullable()();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>>? get uniqueKeys => [
    {trackerId},
  ];
}

@DataClassName('TrackerDefinitionChoiceEntity')
class TrackerDefinitionChoices extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get trackerId => text()();

  TextColumn get choiceKey => text().withLength(min: 1, max: 200)();
  TextColumn get label => text().withLength(min: 1, max: 200)();

  IntColumn get sortOrder => integer().clientDefault(() => 0)();
  BoolColumn get isActive => boolean().clientDefault(() => true)();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TrackerEventEntity')
class TrackerEvents extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();
  TextColumn get trackerId => text()();

  /// Supabase: anchor_type in {entry, day, sleep_night}
  TextColumn get anchorType => text().withLength(min: 1, max: 50)();

  TextColumn get entryId => text().nullable()();
  DateTimeColumn get anchorDate => dateTime().nullable()();

  /// Supabase: op in {set, add, clear}
  TextColumn get op => text().withLength(min: 1, max: 50)();

  /// Supabase: jsonb
  TextColumn get value => text().nullable()();

  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get recordedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TrackerStateDayEntity')
class TrackerStateDay extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();

  /// Supabase: anchor_type in {day, sleep_night}
  TextColumn get anchorType => text().withLength(min: 1, max: 50)();
  DateTimeColumn get anchorDate => dateTime()();

  TextColumn get trackerId => text()();

  /// Supabase: jsonb
  TextColumn get value => text().nullable()();

  TextColumn get lastEventId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TrackerStateEntryEntity')
class TrackerStateEntry extends Table {
  TextColumn get id => text().clientDefault(uuid.v4)();
  TextColumn get userId => text().nullable()();

  TextColumn get entryId => text()();
  TextColumn get trackerId => text()();

  /// Supabase: jsonb
  TextColumn get value => text().nullable()();

  TextColumn get lastEventId => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column> get primaryKey => {id};
}
