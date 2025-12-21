import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
part 'drift_database.g.dart';

enum LabelType { label, value }

class ProjectTable extends Table {
  @override
  String get tableName => 'projects';
  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get description => text().nullable().named('description')();
  BoolColumn get completed => boolean().named('completed')();
  DateTimeColumn get startDate => dateTime().nullable().named('start_date')();
  DateTimeColumn get deadlineDate =>
      dateTime().nullable().named('deadline_date')();
  TextColumn get repeatIcalRrule =>
      text().nullable().named('repeat_ical_rrule').clientDefault(() => '')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskTable extends Table {
  @override
  String get tableName => 'tasks';

  TextColumn get id => text().named('id')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  BoolColumn get completed =>
      boolean().clientDefault(() => false).named('completed')();
  DateTimeColumn get startDate => dateTime().nullable().named('start_date')();
  DateTimeColumn get deadlineDate =>
      dateTime().nullable().named('deadline_date')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get projectId => text()
      .nullable()
      .named('project_id')
      .references(ProjectTable, #id, onDelete: KeyAction.setNull)();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get repeatIcalRrule =>
      text().nullable().named('repeat_ical_rrule').clientDefault(() => '')();

  @override
  Set<Column> get primaryKey => {id};
}

class LabelTable extends Table {
  @override
  String get tableName => 'labels';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get color =>
      text().nullable().named('color').clientDefault(() => '#000000')();
  TextColumn get type => textEnum<LabelType>()
      .named('type')
      .withDefault(const Constant('label'))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  List<String> get customConstraints => [
    "CHECK (color IS NULL OR color GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')",
  ];

  @override
  Set<Column> get primaryKey => {id};
}

class ProjectLabelsTable extends Table {
  @override
  String get tableName => 'project_labels';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get projectId => text()
      .named('project_id')
      .references(ProjectTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get labelId => text()
      .named('label_id')
      .references(LabelTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  List<Set<Column>> get uniqueKeys => [
    {projectId, labelId},
  ];

  @override
  Set<Column> get primaryKey => {id};
}

class TaskLabelsTable extends Table {
  @override
  String get tableName => 'task_labels';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get taskId => text()
      .named('task_id')
      .references(TaskTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get labelId => text()
      .named('label_id')
      .references(LabelTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, labelId},
  ];

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    ProjectTable,
    TaskTable,
    LabelTable,
    ProjectLabelsTable,
    TaskLabelsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // PowerSync owns the underlying SQLite schema. Avoid destructive drift
    // migrations (like table rebuilds) that could drop synced columns.
    onUpgrade: (migrator, from, to) async {},
    beforeOpen: (details) async {
      // Ensure SQLite enforces foreign keys at runtime.
      // Do not enable. Powersync exposes views which do not support
      // foreign key constraints.
      //  await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
