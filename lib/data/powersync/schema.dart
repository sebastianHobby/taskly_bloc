import 'package:powersync/powersync.dart';

//Generated from powersync dashboard --> Client setup
// Note powersync expects everything as SQLITE types of text,integer or real
// Casts it to appropiate type when syncing
const schema = Schema([
  // -------------------------------------------------------------------------
  // EXISTING TABLES
  // -------------------------------------------------------------------------
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
    Column.integer('series_ended'), // NEW: stops generating future occurrences
    Column.integer('repeat_from_completion'), // NEW: anchor to last completion
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
    Column.integer('series_ended'), // NEW: stops generating future occurrences
    Column.integer('repeat_from_completion'), // NEW: anchor to last completion
  ]),
  Table('labels', [
    Column.text('name'),
    Column.text('color'),
    Column.text('created_at'),
    Column.text('updated_at'),
    Column.text('user_id'),
    Column.text('type'),
    Column.text('icon_name'),
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

  // -------------------------------------------------------------------------
  // NEW TABLES FOR REPEATING TASKS
  // -------------------------------------------------------------------------

  /// Tracks completion of task occurrences (both repeating and non-repeating)
  Table('task_completion_history', [
    Column.text('task_id'),
    Column.text('occurrence_date'), // NULL for non-repeating tasks
    Column.text(
      'original_occurrence_date',
    ), // Original RRULE date (for on-time tracking)
    Column.text('completed_at'),
    Column.text('notes'),
    Column.text('user_id'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  /// Tracks completion of project occurrences (both repeating and non-repeating)
  Table('project_completion_history', [
    Column.text('project_id'),
    Column.text('occurrence_date'), // NULL for non-repeating projects
    Column.text(
      'original_occurrence_date',
    ), // Original RRULE date (for on-time tracking)
    Column.text('completed_at'),
    Column.text('notes'),
    Column.text('user_id'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  /// Modifications to individual task occurrences (skip or reschedule)
  Table('task_recurrence_exceptions', [
    Column.text('task_id'),
    Column.text('original_date'), // The RRULE date being modified
    Column.text('exception_type'), // 'skip' | 'reschedule'
    Column.text('new_date'), // Target date for reschedule (NULL if skip)
    Column.text('new_deadline'), // Override deadline (NULL = inherit)
    Column.text('user_id'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),

  /// Modifications to individual project occurrences (skip or reschedule)
  Table('project_recurrence_exceptions', [
    Column.text('project_id'),
    Column.text('original_date'), // The RRULE date being modified
    Column.text('exception_type'), // 'skip' | 'reschedule'
    Column.text('new_date'), // Target date for reschedule (NULL if skip)
    Column.text('new_deadline'), // Override deadline (NULL = inherit)
    Column.text('user_id'),
    Column.text('created_at'),
    Column.text('updated_at'),
  ]),
]);
