import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/features/analytics_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/wellbeing_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/attention_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/allocation_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/workflow_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/shared_enums.dart';
import 'package:taskly_bloc/data/drift/converters/date_only_string_converter.dart';
import 'package:taskly_bloc/data/drift/converters/json_converters.dart';
import 'package:taskly_bloc/domain/models/value_priority.dart';
// Domain models needed by TypeConverters in generated code
import 'package:taskly_bloc/domain/models/screens/actions_config.dart';
import 'package:taskly_bloc/domain/models/screens/content_config.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step_state.dart';
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

  @override
  List<String> get customConstraints => [
    "CHECK (color IS NULL OR color GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')",
  ];

  @override
  Set<Column> get primaryKey => {id};
}

class ProjectValuesTable extends Table {
  @override
  String get tableName => 'project_values';

  TextColumn get id => text().named('id')();
  TextColumn get projectId => text()
      .named('project_id')
      .references(ProjectTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get valueId => text()
      .named('value_id')
      .references(ValueTable, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isPrimary =>
      boolean().clientDefault(() => false).named('is_primary')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  List<Set<Column>> get uniqueKeys => [
    {projectId, valueId},
  ];

  @override
  Set<Column> get primaryKey => {id};
}

class TaskValuesTable extends Table {
  @override
  String get tableName => 'task_values';

  TextColumn get id => text().named('id')();
  TextColumn get taskId => text()
      .named('task_id')
      .references(TaskTable, #id, onDelete: KeyAction.cascade)();
  TextColumn get valueId => text()
      .named('value_id')
      .references(ValueTable, #id, onDelete: KeyAction.cascade)();
  BoolColumn get isPrimary =>
      boolean().clientDefault(() => false).named('is_primary')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, valueId},
  ];

  @override
  Set<Column> get primaryKey => {id};
}

class UserProfileTable extends Table {
  @override
  String get tableName => 'user_profiles';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();

  // Note: user_id not included - managed by Supabase, not synced to client

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

@DriftDatabase(
  tables: [
    ProjectTable,
    TaskTable,
    ValueTable,
    ProjectValuesTable,
    TaskValuesTable,
    UserProfileTable,
    TaskCompletionHistoryTable,
    ProjectCompletionHistoryTable,
    TaskRecurrenceExceptionsTable,
    ProjectRecurrenceExceptionsTable,
    // Analytics tables
    AnalyticsSnapshots,
    AnalyticsCorrelations,
    AnalyticsInsights,
    // Wellbeing tables
    JournalEntries,
    Trackers,
    TrackerResponses,
    DailyTrackerResponses,
    // Screen definitions (system templates + user-created)
    ScreenDefinitions,
    // Screen preferences (per-user ordering/visibility)
    ScreenPreferencesTable,
    PendingNotifications,
    // Workflow tables
    WorkflowDefinitions,
    Workflows,
    // Allocation snapshots (allocated membership only)
    AllocationSnapshots,
    AllocationSnapshotEntries,
    // Attention System (unified attention management)
    AttentionRules,
    AttentionResolutions,
    AttentionRuleRuntimeStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 16;

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
