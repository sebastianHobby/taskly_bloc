// dart format off
// coverage:ignore-file

// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get counterAppBarTitle => 'Counter';

  @override
  String get editLabel => 'Edit';

  @override
  String get cancelLabel => 'Cancel';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get tasksTitle => 'Tasks';

  @override
  String get labelsTitle => 'Labels';

  @override
  String get valuesTitle => 'Values';

  @override
  String get browseTitle => 'Browse';

  @override
  String get noProjectsFound => 'No projects found.';

  @override
  String get createProjectTooltip => 'Create project';

  @override
  String get createTaskTooltip => 'Create task';

  @override
  String get createLabelTooltip => 'Create label';

  @override
  String get createValueTooltip => 'Create value';

  @override
  String get createLabelOption => 'Create label';

  @override
  String get createValueOption => 'Create value';

  @override
  String get labelTypeLabelHeading => 'Label';

  @override
  String get labelTypeValueHeading => 'Values';

  @override
  String get noLabelsFound => 'No labels found.';

  @override
  String get noValuesFound => 'No values found.';

  @override
  String get genericErrorFallback => 'Something went wrong. Please try again.';

  @override
  String get taskNotFound => 'Task not found.';

  @override
  String get projectNotFound => 'Project not found.';

  @override
  String get labelNotFound => 'Label not found.';

  @override
  String get taskFilterAll => 'All tasks';

  @override
  String get taskFilterActive => 'Active tasks';

  @override
  String get taskFilterCompleted => 'Completed tasks';

  @override
  String get taskSortByName => 'Sort by name';

  @override
  String get taskSortByDeadline => 'Sort by deadline';

  @override
  String get groupSortMenuTitle => 'Group & sort';

  @override
  String get groupSortGroupingLabel => 'Grouping';

  @override
  String get groupSortSortingLabel => 'Sorting';

  @override
  String get groupOptionNone => 'No grouping';

  @override
  String get groupOptionLabels => 'Group by labels';

  @override
  String get groupOptionValues => 'Group by values';

  @override
  String get sortFieldNameLabel => 'Name';

  @override
  String get sortFieldStartDateLabel => 'Start date';

  @override
  String get sortFieldDeadlineDateLabel => 'Deadline date';

  @override
  String get sortFieldNoneLabel => 'None';

  @override
  String get sortSlotPrimaryLabel => 'Primary sort';

  @override
  String get sortSlotSecondaryLabel => 'Secondary sort';

  @override
  String get sortSlotTertiaryLabel => 'Tertiary sort';

  @override
  String get sortMenuTitle => 'Sort';

  @override
  String get sortSortingLabel => 'Sorting';

  @override
  String get sortDirectionLabel => 'Direction';

  @override
  String get sortDirectionAscending => 'Ascending';

  @override
  String get sortDirectionDescending => 'Descending';

  @override
  String get groupingMissingLabels => 'No labels';

  @override
  String get groupingMissingValues => 'No values';

  @override
  String get groupSortApplyButton => 'Apply';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get todayTitle => 'Today';

  @override
  String get upcomingTitle => 'Upcoming';

  @override
  String get nextActionsTitle => 'Next actions';

  @override
  String get taskCreatedSuccessfully => 'Task created successfully.';

  @override
  String get taskUpdatedSuccessfully => 'Task updated successfully.';

  @override
  String get taskDeletedSuccessfully => 'Task deleted successfully.';

  @override
  String get projectCreatedSuccessfully => 'Project created successfully.';

  @override
  String get projectUpdatedSuccessfully => 'Project updated successfully.';

  @override
  String get projectDeletedSuccessfully => 'Project deleted successfully.';

  @override
  String get valueCreatedSuccessfully => 'Value created successfully.';

  @override
  String get valueUpdatedSuccessfully => 'Value updated successfully.';

  @override
  String get valueDeletedSuccessfully => 'Value deleted successfully.';

  @override
  String get labelCreatedSuccessfully => 'Label created successfully.';

  @override
  String get labelUpdatedSuccessfully => 'Label updated successfully.';

  @override
  String get labelDeletedSuccessfully => 'Label deleted successfully.';

  @override
  String get actionCreate => 'Create';

  @override
  String get actionUpdate => 'Update';

  @override
  String get projectFormTitleHint => 'Title';

  @override
  String get projectFormTitleRequired => 'Title is required';

  @override
  String get projectFormTitleEmpty => 'Title must not be empty';

  @override
  String get projectFormTitleTooLong => 'Title must be 120 characters or fewer';

  @override
  String get projectFormDescriptionHint => 'Description';

  @override
  String get projectFormDescriptionTooLong => 'Description is too long';

  @override
  String get projectFormStartDateHint => 'Start date (optional)';

  @override
  String get projectFormDeadlineDateHint => 'Deadline date (optional)';

  @override
  String get projectFormDeadlineAfterStartError => 'Deadline must be after start date';

  @override
  String get projectFormCompletedLabel => 'Completed';

  @override
  String get projectFormValuesLabel => 'Values';

  @override
  String get projectFormLabelsLabel => 'Labels';

  @override
  String get projectFormRepeatRuleHint => 'Repeat rule (RRULE, optional)';

  @override
  String get projectFormRepeatRuleTooLong => 'Repeat rule is too long';

  @override
  String get emptyInboxTitle => 'Your inbox is empty';

  @override
  String get emptyInboxDescription => 'Tasks without a project will appear here';

  @override
  String get emptyTodayTitle => 'Nothing due today';

  @override
  String get emptyTodayDescription => 'Tasks and projects due today will appear here';

  @override
  String get emptyUpcomingTitle => 'Nothing upcoming';

  @override
  String get emptyUpcomingDescription => 'Future tasks and projects will appear here';

  @override
  String get emptyProjectsTitle => 'No projects yet';

  @override
  String get emptyProjectsDescription => 'Create a project to organize your tasks';

  @override
  String get emptyTasksTitle => 'No tasks yet';

  @override
  String get emptyTasksDescription => 'Add a task to get started';

  @override
  String get addTaskAction => 'Add task';

  @override
  String get addProjectAction => 'Add project';

  @override
  String get taskFormNameHint => 'Task Name';

  @override
  String get taskFormDescriptionHint => 'Description';

  @override
  String get taskFormStartDateHint => 'Start date (optional)';

  @override
  String get taskFormDeadlineDateHint => 'Deadline date (optional)';

  @override
  String get taskFormProjectHint => 'Project (optional)';

  @override
  String get taskFormCompletedLabel => 'Completed';

  @override
  String get taskFormNameRequired => 'Name is required';

  @override
  String get taskFormNameEmpty => 'Name must not be empty';

  @override
  String get taskFormNameTooLong => 'Name must be 120 characters or fewer';

  @override
  String get taskFormDescriptionTooLong => 'Description is too long';

  @override
  String get taskFormDeadlineAfterStartError => 'Deadline must be after start date';

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrow => 'Tomorrow';

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String dateInDays(int days) {
    return 'In $days days';
  }

  @override
  String dateDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get repeatsLabel => 'Repeats';

  @override
  String get labelTypeLabel => 'Label';

  @override
  String get labelTypeValue => 'Value';

  @override
  String get retryButton => 'Retry';

  @override
  String get rruleDaily => 'Every day';

  @override
  String get rruleWeekly => 'Every week';

  @override
  String get rruleMonthly => 'Every month';

  @override
  String get rruleYearly => 'Every year';

  @override
  String rruleEveryNDays(int n) {
    return 'Every $n days';
  }

  @override
  String rruleEveryNWeeks(int n) {
    return 'Every $n weeks';
  }

  @override
  String rruleEveryNMonths(int n) {
    return 'Every $n months';
  }

  @override
  String rruleEveryNYears(int n) {
    return 'Every $n years';
  }

  @override
  String get rruleOn => 'on';

  @override
  String get rruleOnDay => 'on day';

  @override
  String rruleTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String get rruleUntil => 'until';

  @override
  String get dayMon => 'Mon';

  @override
  String get dayTue => 'Tue';

  @override
  String get dayWed => 'Wed';

  @override
  String get dayThu => 'Thu';

  @override
  String get dayFri => 'Fri';

  @override
  String get daySat => 'Sat';

  @override
  String get daySun => 'Sun';

  @override
  String get projectDetailTasksTitle => 'Tasks';

  @override
  String projectDetailTaskCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tasks',
      one: '1 task',
      zero: 'No tasks',
    );
    return '$_temp0';
  }

  @override
  String projectDetailCompletedCount(int completed, int total) {
    return '$completed of $total completed';
  }

  @override
  String get projectDetailEmptyTasksDescription => 'Add tasks to this project to track your progress';

  @override
  String get projectStatusCompleted => 'Completed';

  @override
  String get projectStatusActive => 'Active';

  @override
  String get deleteProjectAction => 'Delete project';

  @override
  String get markCompleteAction => 'Mark complete';

  @override
  String get markIncompleteAction => 'Mark incomplete';

  @override
  String get settings => 'Settings';

  @override
  String get retry => 'Retry';

  @override
  String get noTasksToFocusOn => 'No tasks to focus on';

  @override
  String get pinnedTasksSection => 'Pinned Tasks';

  @override
  String get unpinTask => 'Unpin task';

  @override
  String get pinTask => 'Pin task';

  @override
  String taskUrgentExcludedWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count urgent tasks excluded from Focus',
      one: '1 urgent task excluded from Focus',
    );
    return '$_temp0';
  }

  @override
  String get reviewExcludedTasks => 'Review';

  @override
  String get dismissWarning => 'Dismiss';

  @override
  String get recurrenceRepeatTitle => 'Repeat';

  @override
  String get recurrenceNever => 'Never';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get recurrenceEvery => 'Every';

  @override
  String get recurrenceOnDays => 'On days';

  @override
  String get recurrenceEnds => 'Ends';

  @override
  String get recurrenceAfter => 'After';

  @override
  String get recurrenceTimesLabel => 'times';

  @override
  String get recurrenceOn => 'On';

  @override
  String get recurrenceSelectDate => 'Select date';

  @override
  String get recurrenceDoesNotRepeat => 'Does not repeat';

  @override
  String get validationRequired => 'Required';

  @override
  String get validationInvalid => 'Invalid';

  @override
  String get validationMustBeGreaterThanZero => 'Must be > 0';

  @override
  String validationMaxValue(int max) {
    return 'Max $max';
  }

  @override
  String get doneButton => 'Done';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAppearanceSection => 'Appearance';

  @override
  String get settingsLanguageRegionSection => 'Language & Region';

  @override
  String get settingsAdvancedSection => 'Advanced';

  @override
  String get settingsThemeMode => 'Theme Mode';

  @override
  String get settingsThemeModeSubtitle => 'Choose between light, dark, or system theme';

  @override
  String get settingsTextSize => 'Text Size';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Select your preferred language';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsDateFormat => 'Date Format';

  @override
  String get settingsDateFormatShort => 'Short';

  @override
  String get settingsDateFormatMedium => 'Medium';

  @override
  String get settingsDateFormatLong => 'Long';

  @override
  String get settingsDateFormatFull => 'Full';

  @override
  String get settingsDateFormatCustom => 'Custom';

  @override
  String settingsDateFormatExample(String example) {
    return 'Example: $example';
  }

  @override
  String get settingsResetToDefaults => 'Reset to Defaults';

  @override
  String get settingsResetTitle => 'Reset Settings';

  @override
  String get settingsResetConfirmation => 'Are you sure you want to reset all settings to their default values?';

  @override
  String get settingsResetSuccess => 'Settings reset to defaults';

  @override
  String get resetButton => 'Reset';

  @override
  String get sortFieldCreatedDate => 'Created date';

  @override
  String get sortFieldUpdatedDate => 'Updated date';

  @override
  String get sortFieldNextActionPriority => 'Next action priority';

  @override
  String get sortOrderHelp => 'Choose how to order items';

  @override
  String get saveButton => 'Save';

  @override
  String get discardButton => 'Discard';

  @override
  String get unsavedChangesTitle => 'Unsaved Changes';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get personaIdealist => 'Idealist';

  @override
  String get personaIdealistDescription => 'Show me what matters most, not what\'s most urgent.';

  @override
  String get personaIdealistHowItWorks => 'Tasks are selected purely based on your value weights. Deadlines and urgency are completely ignored. Best for: Long-term value alignment without time pressure.';

  @override
  String get personaReflector => 'Reflector';

  @override
  String get personaReflectorDescription => 'Show me values I\'ve been neglecting.';

  @override
  String get personaReflectorHowItWorks => 'Analyzes your recent completions and prioritizes values you\'ve been ignoring. Helps maintain balance when you tend to over-focus on certain areas. Best for: Avoiding burnout on favorite values.';

  @override
  String get personaRealist => 'Realist';

  @override
  String get personaRealistDescription => 'Show me what matters most, but warn me about urgent tasks.';

  @override
  String get personaRealistHowItWorks => 'Respects your value weights while warning about approaching deadlines. Urgent tasks with values get a priority boost. Best for: Most users who want balance.';

  @override
  String get personaFirefighter => 'Firefighter';

  @override
  String get personaFirefighterDescription => 'Show me what\'s urgent right now.';

  @override
  String get personaFirefighterHowItWorks => 'Deadlines come first. All urgent tasks are included, even without values. Prevents missed deadlines at the cost of value alignment. Best for: High-pressure periods with many deadlines.';

  @override
  String get personaCustom => 'Custom';

  @override
  String get personaCustomDescription => 'Let me decide what you show me.';

  @override
  String get personaCustomHowItWorks => 'Full control over all allocation parameters. Configure urgency thresholds, boost multipliers, and display options. Best for: Power users who want fine-grained control.';

  @override
  String get personaRecommended => 'Recommended';

  @override
  String get personaHowItWorks => 'How it works';

  @override
  String get personaSectionTitle => 'How should Focus prioritize tasks?';

  @override
  String get urgencyThresholdsSection => 'Urgency Thresholds';

  @override
  String get taskUrgencyDays => 'Task urgency (days before deadline)';

  @override
  String get projectUrgencyDays => 'Project urgency (days before deadline)';

  @override
  String get displayOptionsSection => 'Display Options';

  @override
  String get showUnassignedTaskCount => 'Show unassigned task count';

  @override
  String get showProjectNextTask => 'Show project next task';

  @override
  String get dailyTaskLimit => 'Daily task limit';

  @override
  String get advancedSettingsSection => 'Advanced Settings';

  @override
  String get urgentTaskHandling => 'Urgent task handling';

  @override
  String get urgentTaskIgnore => 'Ignore';

  @override
  String get urgentTaskIgnoreDescription => 'Urgency has no effect, no warnings';

  @override
  String get urgentTaskWarnOnly => 'Warn only';

  @override
  String get urgentTaskWarnOnlyDescription => 'Urgent tasks excluded but show warnings';

  @override
  String get urgentTaskIncludeAll => 'Include all';

  @override
  String get urgentTaskIncludeAllDescription => 'All urgent tasks are included';

  @override
  String get valueAlignedUrgencyBoost => 'Value-aligned urgency boost';

  @override
  String get enableNeglectWeighting => 'Enable neglect weighting';

  @override
  String get reflectorLookbackDays => 'Reflector lookback (days)';

  @override
  String get neglectInfluence => 'Neglect influence (0-1)';

  @override
  String get switchedToCustomMode => 'Switched to Custom mode';

  @override
  String get allocationSettingsTitle => 'Allocation Settings';

  @override
  String get saveLabel => 'Save';

  @override
  String get valueRankingsTitle => 'Value Rankings';

  @override
  String get valueRankingsDescription => 'Drag to reorder. Higher values get more focus tasks.';

  @override
  String get noValuesForRanking => 'No values found. Create values in the Values screen.';

  @override
  String get weightLabel => 'Weight';

  @override
  String get notRankedDragToRank => 'Not ranked - drag to rank';

  @override
  String get recommendedNextActionLabel => 'Recommended Next Action';

  @override
  String get startLabel => 'Start';

  @override
  String get projectNextTaskPrefix => '→ Next:';

  @override
  String taskPinnedToFocus(String taskName) {
    return '\'$taskName\' pinned to Focus';
  }

  @override
  String deadlineFormatDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Due in $days days',
      one: 'Due tomorrow',
      zero: 'Due today',
    );
    return '$_temp0';
  }

  @override
  String get deadlineOverdue => 'Overdue';

  @override
  String get reflectorBuildingHistory => 'Building your history...';

  @override
  String reflectorHistoryExplanation(int count, int days) {
    return 'Reflector works best with more data. You have $count completions in the last $days days. Using value weights for now.';
  }

  @override
  String get targetLabel => 'Target';

  @override
  String get actualLabel => 'Actual';

  @override
  String get gapLabel => 'Gap';

  @override
  String valueActivityCounts(int taskCount, int projectCount) {
    return '$taskCount tasks · $projectCount projects';
  }

  @override
  String weekTrendTitle(int weeks) {
    return '$weeks-Week Trend';
  }

  @override
  String get noTrendData => 'No trend data yet';

  @override
  String get activitySectionTitle => 'Activity';

  @override
  String activeTasksCount(int count) {
    return '$count active tasks';
  }

  @override
  String projectsCount(int count) {
    return '$count projects';
  }

  @override
  String get unassignedWorkTitle => 'Unassigned Work';

  @override
  String get valuesGatewayTitle => 'Prioritize What Matters';

  @override
  String get valuesGatewayDescription => 'Focus uses your personal values to recommend which tasks deserve your attention today.\n\nDefine what\'s important to you—like Health, Family, Career—and Focus will help you spend time on what truly matters.';

  @override
  String get setUpMyValues => 'Set Up My Values';

  @override
  String get myDayTitle => 'My Day';

  @override
  String get myDayAlertBannerSingular => '1 item outside Focus';

  @override
  String myDayAlertBannerPlural(int count) {
    return '$count items outside Focus';
  }

  @override
  String get myDayAlertBannerReview => 'Review';

  @override
  String get excludedSectionNeedsAlignment => 'Needs Alignment';

  @override
  String get excludedSectionWorthConsidering => 'Worth Considering';

  @override
  String get excludedSectionOverdueAttention => 'Overdue Attention';

  @override
  String get excludedSectionActiveFires => 'Active Fires';

  @override
  String get excludedSectionOutsideFocus => 'Outside Focus';

  @override
  String get alertTypeUrgent => 'Urgent tasks';

  @override
  String get alertTypeOverdue => 'Overdue tasks';

  @override
  String get alertTypeNoValue => 'Tasks without values';

  @override
  String get alertTypeLowPriority => 'Low priority tasks';

  @override
  String get alertTypeQuotaFull => 'Quota exceeded tasks';

  @override
  String get alertSeverityCritical => 'Critical';

  @override
  String get alertSeverityWarning => 'Warning';

  @override
  String get alertSeverityNotice => 'Notice';

  @override
  String get basicInfoSection => 'Basic Information';

  @override
  String get personaSectionSubtitle => 'Choose a persona to control how tasks are prioritized';

  @override
  String get taskLimitSection => 'Task Limit';

  @override
  String get sourceFilterSection => 'Narrow Source';

  @override
  String get sourceFilterSubtitle => 'Limit which tasks are considered';

  @override
  String get saving => 'Saving...';

  @override
  String get saveFocusScreen => 'Save Focus Screen';

  @override
  String get maxTasksLabel => 'Maximum Tasks';

  @override
  String get showExcludedSection => 'Show excluded section';

  @override
  String get showExcludedSectionSubtitle => 'Display excluded tasks at the bottom';

  @override
  String get urgentTaskBehaviorLabel => 'Urgent task handling';

  @override
  String get urgentBehaviorIgnore => 'Ignore urgent tasks';

  @override
  String get urgentBehaviorWarnOnly => 'Warn about urgent tasks';

  @override
  String get urgentBehaviorIncludeAll => 'Include all urgent tasks';

  @override
  String daysFormat(int count) {
    return '$count days';
  }
}
