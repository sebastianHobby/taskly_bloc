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
  Table('projects', [
    Column.text('name'),
    Column.text('description'),
    Column.integer('completed'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('user_id'),
    Column.text('start_date'),
    Column.text('deadline_date'),
    Column.text('repeat_ical_rrule'),
    Column.text('last_review_date'),
  ]),
  Table('labels', [
    Column.text('name'),
    Column.text('color'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('user_id'),
    Column.text('type'),
  ]),
  Table('task_labels', [
    Column.text('task_id'),
    Column.text('label_id'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('user_id'),
  ]),
  Table('project_labels', [
    Column.text('project_id'),
    Column.text('label_id'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('user_id'),
  ]),
  Table('user_profiles', [
    Column.text('user_id'),
    Column.text('settings'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
]);
