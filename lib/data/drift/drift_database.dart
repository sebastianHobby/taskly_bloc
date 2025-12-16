import 'package:drift/drift.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' show uuid;

part 'drift_database.g.dart';

class ProjectTable extends Table {
  @override
  String get tableName => 'projects';
  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get name => text().withLength(min: 1, max: 120).named('name')();
  TextColumn get description => text().nullable().named('description')();
  BoolColumn get completed =>
      boolean().clientDefault(() => false).named('completed')();
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

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get name => text().withLength(min: 1, max: 120).named('name')();
  BoolColumn get completed =>
      boolean().clientDefault(() => false).named('completed')();
  DateTimeColumn get startDate => dateTime().nullable().named('start_date')();
  DateTimeColumn get deadlineDate =>
      dateTime().nullable().named('deadline_date')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get projectId =>
      text().nullable().named('project_id').references(ProjectTable, #id)();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get repeatIcalRrule =>
      text().withDefault(const Constant('')).named('repeat_ical_rrule')();

  @override
  Set<Column> get primaryKey => {id};
}

class ValueTable extends Table {
  @override
  String get tableName => 'values';
  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get name => text().withLength(min: 1, max: 120).named('name')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  Set<Column> get primaryKey => {id};
}

class ProjectValuesLinkTable extends Table {
  @override
  String get tableName => 'project_values_link';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get projectId =>
      text().nullable().named('project_id').references(ProjectTable, #id)();
  TextColumn get valueId =>
      text().named('value_id').references(ValueTable, #id)();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  Set<Column> get primaryKey => {id};
}

class LabelTable extends Table {
  @override
  String get tableName => 'labels';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get name => text().withLength(min: 1, max: 120).named('name')();
  TextColumn get color =>
      text().withDefault(const Constant('#ffffff')).named('color')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  Set<Column> get primaryKey => {id};
}

class ProjectLabelsTable extends Table {
  @override
  String get tableName => 'project_labels';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get projectId =>
      text().named('project_id').references(ProjectTable, #id)();
  TextColumn get labelId =>
      text().named('label_id').references(LabelTable, #id)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskLabelsTable extends Table {
  @override
  String get tableName => 'task_labels';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get taskId => text().named('task_id').references(TaskTable, #id)();
  TextColumn get labelId =>
      text().named('label_id').references(LabelTable, #id)();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    ProjectTable,
    TaskTable,
    ValueTable,
    ProjectValuesLinkTable,
    LabelTable,
    ProjectLabelsTable,
    TaskLabelsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
