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
}
