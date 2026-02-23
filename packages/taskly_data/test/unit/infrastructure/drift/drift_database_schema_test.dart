@Tags(['unit'])
library;

import '../../../helpers/test_imports.dart';
import '../../../helpers/test_db.dart';

import 'package:taskly_data/db.dart';

void main() {
  setUpAll(setUpAllTestEnvironment);
  setUp(setUpTestEnvironment);

  group('AppDatabase schema wiring', () {
    testSafe(
      'exposes expected schema version and migration strategy',
      () async {
        final db = createAutoClosingDb();

        expect(db.schemaVersion, equals(22));
        expect(db.migration, isNotNull);
        expect(ExceptionType.skip.name, equals('skip'));
        expect(ExceptionType.reschedule.name, equals('reschedule'));
      },
    );

    testSafe(
      'table definitions expose expected names and key columns',
      () async {
        final db = createAutoClosingDb();

        expect(db.projectTable.tableName, equals('projects'));
        expect(db.projectTable.id.name, equals('id'));
        expect(db.projectTable.primaryValueId.name, equals('primary_value_id'));
        expect(db.projectTable.priority.name, equals('priority'));
        expect(db.projectTable.isPinned.name, equals('pinned'));

        expect(db.taskTable.tableName, equals('tasks'));
        expect(db.taskTable.id.name, equals('id'));
        expect(db.taskTable.projectId.name, equals('project_id'));
        expect(
          db.taskTable.overridePrimaryValueId.name,
          equals('override_primary_value_id'),
        );
        expect(
          db.taskTable.overrideSecondaryValueId.name,
          equals('override_secondary_value_id'),
        );
        expect(db.taskTable.reminderKind.name, equals('reminder_kind'));
        expect(db.taskTable.reminderAtUtc.name, equals('reminder_at_utc'));
        expect(
          db.taskTable.reminderMinutesBeforeDue.name,
          equals('reminder_minutes_before_due'),
        );
        expect(db.taskTable.isPinned.name, equals('pinned'));

        expect(db.valueTable.tableName, equals('values'));
        expect(db.valueTable.id.name, equals('id'));
        expect(db.valueTable.color.name, equals('color'));
        expect(db.valueTable.iconName.name, equals('icon_name'));
        expect(db.valueTable.priority.name, equals('priority'));
        expect(db.valueTable.customConstraints, isNotEmpty);

        expect(
          db.valueRatingsWeeklyTable.tableName,
          equals('value_ratings_weekly'),
        );
        expect(db.valueRatingsWeeklyTable.valueId.name, equals('value_id'));
        expect(db.valueRatingsWeeklyTable.weekStart.name, equals('week_start'));
        expect(db.valueRatingsWeeklyTable.rating.name, equals('rating'));
        expect(db.valueRatingsWeeklyTable.uniqueKeys, isNotEmpty);
      },
    );

    testSafe('feature tables expose expected fields and unique keys', () async {
      final db = createAutoClosingDb();

      expect(db.userProfileTable.tableName, equals('user_profiles'));
      expect(
        db.userProfileTable.settingsOverrides.name,
        equals('settings_overrides'),
      );

      expect(db.myDayDaysTable.tableName, equals('my_day_days'));
      expect(db.myDayDaysTable.dayUtc.name, equals('day_utc'));
      expect(
        db.myDayDaysTable.ritualCompletedAt.name,
        equals('ritual_completed_at'),
      );

      expect(db.myDayPicksTable.tableName, equals('my_day_picks'));
      expect(db.myDayPicksTable.dayId.name, equals('day_id'));
      expect(db.myDayPicksTable.taskId.name, equals('task_id'));
      expect(db.myDayPicksTable.routineId.name, equals('routine_id'));
      expect(db.myDayPicksTable.bucket.name, equals('bucket'));
      expect(db.myDayPicksTable.reasonCodes.name, equals('reason_codes'));

      expect(
        db.taskCompletionHistoryTable.tableName,
        equals('task_completion_history'),
      );
      expect(db.taskCompletionHistoryTable.taskId.name, equals('task_id'));
      expect(
        db.taskCompletionHistoryTable.occurrenceDate.name,
        equals('occurrence_date'),
      );
      expect(
        db.taskCompletionHistoryTable.originalOccurrenceDate.name,
        equals('original_occurrence_date'),
      );
      expect(db.taskCompletionHistoryTable.uniqueKeys, isNotEmpty);

      expect(db.taskSnoozeEventsTable.tableName, equals('task_snooze_events'));
      expect(db.taskSnoozeEventsTable.taskId.name, equals('task_id'));
      expect(db.taskSnoozeEventsTable.snoozedAt.name, equals('snoozed_at'));
      expect(
        db.taskSnoozeEventsTable.snoozedUntil.name,
        equals('snoozed_until'),
      );

      expect(
        db.projectCompletionHistoryTable.tableName,
        equals('project_completion_history'),
      );
      expect(
        db.projectCompletionHistoryTable.projectId.name,
        equals('project_id'),
      );
      expect(db.projectCompletionHistoryTable.uniqueKeys, isNotEmpty);

      expect(
        db.taskRecurrenceExceptionsTable.tableName,
        equals('task_recurrence_exceptions'),
      );
      expect(db.taskRecurrenceExceptionsTable.taskId.name, equals('task_id'));
      expect(
        db.taskRecurrenceExceptionsTable.exceptionType.name,
        equals('exception_type'),
      );
      expect(db.taskRecurrenceExceptionsTable.newDate.name, equals('new_date'));
      expect(db.taskRecurrenceExceptionsTable.uniqueKeys, isNotEmpty);

      expect(
        db.projectRecurrenceExceptionsTable.tableName,
        equals('project_recurrence_exceptions'),
      );
      expect(
        db.projectRecurrenceExceptionsTable.projectId.name,
        equals('project_id'),
      );
      expect(
        db.projectRecurrenceExceptionsTable.newDeadline.name,
        equals('new_deadline'),
      );
      expect(db.projectRecurrenceExceptionsTable.uniqueKeys, isNotEmpty);
    });

    testSafe('checklist and routine tables expose expected columns', () async {
      final db = createAutoClosingDb();

      expect(
        db.projectAnchorStateTable.tableName,
        equals('project_anchor_state'),
      );
      expect(db.projectAnchorStateTable.projectId.name, equals('project_id'));

      expect(
        db.taskChecklistItemsTable.tableName,
        equals('task_checklist_items'),
      );
      expect(db.taskChecklistItemsTable.taskId.name, equals('task_id'));
      expect(db.taskChecklistItemsTable.sortIndex.name, equals('sort_index'));

      expect(
        db.taskChecklistItemStateTable.tableName,
        equals('task_checklist_item_state'),
      );
      expect(db.taskChecklistItemStateTable.taskId.name, equals('task_id'));
      expect(
        db.taskChecklistItemStateTable.checklistItemId.name,
        equals('checklist_item_id'),
      );
      expect(
        db.taskChecklistItemStateTable.occurrenceDate.name,
        equals('occurrence_date'),
      );

      expect(db.routinesTable.tableName, equals('routines'));
      expect(db.routinesTable.projectId.name, equals('project_id'));
      expect(db.routinesTable.periodType.name, equals('period_type'));
      expect(db.routinesTable.scheduleMode.name, equals('schedule_mode'));
      expect(db.routinesTable.targetCount.name, equals('target_count'));
      expect(db.routinesTable.scheduleDays.name, equals('schedule_days'));
      expect(
        db.routinesTable.scheduleMonthDays.name,
        equals('schedule_month_days'),
      );
      expect(
        db.routinesTable.scheduleTimeMinutes.name,
        equals('schedule_time_minutes'),
      );
      expect(db.routinesTable.minSpacingDays.name, equals('min_spacing_days'));
      expect(db.routinesTable.restDayBuffer.name, equals('rest_day_buffer'));
      expect(db.routinesTable.pausedUntil.name, equals('paused_until'));

      expect(
        db.routineChecklistItemsTable.tableName,
        equals('routine_checklist_items'),
      );
      expect(
        db.routineChecklistItemsTable.routineId.name,
        equals('routine_id'),
      );
      expect(
        db.routineChecklistItemsTable.sortIndex.name,
        equals('sort_index'),
      );

      expect(
        db.routineChecklistItemStateTable.tableName,
        equals('routine_checklist_item_state'),
      );
      expect(
        db.routineChecklistItemStateTable.routineId.name,
        equals('routine_id'),
      );
      expect(
        db.routineChecklistItemStateTable.checklistItemId.name,
        equals('checklist_item_id'),
      );
      expect(
        db.routineChecklistItemStateTable.periodType.name,
        equals('period_type'),
      );
      expect(
        db.routineChecklistItemStateTable.windowKey.name,
        equals('window_key'),
      );

      expect(db.checklistEventsTable.tableName, equals('checklist_events'));
      expect(db.checklistEventsTable.parentType.name, equals('parent_type'));
      expect(db.checklistEventsTable.parentId.name, equals('parent_id'));
      expect(db.checklistEventsTable.eventType.name, equals('event_type'));
      expect(db.checklistEventsTable.metricsJson.name, equals('metrics_json'));

      expect(
        db.routineCompletionsTable.tableName,
        equals('routine_completions'),
      );
      expect(db.routineCompletionsTable.routineId.name, equals('routine_id'));
      expect(
        db.routineCompletionsTable.completedDayLocal.name,
        equals('completed_day_local'),
      );
      expect(
        db.routineCompletionsTable.completedTimeLocalMinutes.name,
        equals('completed_time_local_minutes'),
      );

      expect(db.routineSkipsTable.tableName, equals('routine_skips'));
      expect(db.routineSkipsTable.routineId.name, equals('routine_id'));
      expect(db.routineSkipsTable.periodType.name, equals('period_type'));
      expect(db.routineSkipsTable.periodKey.name, equals('period_key'));
    });

    testSafe(
      'analytics, journal, tracker, notification and attention tables exist',
      () async {
        final db = createAutoClosingDb();

        expect(
          db.analyticsSnapshots.actualTableName,
          equals('analytics_snapshots'),
        );
        expect(
          db.analyticsCorrelations.actualTableName,
          equals('analytics_correlations'),
        );
        expect(
          db.analyticsInsights.actualTableName,
          equals('analytics_insights'),
        );

        expect(db.journalEntries.actualTableName, equals('journal_entries'));
        expect(db.trackerGroups.actualTableName, equals('tracker_groups'));
        expect(
          db.trackerDefinitions.actualTableName,
          equals('tracker_definitions'),
        );
        expect(
          db.trackerPreferences.actualTableName,
          equals('tracker_preferences'),
        );
        expect(
          db.trackerDefinitionChoices.actualTableName,
          equals('tracker_definition_choices'),
        );
        expect(db.trackerEvents.actualTableName, equals('tracker_events'));
        expect(db.trackerStateDay.actualTableName, equals('tracker_state_day'));
        expect(
          db.trackerStateEntry.actualTableName,
          equals('tracker_state_entry'),
        );
        expect(
          db.pendingNotifications.actualTableName,
          equals('pending_notifications'),
        );
        expect(db.syncIssues.actualTableName, equals('sync_issues'));

        expect(db.attentionRules.actualTableName, equals('attention_rules'));
        expect(
          db.attentionResolutions.actualTableName,
          equals('attention_resolutions'),
        );
        expect(
          db.attentionRuleRuntimeStates.actualTableName,
          equals('attention_rule_runtime_state'),
        );
      },
    );
  });
}
