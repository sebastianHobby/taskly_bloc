import 'package:drift/drift.dart';
import 'package:powersync/powersync.dart' show uuid;
import 'package:taskly_bloc/data/drift/features/analytics_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/wellbeing_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/screen_tables.drift.dart';
import 'package:taskly_bloc/data/drift/features/workflow_tables.drift.dart';
import 'package:taskly_bloc/data/drift/converters/date_only_string_converter.dart';
import 'package:taskly_bloc/data/drift/converters/json_converters.dart';
// Domain models needed by TypeConverters in generated code
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step.dart';
import 'package:taskly_bloc/domain/models/workflow/workflow_step_state.dart';
part 'drift_database.g.dart';

enum LabelType { label, value }

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

  /// Timestamp of last per-item review (standardized field)
  DateTimeColumn get lastReviewedAt =>
      dateTime().nullable().named('last_reviewed_at')();

  /// Priority level (1=P1/highest, 4=P4/lowest, null=none)
  IntColumn get priority => integer().nullable().named('priority')();

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

  /// Timestamp of last per-item review
  DateTimeColumn get lastReviewedAt =>
      dateTime().nullable().named('last_reviewed_at')();

  /// Optional notes from last review
  TextColumn get reviewNotes => text().nullable().named('review_notes')();

  /// Priority level (1=P1/highest, 4=P4/lowest, null=none)
  IntColumn get priority => integer().nullable().named('priority')();

  @override
  Set<Column> get primaryKey => {id};
}

class LabelTable extends Table {
  @override
  String get tableName => 'labels';

  TextColumn get id => text().named('id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get color => text().named('color')();
  TextColumn get type => textEnum<LabelType>()
      .named('type')
      .withDefault(const Constant('label'))();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(DateTime.now).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().clientDefault(DateTime.now).named('updated_at')();
  TextColumn get userId => text().nullable().named('user_id')();
  TextColumn get iconName => text().nullable().named('icon_name')();

  /// Whether this is a system-managed label
  BoolColumn get isSystemLabel => boolean()
      .nullable()
      .withDefault(const Constant(false))
      .named('is_system_label')();

  /// Type of system label (if isSystemLabel is true)
  TextColumn get systemLabelType =>
      text().nullable().named('system_label_type')();

  /// Timestamp of last per-item review (standardized field)
  DateTimeColumn get lastReviewedAt =>
      dateTime().nullable().named('last_reviewed_at')();

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

  TextColumn get id => text().named('id')();
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

  TextColumn get id => text().named('id')();
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

class UserProfileTable extends Table {
  @override
  String get tableName => 'user_profiles';

  TextColumn get id => text().clientDefault(uuid.v4).named('id')();

  // Note: user_id not included - managed by Supabase, not synced to client

  /// Individual settings columns for PowerSync field-level sync.
  /// Each column syncs independently to prevent cross-device conflicts.
  ///
  /// IMPORTANT: When inserting via PowerSync, you MUST explicitly provide
  /// values for all columns. The withDefault() only applies to Drift's own
  /// schema - PowerSync stores data as JSON blobs and will return NULL for
  /// any keys not present in the JSON.
  TextColumn get globalSettings =>
      text().withDefault(const Constant('{}')).named('global_settings')();
  TextColumn get allocationSettings =>
      text().withDefault(const Constant('{}')).named('allocation_settings')();
  TextColumn get softGatesSettings =>
      text().withDefault(const Constant('{}')).named('soft_gates_settings')();
  TextColumn get nextActionsSettings =>
      text().withDefault(const Constant('{}')).named('next_actions_settings')();
  TextColumn get valueRanking =>
      text().withDefault(const Constant('{}')).named('value_ranking')();
  TextColumn get allocationAlertsSettings => text()
      .withDefault(const Constant('{}'))
      .named('allocation_alerts_settings')();
  TextColumn get pageSortPreferences =>
      text().withDefault(const Constant('{}')).named('page_sort_preferences')();
  TextColumn get pageDisplaySettings =>
      text().withDefault(const Constant('{}')).named('page_display_settings')();
  TextColumn get screenPreferences =>
      text().withDefault(const Constant('{}')).named('screen_preferences')();

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
    LabelTable,
    ProjectLabelsTable,
    TaskLabelsTable,
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
    // Generic screen/workflow system
    ScreenDefinitions,
    PendingNotifications,
    // New workflow system
    WorkflowDefinitions,
    Workflows,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 14;

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
