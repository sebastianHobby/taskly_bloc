import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_data/src/infrastructure/drift/converters/date_only_string_converter.dart';
import 'package:taskly_data/src/infrastructure/drift/converters/json_converters.dart';
import 'package:taskly_data/src/infrastructure/drift/features/analytics_tables.drift.dart';
import 'package:taskly_data/src/infrastructure/drift/features/attention_tables.drift.dart';
import 'package:taskly_data/src/infrastructure/drift/features/journal_tables.drift.dart';
import 'package:taskly_data/src/infrastructure/drift/features/screen_tables.drift.dart';
import 'package:taskly_data/src/infrastructure/drift/features/shared_enums.dart';
import 'package:taskly_data/src/infrastructure/drift/features/tracker_tables.drift.dart';
import 'package:taskly_domain/core.dart' hide Value;
part 'drift_database.g.dart';

/// Exception types for recurrence modifications
enum ExceptionType { skip, reschedule }

class ProjectTable extends Table {
  @override
  String get tableName => 'projects';
  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get description => text().nullable().named('description')();
  BoolColumn get completed => boolean().named('completed')();
  TextColumn get startDate =>
      text().map(dateOnlyStringConverter).nullable().named('start_date')();
  TextColumn get deadlineDate =>
      text().map(dateOnlyStringConverter).nullable().named('deadline_date')();
  TextColumn get repeatIcalRrule =>
      text().nullable().named('repeat_ical_rrule').clientDefault(() => '')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  /// When true, stops generating future occurrences for repeating projects
  BoolColumn get seriesEnded =>
      boolean().clientDefault(() => false).named('series_ended')();

  /// When true, recurrence is anchored to last completion date instead of
  /// original start date. Used for rolling/relative patterns like
  /// "7 days after completion".
  BoolColumn get repeatFromCompletion =>
      boolean().clientDefault(() => false).named('repeat_from_completion')();

  /// Priority level (1=P1/highest, 4=P4/lowest, null=none)
  IntColumn get priority => integer().nullable().named('priority')();

  /// Whether this project is pinned to the top of lists
  BoolColumn get isPinned =>
      boolean().clientDefault(() => false).named('pinned')();

  /// Last time a task in this project was completed (UTC).
  DateTimeColumn get lastProgressAt =>
      dateTime().nullable().named('last_progress_at')();

  /// Primary value slot for this project (nullable).
  @ReferenceName('primaryValueProjects')
  TextColumn get primaryValueId => text()
      .nullable()
      .named('primary_value_id')
      .references(ValueTable, #id, onDelete: KeyAction.setNull)();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  ///
  /// This should generally be treated as internal (not part of domain state).
  TextColumn get psMetadata => text().nullable().named('_metadata')();

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
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  BoolColumn get completed =>
      boolean().clientDefault(() => false).named('completed')();
  TextColumn get startDate =>
      text().map(dateOnlyStringConverter).nullable().named('start_date')();
  TextColumn get deadlineDate =>
      text().map(dateOnlyStringConverter).nullable().named('deadline_date')();
  DateTimeColumn get myDaySnoozedUntilUtc =>
      dateTime().nullable().named('my_day_snoozed_until')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get projectId => text()
      .nullable()
      .named('project_id')
      .references(ProjectTable, #id, onDelete: KeyAction.setNull)();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get repeatIcalRrule =>
      text().nullable().named('repeat_ical_rrule').clientDefault(() => '')();

  /// When true, stops generating future occurrences for repeating tasks
  BoolColumn get seriesEnded =>
      boolean().clientDefault(() => false).named('series_ended')();

  /// When true, recurrence is anchored to last completion date instead of
  /// original start date. Used for rolling/relative patterns like
  /// "7 days after completion".
  BoolColumn get repeatFromCompletion =>
      boolean().clientDefault(() => false).named('repeat_from_completion')();

  /// Optional notes from last review
  TextColumn get reviewNotes => text().nullable().named('review_notes')();

  /// Priority level (1=P1/highest, 4=P4/lowest, null=none)
  IntColumn get priority => integer().nullable().named('priority')();

  /// Whether this task is pinned to the top of lists
  BoolColumn get isPinned =>
      boolean().clientDefault(() => false).named('pinned')();

  /// Reminder type ('none', 'absolute', 'before_due').
  TextColumn get reminderKind =>
      text().clientDefault(() => 'none').named('reminder_kind')();

  /// Absolute reminder timestamp (UTC) for absolute reminders.
  DateTimeColumn get reminderAtUtc =>
      dateTime().nullable().named('reminder_at_utc')();

  /// Relative reminder offset in minutes before due date.
  IntColumn get reminderMinutesBeforeDue =>
      integer().nullable().named('reminder_minutes_before_due')();

  /// Task override primary value slot (nullable).
  ///
  /// When set, the task is considered to override project value slots.
  @ReferenceName('overridePrimaryValueTasks')
  TextColumn get overridePrimaryValueId => text()
      .nullable()
      .named('override_primary_value_id')
      .references(ValueTable, #id, onDelete: KeyAction.setNull)();

  /// Task override secondary value slot (nullable).
  @ReferenceName('overrideSecondaryValueTasks')
  TextColumn get overrideSecondaryValueId => text()
      .nullable()
      .named('override_secondary_value_id')
      .references(ValueTable, #id, onDelete: KeyAction.setNull)();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  ///
  /// This should generally be treated as internal (not part of domain state).
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class ValueTable extends Table {
  @override
  String get tableName => 'values';

  TextColumn get id => text().named('id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get color => text().named('color')();
  TextColumn get iconName => text().nullable().named('icon_name')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  /// Priority level (low, medium, high)
  TextColumn get priority =>
      textEnum<ValuePriority>().nullable().named('priority')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  ///
  /// This should generally be treated as internal (not part of domain state).
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  List<String> get customConstraints => [
    "CHECK (color IS NULL OR color GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')",
  ];

  @override
  Set<Column> get primaryKey => {id};
}

class ValueRatingsWeeklyTable extends Table {
  @override
  String get tableName => 'value_ratings_weekly';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();

  @ReferenceName('valueRatingsValue')
  TextColumn get valueId => text()
      .named('value_id')
      .references(ValueTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get weekStart =>
      text().map(dateOnlyStringConverter).named('week_start')();

  IntColumn get rating => integer().named('rating')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {userId, valueId, weekStart},
  ];
}

class UserProfileTable extends Table {
  @override
  String get tableName => 'user_profiles';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();
  // Server-owned (auth.uid()) but synced to client for reads.
  TextColumn get userId => text().nullable().named('user_id')();

  /// Settings override map (jsonb in Supabase, TEXT in SQLite).
  ///
  /// This is nullable because PowerSync may omit unchanged fields.
  /// The repository treats null/invalid as an empty map and repairs it.
  TextColumn get settingsOverrides =>
      text().nullable().named('settings_overrides')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class MyDayDaysTable extends Table {
  @override
  String get tableName => 'my_day_days';

  TextColumn get id => text().named('id')();

  TextColumn get userId => text().nullable().named('user_id')();

  /// UTC day key stored as a date-only string.
  TextColumn get dayUtc =>
      text().map(dateOnlyStringConverter).named('day_utc')();

  DateTimeColumn get ritualCompletedAt =>
      dateTime().nullable().named('ritual_completed_at')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class MyDayPicksTable extends Table {
  @override
  String get tableName => 'my_day_picks';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();

  TextColumn get dayId => text()
      .named('day_id')
      .references(MyDayDaysTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get taskId => text()
      .named('task_id')
      .nullable()
      .references(TaskTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get routineId => text()
      .named('routine_id')
      .nullable()
      .references(RoutinesTable, #id, onDelete: KeyAction.cascade)();

  /// One of: values, routine, due, starts, manual.
  TextColumn get bucket => text().named('bucket')();

  IntColumn get sortIndex => integer().named('sort_index')();

  DateTimeColumn get pickedAt => dateTime().named('picked_at')();

  IntColumn get suggestionRank =>
      integer().nullable().named('suggestion_rank')();

  @ReferenceName('qualifyingValueMyDayPicks')
  TextColumn get qualifyingValueId => text()
      .nullable()
      .named('qualifying_value_id')
      .references(ValueTable, #id, onDelete: KeyAction.setNull)();

  TextColumn get reasonCodes => text()
      .map(const JsonStringListConverter())
      .nullable()
      .named('reason_codes')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class MyDayDecisionEventsTable extends Table {
  @override
  String get tableName => 'my_day_decision_events';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get dayKeyUtc =>
      text().map(dateOnlyStringConverter).named('day_key_utc')();
  TextColumn get entityType => text().named('entity_type')();
  TextColumn get entityId => text().named('entity_id')();
  TextColumn get shelf => text().named('shelf')();
  TextColumn get action => text().named('action')();
  DateTimeColumn get actionAtUtc => dateTime().named('action_at_utc')();
  TextColumn get deferKind => text().nullable().named('defer_kind')();
  TextColumn get fromDayKey =>
      text().map(dateOnlyStringConverter).nullable().named('from_day_key')();
  TextColumn get toDayKey =>
      text().map(dateOnlyStringConverter).nullable().named('to_day_key')();
  IntColumn get suggestionRank =>
      integer().nullable().named('suggestion_rank')();
  TextColumn get metaJson => text().nullable().named('meta_json')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  List<String> get customConstraints => [
    "CHECK (entity_type IN ('task','routine'))",
    "CHECK (shelf IN ('due','planned','routine_scheduled','routine_flexible','suggestion'))",
    "CHECK (\"action\" IN ('kept','deferred','snoozed','removed','completed'))",
    "CHECK (defer_kind IS NULL OR defer_kind IN ('deadline_reschedule','start_reschedule','snooze'))",
    'CHECK (suggestion_rank IS NULL OR suggestion_rank >= 0)',
  ];

  @override
  Set<Column> get primaryKey => {id};
}

// =============================================================================
// NEW TABLES FOR REPEATING TASKS
// =============================================================================

/// Tracks completion of task occurrences (both repeating and non-repeating)
class TaskCompletionHistoryTable extends Table {
  @override
  String get tableName => 'task_completion_history';

  TextColumn get id => text().named('id')();
  TextColumn get taskId => text()
      .named('task_id')
      .references(TaskTable, #id, onDelete: KeyAction.cascade)();

  /// The scheduled date of the occurrence. NULL for non-repeating tasks.
  DateTimeColumn get occurrenceDate =>
      dateTime().nullable().named('occurrence_date')();

  /// Original RRULE-generated date. For rescheduled tasks, this differs from
  /// occurrence_date. Used for on-time reporting.
  DateTimeColumn get originalOccurrenceDate =>
      dateTime().nullable().named('original_occurrence_date')();

  DateTimeColumn get completedAt =>
      dateTime().clientDefault(DateTime.now).named('completed_at')();
  TextColumn get notes => text().nullable().named('notes')();
  TextColumn get userId => text().nullable().named('user_id')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, occurrenceDate},
  ];
}

/// Tracks My Day snooze events for tasks.
class TaskSnoozeEventsTable extends Table {
  @override
  String get tableName => 'task_snooze_events';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get taskId => text()
      .named('task_id')
      .references(TaskTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get snoozedAt => dateTime().named('snoozed_at')();
  DateTimeColumn get snoozedUntil =>
      dateTime().nullable().named('snoozed_until')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tracks completion of project occurrences (both repeating and non-repeating)
class ProjectCompletionHistoryTable extends Table {
  @override
  String get tableName => 'project_completion_history';

  TextColumn get id => text().named('id')();
  TextColumn get projectId => text()
      .named('project_id')
      .references(ProjectTable, #id, onDelete: KeyAction.cascade)();

  /// The scheduled date of the occurrence. NULL for non-repeating projects.
  DateTimeColumn get occurrenceDate =>
      dateTime().nullable().named('occurrence_date')();

  /// Original RRULE-generated date. Used for on-time reporting.
  DateTimeColumn get originalOccurrenceDate =>
      dateTime().nullable().named('original_occurrence_date')();

  DateTimeColumn get completedAt =>
      dateTime().clientDefault(DateTime.now).named('completed_at')();
  TextColumn get notes => text().nullable().named('notes')();
  TextColumn get userId => text().nullable().named('user_id')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {projectId, occurrenceDate},
  ];
}

/// Modifications to individual task occurrences (skip or reschedule)
class TaskRecurrenceExceptionsTable extends Table {
  @override
  String get tableName => 'task_recurrence_exceptions';

  TextColumn get id => text().named('id')();
  TextColumn get taskId => text()
      .named('task_id')
      .references(TaskTable, #id, onDelete: KeyAction.cascade)();

  /// The RRULE date being modified
  DateTimeColumn get originalDate => dateTime().named('original_date')();

  /// 'skip' = remove occurrence, 'reschedule' = move to new_date
  TextColumn get exceptionType =>
      textEnum<ExceptionType>().named('exception_type')();

  /// Target date for reschedule. NULL if skip.
  DateTimeColumn get newDate => dateTime().nullable().named('new_date')();

  /// Override deadline for this occurrence. NULL = inherit from task.
  DateTimeColumn get newDeadline =>
      dateTime().nullable().named('new_deadline')();

  TextColumn get userId => text().nullable().named('user_id')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, originalDate},
  ];
}

/// Modifications to individual project occurrences (skip or reschedule)
class ProjectRecurrenceExceptionsTable extends Table {
  @override
  String get tableName => 'project_recurrence_exceptions';

  TextColumn get id => text().named('id')();
  TextColumn get projectId => text()
      .named('project_id')
      .references(ProjectTable, #id, onDelete: KeyAction.cascade)();

  /// The RRULE date being modified
  DateTimeColumn get originalDate => dateTime().named('original_date')();

  /// 'skip' = remove occurrence, 'reschedule' = move to new_date
  TextColumn get exceptionType =>
      textEnum<ExceptionType>().named('exception_type')();

  /// Target date for reschedule. NULL if skip.
  DateTimeColumn get newDate => dateTime().nullable().named('new_date')();

  /// Override deadline for this occurrence. NULL = inherit from project.
  DateTimeColumn get newDeadline =>
      dateTime().nullable().named('new_deadline')();

  TextColumn get userId => text().nullable().named('user_id')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {projectId, originalDate},
  ];
}

class ProjectAnchorStateTable extends Table {
  @override
  String get tableName => 'project_anchor_state';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();

  TextColumn get projectId => text()
      .named('project_id')
      .references(ProjectTable, #id, onDelete: KeyAction.cascade)();

  DateTimeColumn get lastAnchoredAt => dateTime().named('last_anchored_at')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskChecklistItemsTable extends Table {
  @override
  String get tableName => 'task_checklist_items';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get taskId => text()
      .named('task_id')
      .references(TaskTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  IntColumn get sortIndex => integer().named('sort_index')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class TaskChecklistItemStateTable extends Table {
  @override
  String get tableName => 'task_checklist_item_state';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get taskId => text()
      .named('task_id')
      .references(TaskTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get checklistItemId => text()
      .named('checklist_item_id')
      .references(TaskChecklistItemsTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get occurrenceDate =>
      text().map(dateOnlyStringConverter).nullable().named('occurrence_date')();
  BoolColumn get isChecked =>
      boolean().clientDefault(() => false).named('is_checked')();
  DateTimeColumn get checkedAt => dateTime().nullable().named('checked_at')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineChecklistItemsTable extends Table {
  @override
  String get tableName => 'routine_checklist_items';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get routineId => text()
      .named('routine_id')
      .references(RoutinesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  IntColumn get sortIndex => integer().named('sort_index')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineChecklistItemStateTable extends Table {
  @override
  String get tableName => 'routine_checklist_item_state';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get routineId => text()
      .named('routine_id')
      .references(RoutinesTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get checklistItemId => text()
      .named('checklist_item_id')
      .references(
        RoutineChecklistItemsTable,
        #id,
        onDelete: KeyAction.cascade,
      )();
  TextColumn get periodType => text().named('period_type')();
  TextColumn get windowKey =>
      text().map(dateOnlyStringConverter).named('window_key')();
  BoolColumn get isChecked =>
      boolean().clientDefault(() => false).named('is_checked')();
  DateTimeColumn get checkedAt => dateTime().nullable().named('checked_at')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class ChecklistEventsTable extends Table {
  @override
  String get tableName => 'checklist_events';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get parentType => text().named('parent_type')();
  TextColumn get parentId => text().named('parent_id')();
  TextColumn get checklistItemId =>
      text().nullable().named('checklist_item_id')();
  TextColumn get scopePeriodType =>
      text().nullable().named('scope_period_type')();
  TextColumn get scopeDate =>
      text().map(dateOnlyStringConverter).nullable().named('scope_date')();
  TextColumn get eventType => text().named('event_type')();
  TextColumn get metricsJson => text().named('metrics_json')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutinesTable extends Table {
  @override
  String get tableName => 'routines';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();

  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get projectId => text()
      .named('project_id')
      .references(ProjectTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get periodType => text().named('period_type')();
  TextColumn get scheduleMode => text().named('schedule_mode')();
  IntColumn get targetCount => integer().named('target_count')();

  TextColumn get scheduleDays => text()
      .map(const JsonIntListConverter())
      .nullable()
      .named('schedule_days')();
  TextColumn get scheduleMonthDays => text()
      .map(const JsonIntListConverter())
      .nullable()
      .named('schedule_month_days')();
  IntColumn get scheduleTimeMinutes =>
      integer().nullable().named('schedule_time_minutes')();
  IntColumn get minSpacingDays =>
      integer().nullable().named('min_spacing_days')();
  IntColumn get restDayBuffer =>
      integer().nullable().named('rest_day_buffer')();
  BoolColumn get isActive =>
      boolean().clientDefault(() => true).named('is_active')();
  TextColumn get pausedUntil =>
      text().map(dateOnlyStringConverter).nullable().named('paused_until')();

  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineCompletionsTable extends Table {
  @override
  String get tableName => 'routine_completions';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get routineId => text()
      .named('routine_id')
      .references(RoutinesTable, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get completedAt => dateTime().named('completed_at')();
  TextColumn get completedDayLocal => text()
      .map(dateOnlyStringConverter)
      .nullable()
      .named('completed_day_local')();
  IntColumn get completedWeekdayLocal =>
      integer().nullable().named('completed_weekday_local')();
  IntColumn get completedTimeLocalMinutes =>
      integer().nullable().named('completed_time_local_minutes')();
  IntColumn get timezoneOffsetMinutes =>
      integer().nullable().named('timezone_offset_minutes')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

class RoutineSkipsTable extends Table {
  @override
  String get tableName => 'routine_skips';

  TextColumn get id => text().named('id')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get routineId => text()
      .named('routine_id')
      .references(RoutinesTable, #id, onDelete: KeyAction.cascade)();

  TextColumn get periodType => text().named('period_type')();
  TextColumn get periodKey =>
      text().map(dateOnlyStringConverter).named('period_key')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();

  /// Per-write metadata captured by PowerSync when `trackMetadata` is enabled.
  TextColumn get psMetadata => text().nullable().named('_metadata')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    ProjectTable,
    TaskTable,
    ValueTable,
    ValueRatingsWeeklyTable,
    UserProfileTable,
    MyDayDaysTable,
    MyDayPicksTable,
    MyDayDecisionEventsTable,
    TaskCompletionHistoryTable,
    TaskSnoozeEventsTable,
    ProjectCompletionHistoryTable,
    TaskRecurrenceExceptionsTable,
    ProjectRecurrenceExceptionsTable,
    ProjectAnchorStateTable,
    TaskChecklistItemsTable,
    TaskChecklistItemStateTable,
    RoutinesTable,
    RoutineChecklistItemsTable,
    RoutineChecklistItemStateTable,
    ChecklistEventsTable,
    RoutineCompletionsTable,
    RoutineSkipsTable,
    // Analytics tables
    AnalyticsSnapshots,
    AnalyticsCorrelations,
    AnalyticsInsights,
    // Journal tables
    JournalEntries,
    // Tracker model (OPT-A): event-log + projections
    TrackerGroups,
    TrackerDefinitions,
    TrackerPreferences,
    TrackerDefinitionChoices,
    TrackerEvents,
    TrackerStateDay,
    TrackerStateEntry,
    PendingNotifications,
    SyncIssues,
    // Attention System (unified attention management)
    AttentionRules,
    AttentionResolutions,
    AttentionRuleRuntimeStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 23;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // PowerSync owns the underlying SQLite schema. Avoid destructive drift
    // migrations (like table rebuilds) that could drop synced columns.
    onUpgrade: (migrator, from, to) async {},
    beforeOpen: (details) async {
      // Backfill explicit recurrence anchors for legacy repeating entities.
      // U2 semantics require recurring items to have a start date anchor.
      await customStatement('''
        UPDATE tasks
        SET start_date = COALESCE(deadline_date, date(created_at))
        WHERE (start_date IS NULL OR TRIM(start_date) = '')
          AND TRIM(COALESCE(repeat_ical_rrule, '')) <> '';
      ''');
      await customStatement('''
        UPDATE projects
        SET start_date = COALESCE(deadline_date, date(created_at))
        WHERE (start_date IS NULL OR TRIM(start_date) = '')
          AND TRIM(COALESCE(repeat_ical_rrule, '')) <> '';
      ''');

      // Ensure SQLite enforces foreign keys at runtime.
      // Do not enable. Powersync exposes views which do not support
      // foreign key constraints.
      //  await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
