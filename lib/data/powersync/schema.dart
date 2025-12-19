import 'package:powersync/powersync.dart';

//Generated from powersync dashboard --> Client setup
// Note powersync expects everything as SQLITE types of text,integer or real
// Casts it to appropiate type when syncing
const schema = Schema([
  Table('tasks', [
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('name'),
    Column.integer('completed'),
    Column.text('start_date'),
    Column.text('deadline_date'),
    Column.text('description'),
    Column.text('project_id'),
    Column.text('user_id'),
    Column.text('repeat_ical_rrule'),
  ]),
  Table('values', [
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('name'),
    Column.text('user_id'),
  ]),
  Table('projects', [
    Column.text('name'),
    Column.text('description'),
    Column.integer('completed'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('user_id'),
  ]),
  Table('project_values_link', [
    Column.text('project_id'),
    Column.text('value_id'),
    Column.text('user_id'),
  ]),
  Table('repeat_schedule', []),
]);
