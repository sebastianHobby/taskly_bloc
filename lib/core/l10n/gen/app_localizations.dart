// dart format off
// coverage:ignore-file
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es')
  ];

  /// Text shown in the AppBar of the Counter Page
  ///
  /// In en, this message translates to:
  /// **'Counter'**
  String get counterAppBarTitle;

  /// Generic edit action label
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editLabel;

  /// Generic cancel action label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelLabel;

  /// Generic delete action label
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// Title for the Projects section
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projectsTitle;

  /// Title for the Tasks section
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// Title for the Labels section
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get labelsTitle;

  /// Title/label for the Values section
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get valuesTitle;

  /// Title/label for the Browse navigation destination
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get browseTitle;

  /// Empty state shown when there are no projects
  ///
  /// In en, this message translates to:
  /// **'No projects found.'**
  String get noProjectsFound;

  /// Tooltip for the create project floating action button
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get createProjectTooltip;

  /// Tooltip for the create task floating action button
  ///
  /// In en, this message translates to:
  /// **'Create task'**
  String get createTaskTooltip;

  /// Tooltip for the create label floating action button
  ///
  /// In en, this message translates to:
  /// **'Create label'**
  String get createLabelTooltip;

  /// Tooltip for the create value floating action button
  ///
  /// In en, this message translates to:
  /// **'Create value'**
  String get createValueTooltip;

  /// Option text for creating a label
  ///
  /// In en, this message translates to:
  /// **'Create label'**
  String get createLabelOption;

  /// Option text for creating a value
  ///
  /// In en, this message translates to:
  /// **'Create value'**
  String get createValueOption;

  /// Heading shown above the list of labels
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelTypeLabelHeading;

  /// Heading shown above the list of values
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get labelTypeValueHeading;

  /// Empty state shown when there are no labels
  ///
  /// In en, this message translates to:
  /// **'No labels found.'**
  String get noLabelsFound;

  /// Empty state shown when there are no values
  ///
  /// In en, this message translates to:
  /// **'No values found.'**
  String get noValuesFound;

  /// Fallback error shown for unexpected errors
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get genericErrorFallback;

  /// Error shown when a task cannot be found
  ///
  /// In en, this message translates to:
  /// **'Task not found.'**
  String get taskNotFound;

  /// Error shown when a project cannot be found
  ///
  /// In en, this message translates to:
  /// **'Project not found.'**
  String get projectNotFound;

  /// Error shown when a label cannot be found
  ///
  /// In en, this message translates to:
  /// **'Label not found.'**
  String get labelNotFound;

  /// Task overview filter option to show all tasks
  ///
  /// In en, this message translates to:
  /// **'All tasks'**
  String get taskFilterAll;

  /// Task overview filter option to show only active (not completed) tasks
  ///
  /// In en, this message translates to:
  /// **'Active tasks'**
  String get taskFilterActive;

  /// Task overview filter option to show only completed tasks
  ///
  /// In en, this message translates to:
  /// **'Completed tasks'**
  String get taskFilterCompleted;

  /// Task overview sort option to sort tasks by name
  ///
  /// In en, this message translates to:
  /// **'Sort by name'**
  String get taskSortByName;

  /// Task overview sort option to sort tasks by deadline date
  ///
  /// In en, this message translates to:
  /// **'Sort by deadline'**
  String get taskSortByDeadline;

  /// Title for the group and sort bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Group & sort'**
  String get groupSortMenuTitle;

  /// Label shown above grouping options
  ///
  /// In en, this message translates to:
  /// **'Grouping'**
  String get groupSortGroupingLabel;

  /// Label shown above sorting controls
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get groupSortSortingLabel;

  /// Grouping option to disable grouping
  ///
  /// In en, this message translates to:
  /// **'No grouping'**
  String get groupOptionNone;

  /// Grouping option to organize items by associated labels
  ///
  /// In en, this message translates to:
  /// **'Group by labels'**
  String get groupOptionLabels;

  /// Grouping option to organize items by associated values
  ///
  /// In en, this message translates to:
  /// **'Group by values'**
  String get groupOptionValues;

  /// Label for the name sort field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortFieldNameLabel;

  /// Label for the start date sort field
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get sortFieldStartDateLabel;

  /// Label for the deadline date sort field
  ///
  /// In en, this message translates to:
  /// **'Deadline date'**
  String get sortFieldDeadlineDateLabel;

  /// Option label for clearing a sort slot
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get sortFieldNoneLabel;

  /// Label for the primary sort dropdown
  ///
  /// In en, this message translates to:
  /// **'Primary sort'**
  String get sortSlotPrimaryLabel;

  /// Label for the secondary sort dropdown
  ///
  /// In en, this message translates to:
  /// **'Secondary sort'**
  String get sortSlotSecondaryLabel;

  /// Label for the tertiary sort dropdown
  ///
  /// In en, this message translates to:
  /// **'Tertiary sort'**
  String get sortSlotTertiaryLabel;

  /// Title for the sort bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sortMenuTitle;

  /// Label shown above sorting controls
  ///
  /// In en, this message translates to:
  /// **'Sorting'**
  String get sortSortingLabel;

  /// Label for the sort direction dropdown
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get sortDirectionLabel;

  /// Label for ascending sort direction
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get sortDirectionAscending;

  /// Label for descending sort direction
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get sortDirectionDescending;

  /// Group header shown when an item has no labels
  ///
  /// In en, this message translates to:
  /// **'No labels'**
  String get groupingMissingLabels;

  /// Group header shown when an item has no values
  ///
  /// In en, this message translates to:
  /// **'No values'**
  String get groupingMissingValues;

  /// Button text for applying group & sort changes
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get groupSortApplyButton;

  /// Title for the Inbox section
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// Title for the Today section
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayTitle;

  /// Title for the Upcoming section
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcomingTitle;

  /// Title for the Next actions section
  ///
  /// In en, this message translates to:
  /// **'Next actions'**
  String get nextActionsTitle;

  /// Snackbar message shown after creating a task
  ///
  /// In en, this message translates to:
  /// **'Task created successfully.'**
  String get taskCreatedSuccessfully;

  /// Snackbar message shown after updating a task
  ///
  /// In en, this message translates to:
  /// **'Task updated successfully.'**
  String get taskUpdatedSuccessfully;

  /// Snackbar message shown after deleting a task
  ///
  /// In en, this message translates to:
  /// **'Task deleted successfully.'**
  String get taskDeletedSuccessfully;

  /// Snackbar message shown after creating a project
  ///
  /// In en, this message translates to:
  /// **'Project created successfully.'**
  String get projectCreatedSuccessfully;

  /// Snackbar message shown after updating a project
  ///
  /// In en, this message translates to:
  /// **'Project updated successfully.'**
  String get projectUpdatedSuccessfully;

  /// Snackbar message shown after deleting a project
  ///
  /// In en, this message translates to:
  /// **'Project deleted successfully.'**
  String get projectDeletedSuccessfully;

  /// Snackbar message shown after creating a value
  ///
  /// In en, this message translates to:
  /// **'Value created successfully.'**
  String get valueCreatedSuccessfully;

  /// Snackbar message shown after updating a value
  ///
  /// In en, this message translates to:
  /// **'Value updated successfully.'**
  String get valueUpdatedSuccessfully;

  /// Snackbar message shown after deleting a value
  ///
  /// In en, this message translates to:
  /// **'Value deleted successfully.'**
  String get valueDeletedSuccessfully;

  /// Snackbar message shown after creating a label
  ///
  /// In en, this message translates to:
  /// **'Label created successfully.'**
  String get labelCreatedSuccessfully;

  /// Snackbar message shown after updating a label
  ///
  /// In en, this message translates to:
  /// **'Label updated successfully.'**
  String get labelUpdatedSuccessfully;

  /// Snackbar message shown after deleting a label
  ///
  /// In en, this message translates to:
  /// **'Label deleted successfully.'**
  String get labelDeletedSuccessfully;

  /// Generic tooltip/label for a create action
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get actionCreate;

  /// Generic tooltip/label for an update action
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get actionUpdate;

  /// Hint text for the project title field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get projectFormTitleHint;

  /// Validation error shown when the project title is missing
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get projectFormTitleRequired;

  /// Validation error shown when the project title is empty
  ///
  /// In en, this message translates to:
  /// **'Title must not be empty'**
  String get projectFormTitleEmpty;

  /// Validation error shown when the project title is too long
  ///
  /// In en, this message translates to:
  /// **'Title must be 120 characters or fewer'**
  String get projectFormTitleTooLong;

  /// Hint text for the project description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectFormDescriptionHint;

  /// Validation error shown when the project description is too long
  ///
  /// In en, this message translates to:
  /// **'Description is too long'**
  String get projectFormDescriptionTooLong;

  /// Hint text for the optional project start date field
  ///
  /// In en, this message translates to:
  /// **'Start date (optional)'**
  String get projectFormStartDateHint;

  /// Hint text for the optional project deadline date field
  ///
  /// In en, this message translates to:
  /// **'Deadline date (optional)'**
  String get projectFormDeadlineDateHint;

  /// Validation error shown when the deadline is before the start date
  ///
  /// In en, this message translates to:
  /// **'Deadline must be after start date'**
  String get projectFormDeadlineAfterStartError;

  /// Label for the completed checkbox in the project form
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectFormCompletedLabel;

  /// Label for the values selection chips in the project form
  ///
  /// In en, this message translates to:
  /// **'Values'**
  String get projectFormValuesLabel;

  /// Label for the labels selection chips in the project form
  ///
  /// In en, this message translates to:
  /// **'Labels'**
  String get projectFormLabelsLabel;

  /// Hint text for the optional RRULE repeat rule field
  ///
  /// In en, this message translates to:
  /// **'Repeat rule (RRULE, optional)'**
  String get projectFormRepeatRuleHint;

  /// Validation error shown when the RRULE repeat rule is too long
  ///
  /// In en, this message translates to:
  /// **'Repeat rule is too long'**
  String get projectFormRepeatRuleTooLong;

  /// Title shown when the inbox has no tasks
  ///
  /// In en, this message translates to:
  /// **'Your inbox is empty'**
  String get emptyInboxTitle;

  /// Description shown when the inbox has no tasks
  ///
  /// In en, this message translates to:
  /// **'Tasks without a project will appear here'**
  String get emptyInboxDescription;

  /// Title shown when there are no tasks or projects due today
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get emptyTodayTitle;

  /// Description shown when there are no tasks or projects due today
  ///
  /// In en, this message translates to:
  /// **'Tasks and projects due today will appear here'**
  String get emptyTodayDescription;

  /// Title shown when there are no upcoming tasks or projects
  ///
  /// In en, this message translates to:
  /// **'Nothing upcoming'**
  String get emptyUpcomingTitle;

  /// Description shown when there are no upcoming tasks or projects
  ///
  /// In en, this message translates to:
  /// **'Future tasks and projects will appear here'**
  String get emptyUpcomingDescription;

  /// Title shown when there are no projects
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get emptyProjectsTitle;

  /// Description shown when there are no projects
  ///
  /// In en, this message translates to:
  /// **'Create a project to organize your tasks'**
  String get emptyProjectsDescription;

  /// Title shown when there are no tasks
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get emptyTasksTitle;

  /// Description shown when there are no tasks
  ///
  /// In en, this message translates to:
  /// **'Add a task to get started'**
  String get emptyTasksDescription;

  /// Action button text for adding a task
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get addTaskAction;

  /// Action button text for adding a project
  ///
  /// In en, this message translates to:
  /// **'Add project'**
  String get addProjectAction;

  /// Hint text for the task name field
  ///
  /// In en, this message translates to:
  /// **'Task Name'**
  String get taskFormNameHint;

  /// Hint text for the task description field
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskFormDescriptionHint;

  /// Hint text for the task start date field
  ///
  /// In en, this message translates to:
  /// **'Start date (optional)'**
  String get taskFormStartDateHint;

  /// Hint text for the task deadline date field
  ///
  /// In en, this message translates to:
  /// **'Deadline date (optional)'**
  String get taskFormDeadlineDateHint;

  /// Hint text for the task project field
  ///
  /// In en, this message translates to:
  /// **'Project (optional)'**
  String get taskFormProjectHint;

  /// Label for the completed checkbox in the task form
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskFormCompletedLabel;

  /// Validation error when task name is missing
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get taskFormNameRequired;

  /// Validation error when task name is empty
  ///
  /// In en, this message translates to:
  /// **'Name must not be empty'**
  String get taskFormNameEmpty;

  /// Validation error when task name is too long
  ///
  /// In en, this message translates to:
  /// **'Name must be 120 characters or fewer'**
  String get taskFormNameTooLong;

  /// Validation error when task description is too long
  ///
  /// In en, this message translates to:
  /// **'Description is too long'**
  String get taskFormDescriptionTooLong;

  /// Validation error when deadline is before start date
  ///
  /// In en, this message translates to:
  /// **'Deadline must be after start date'**
  String get taskFormDeadlineAfterStartError;

  /// Relative date label for today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// Relative date label for tomorrow
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dateTomorrow;

  /// Relative date label for yesterday
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// Relative date label for days in the future
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String dateInDays(int days);

  /// Relative date label for days in the past
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String dateDaysAgo(int days);

  /// Label shown for repeating tasks/projects
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeatsLabel;

  /// Display name for label type
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelTypeLabel;

  /// Display name for value type
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get labelTypeValue;

  /// Text for retry action button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// RRULE frequency: daily
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get rruleDaily;

  /// RRULE frequency: weekly
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get rruleWeekly;

  /// RRULE frequency: monthly
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get rruleMonthly;

  /// RRULE frequency: yearly
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get rruleYearly;

  /// RRULE frequency: every n days
  ///
  /// In en, this message translates to:
  /// **'Every {n} days'**
  String rruleEveryNDays(int n);

  /// RRULE frequency: every n weeks
  ///
  /// In en, this message translates to:
  /// **'Every {n} weeks'**
  String rruleEveryNWeeks(int n);

  /// RRULE frequency: every n months
  ///
  /// In en, this message translates to:
  /// **'Every {n} months'**
  String rruleEveryNMonths(int n);

  /// RRULE frequency: every n years
  ///
  /// In en, this message translates to:
  /// **'Every {n} years'**
  String rruleEveryNYears(int n);

  /// RRULE: preposition for days
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get rruleOn;

  /// RRULE: preposition for day of month
  ///
  /// In en, this message translates to:
  /// **'on day'**
  String get rruleOnDay;

  /// RRULE: number of occurrences
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String rruleTimes(int count);

  /// RRULE: preposition for end date
  ///
  /// In en, this message translates to:
  /// **'until'**
  String get rruleUntil;

  /// Abbreviated day name: Monday
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get dayMon;

  /// Abbreviated day name: Tuesday
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get dayTue;

  /// Abbreviated day name: Wednesday
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get dayWed;

  /// Abbreviated day name: Thursday
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get dayThu;

  /// Abbreviated day name: Friday
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get dayFri;

  /// Abbreviated day name: Saturday
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get daySat;

  /// Abbreviated day name: Sunday
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get daySun;

  /// Title for tasks section in project detail
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get projectDetailTasksTitle;

  /// Task count display in project detail
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No tasks} =1{1 task} other{{count} tasks}}'**
  String projectDetailTaskCount(int count);

  /// Completed task count display
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} completed'**
  String projectDetailCompletedCount(int completed, int total);

  /// Description shown when project has no tasks
  ///
  /// In en, this message translates to:
  /// **'Add tasks to this project to track your progress'**
  String get projectDetailEmptyTasksDescription;

  /// Status badge for completed projects
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectStatusCompleted;

  /// Status badge for active projects
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get projectStatusActive;

  /// Menu action to delete a project
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get deleteProjectAction;

  /// Menu action to mark a project complete
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markCompleteAction;

  /// Menu action to mark a project incomplete
  ///
  /// In en, this message translates to:
  /// **'Mark incomplete'**
  String get markIncompleteAction;

  /// Settings label
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Retry action label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Empty state message when no tasks are allocated
  ///
  /// In en, this message translates to:
  /// **'No tasks to focus on'**
  String get noTasksToFocusOn;

  /// Section title for pinned tasks
  ///
  /// In en, this message translates to:
  /// **'Pinned Tasks'**
  String get pinnedTasksSection;

  /// Action to remove pin from a task
  ///
  /// In en, this message translates to:
  /// **'Unpin task'**
  String get unpinTask;

  /// Action to pin a task to top
  ///
  /// In en, this message translates to:
  /// **'Pin task'**
  String get pinTask;

  /// Warning message for urgent tasks excluded from Focus screen
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 urgent task excluded from Focus} other{{count} urgent tasks excluded from Focus}}'**
  String taskUrgentExcludedWarning(int count);

  /// Action to review excluded urgent tasks
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewExcludedTasks;

  /// Action to dismiss a warning
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismissWarning;

  /// Title for recurrence picker dialog
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recurrenceRepeatTitle;

  /// Recurrence option: no repeat
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get recurrenceNever;

  /// Recurrence option: daily
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// Recurrence option: weekly
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// Recurrence option: monthly
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// Recurrence option: yearly
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// Prefix for interval: Every X days
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get recurrenceEvery;

  /// Label for weekday selection in weekly recurrence
  ///
  /// In en, this message translates to:
  /// **'On days'**
  String get recurrenceOnDays;

  /// Label for end condition section
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get recurrenceEnds;

  /// End condition: after X times
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get recurrenceAfter;

  /// Suffix for occurrence count
  ///
  /// In en, this message translates to:
  /// **'times'**
  String get recurrenceTimesLabel;

  /// End condition: on specific date
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get recurrenceOn;

  /// Placeholder for date selection
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get recurrenceSelectDate;

  /// Text shown when no recurrence is set
  ///
  /// In en, this message translates to:
  /// **'Does not repeat'**
  String get recurrenceDoesNotRepeat;

  /// Validation error: field is required
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get validationRequired;

  /// Validation error: value is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get validationInvalid;

  /// Validation error: value must be greater than zero
  ///
  /// In en, this message translates to:
  /// **'Must be > 0'**
  String get validationMustBeGreaterThanZero;

  /// Validation error: value exceeds maximum
  ///
  /// In en, this message translates to:
  /// **'Max {max}'**
  String validationMaxValue(int max);

  /// Done action button
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// Title for settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section: appearance
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearanceSection;

  /// Settings section: language and region
  ///
  /// In en, this message translates to:
  /// **'Language & Region'**
  String get settingsLanguageRegionSection;

  /// Settings section: advanced options
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get settingsAdvancedSection;

  /// Theme mode setting label
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get settingsThemeMode;

  /// Theme mode setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose between light, dark, or system theme'**
  String get settingsThemeModeSubtitle;

  /// Text size setting label
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get settingsTextSize;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Language setting subtitle
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get settingsLanguageSubtitle;

  /// Language option: system default
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsLanguageSystem;

  /// Date format setting label
  ///
  /// In en, this message translates to:
  /// **'Date Format'**
  String get settingsDateFormat;

  /// Date format option: short
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get settingsDateFormatShort;

  /// Date format option: medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get settingsDateFormatMedium;

  /// Date format option: long
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get settingsDateFormatLong;

  /// Date format option: full
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get settingsDateFormatFull;

  /// Date format option: custom
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get settingsDateFormatCustom;

  /// Date format example display
  ///
  /// In en, this message translates to:
  /// **'Example: {example}'**
  String settingsDateFormatExample(String example);

  /// Button to reset settings
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get settingsResetToDefaults;

  /// Dialog title for reset confirmation
  ///
  /// In en, this message translates to:
  /// **'Reset Settings'**
  String get settingsResetTitle;

  /// Reset confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset all settings to their default values?'**
  String get settingsResetConfirmation;

  /// Success message after resetting settings
  ///
  /// In en, this message translates to:
  /// **'Settings reset to defaults'**
  String get settingsResetSuccess;

  /// Reset action button
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetButton;

  /// Sort field: created date
  ///
  /// In en, this message translates to:
  /// **'Created date'**
  String get sortFieldCreatedDate;

  /// Sort field: updated date
  ///
  /// In en, this message translates to:
  /// **'Updated date'**
  String get sortFieldUpdatedDate;

  /// Sort field: next action priority
  ///
  /// In en, this message translates to:
  /// **'Next action priority'**
  String get sortFieldNextActionPriority;

  /// Help text for sort configuration
  ///
  /// In en, this message translates to:
  /// **'Choose how to order items'**
  String get sortOrderHelp;

  /// Save action button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// Discard action button
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardButton;

  /// Dialog title for unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChangesTitle;

  /// Confirm action button
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// Name of the Idealist allocation persona
  ///
  /// In en, this message translates to:
  /// **'Idealist'**
  String get personaIdealist;

  /// Short description of the Idealist persona
  ///
  /// In en, this message translates to:
  /// **'Show me what matters most, not what\'s most urgent.'**
  String get personaIdealistDescription;

  /// Detailed explanation of how Idealist persona works
  ///
  /// In en, this message translates to:
  /// **'Tasks are selected purely based on your value weights. Deadlines and urgency are completely ignored. Best for: Long-term value alignment without time pressure.'**
  String get personaIdealistHowItWorks;

  /// Name of the Reflector allocation persona
  ///
  /// In en, this message translates to:
  /// **'Reflector'**
  String get personaReflector;

  /// Short description of the Reflector persona
  ///
  /// In en, this message translates to:
  /// **'Show me values I\'ve been neglecting.'**
  String get personaReflectorDescription;

  /// Detailed explanation of how Reflector persona works
  ///
  /// In en, this message translates to:
  /// **'Analyzes your recent completions and prioritizes values you\'ve been ignoring. Helps maintain balance when you tend to over-focus on certain areas. Best for: Avoiding burnout on favorite values.'**
  String get personaReflectorHowItWorks;

  /// Name of the Realist allocation persona
  ///
  /// In en, this message translates to:
  /// **'Realist'**
  String get personaRealist;

  /// Short description of the Realist persona
  ///
  /// In en, this message translates to:
  /// **'Show me what matters most, but warn me about urgent tasks.'**
  String get personaRealistDescription;

  /// Detailed explanation of how Realist persona works
  ///
  /// In en, this message translates to:
  /// **'Respects your value weights while warning about approaching deadlines. Urgent tasks with values get a priority boost. Best for: Most users who want balance.'**
  String get personaRealistHowItWorks;

  /// Name of the Firefighter allocation persona
  ///
  /// In en, this message translates to:
  /// **'Firefighter'**
  String get personaFirefighter;

  /// Short description of the Firefighter persona
  ///
  /// In en, this message translates to:
  /// **'Show me what\'s urgent right now.'**
  String get personaFirefighterDescription;

  /// Detailed explanation of how Firefighter persona works
  ///
  /// In en, this message translates to:
  /// **'Deadlines come first. All urgent tasks are included, even without values. Prevents missed deadlines at the cost of value alignment. Best for: High-pressure periods with many deadlines.'**
  String get personaFirefighterHowItWorks;

  /// Name of the Custom allocation persona
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get personaCustom;

  /// Short description of the Custom persona
  ///
  /// In en, this message translates to:
  /// **'Let me decide what you show me.'**
  String get personaCustomDescription;

  /// Detailed explanation of how Custom persona works
  ///
  /// In en, this message translates to:
  /// **'Full control over all allocation parameters. Configure urgency thresholds, boost multipliers, and display options. Best for: Power users who want fine-grained control.'**
  String get personaCustomHowItWorks;

  /// Badge text for recommended persona
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get personaRecommended;

  /// Expandable section title for persona explanation
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get personaHowItWorks;

  /// Section title for persona selection
  ///
  /// In en, this message translates to:
  /// **'How should Focus prioritize tasks?'**
  String get personaSectionTitle;

  /// Section title for urgency threshold settings
  ///
  /// In en, this message translates to:
  /// **'Urgency Thresholds'**
  String get urgencyThresholdsSection;

  /// Label for task urgency threshold setting
  ///
  /// In en, this message translates to:
  /// **'Task urgency (days before deadline)'**
  String get taskUrgencyDays;

  /// Label for project urgency threshold setting
  ///
  /// In en, this message translates to:
  /// **'Project urgency (days before deadline)'**
  String get projectUrgencyDays;

  /// Section title for display options
  ///
  /// In en, this message translates to:
  /// **'Display Options'**
  String get displayOptionsSection;

  /// Toggle label for showing orphan task count
  ///
  /// In en, this message translates to:
  /// **'Show unassigned task count'**
  String get showUnassignedTaskCount;

  /// Toggle label for showing next task on project cards
  ///
  /// In en, this message translates to:
  /// **'Show project next task'**
  String get showProjectNextTask;

  /// Label for daily focus task limit setting
  ///
  /// In en, this message translates to:
  /// **'Daily task limit'**
  String get dailyTaskLimit;

  /// Section title for advanced settings
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettingsSection;

  /// Label for urgent task behavior setting
  ///
  /// In en, this message translates to:
  /// **'Urgent task handling'**
  String get urgentTaskHandling;

  /// Urgent task behavior option: ignore
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get urgentTaskIgnore;

  /// Description for ignore urgent task behavior
  ///
  /// In en, this message translates to:
  /// **'Urgency has no effect, no warnings'**
  String get urgentTaskIgnoreDescription;

  /// Urgent task behavior option: warn only
  ///
  /// In en, this message translates to:
  /// **'Warn only'**
  String get urgentTaskWarnOnly;

  /// Description for warn only urgent task behavior
  ///
  /// In en, this message translates to:
  /// **'Urgent tasks excluded but show warnings'**
  String get urgentTaskWarnOnlyDescription;

  /// Urgent task behavior option: include all
  ///
  /// In en, this message translates to:
  /// **'Include all'**
  String get urgentTaskIncludeAll;

  /// Description for include all urgent task behavior
  ///
  /// In en, this message translates to:
  /// **'All urgent tasks are included'**
  String get urgentTaskIncludeAllDescription;

  /// Label for urgency boost multiplier setting
  ///
  /// In en, this message translates to:
  /// **'Value-aligned urgency boost'**
  String get valueAlignedUrgencyBoost;

  /// Toggle label for neglect-based weighting feature
  ///
  /// In en, this message translates to:
  /// **'Enable neglect weighting'**
  String get enableNeglectWeighting;

  /// Label for neglect lookback days setting
  ///
  /// In en, this message translates to:
  /// **'Reflector lookback (days)'**
  String get reflectorLookbackDays;

  /// Label for neglect influence setting
  ///
  /// In en, this message translates to:
  /// **'Neglect influence (0-1)'**
  String get neglectInfluence;

  /// Snackbar message when auto-switching to Custom persona
  ///
  /// In en, this message translates to:
  /// **'Switched to Custom mode'**
  String get switchedToCustomMode;

  /// Title for allocation settings page
  ///
  /// In en, this message translates to:
  /// **'Allocation Settings'**
  String get allocationSettingsTitle;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveLabel;

  /// Title for value rankings section
  ///
  /// In en, this message translates to:
  /// **'Value Rankings'**
  String get valueRankingsTitle;

  /// Description for value rankings section
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Higher values get more focus tasks.'**
  String get valueRankingsDescription;

  /// Empty state for value rankings
  ///
  /// In en, this message translates to:
  /// **'No values found. Create values in the Values screen.'**
  String get noValuesForRanking;

  /// Label for weight value
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightLabel;

  /// Subtitle for unranked values
  ///
  /// In en, this message translates to:
  /// **'Not ranked - drag to rank'**
  String get notRankedDragToRank;

  /// Title for the recommended next task card in project detail
  ///
  /// In en, this message translates to:
  /// **'Recommended Next Action'**
  String get recommendedNextActionLabel;

  /// Label for the start button that pins a task to Focus
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// Prefix shown before the next task name in project list
  ///
  /// In en, this message translates to:
  /// **'→ Next:'**
  String get projectNextTaskPrefix;

  /// Snackbar message shown when a task is pinned to Focus
  ///
  /// In en, this message translates to:
  /// **'\'{taskName}\' pinned to Focus'**
  String taskPinnedToFocus(String taskName);

  /// Format string for deadline relative to today
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Due today} =1{Due tomorrow} other{Due in {days} days}}'**
  String deadlineFormatDays(int days);

  /// Label shown when a deadline has passed
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get deadlineOverdue;

  /// Title for Reflector mode info banner when insufficient data
  ///
  /// In en, this message translates to:
  /// **'Building your history...'**
  String get reflectorBuildingHistory;

  /// Explanation for Reflector mode with insufficient history
  ///
  /// In en, this message translates to:
  /// **'Reflector works best with more data. You have {count} completions in the last {days} days. Using value weights for now.'**
  String reflectorHistoryExplanation(int count, int days);

  /// Label for target percentage in value stats
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get targetLabel;

  /// Label for actual percentage in value stats
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actualLabel;

  /// Label for gap percentage in value stats
  ///
  /// In en, this message translates to:
  /// **'Gap'**
  String get gapLabel;

  /// Activity counts for a value showing tasks and projects
  ///
  /// In en, this message translates to:
  /// **'{taskCount} tasks · {projectCount} projects'**
  String valueActivityCounts(int taskCount, int projectCount);

  /// Title for weekly trend chart
  ///
  /// In en, this message translates to:
  /// **'{weeks}-Week Trend'**
  String weekTrendTitle(int weeks);

  /// Message shown when there is no trend data to display
  ///
  /// In en, this message translates to:
  /// **'No trend data yet'**
  String get noTrendData;

  /// Title for activity section in value detail modal
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activitySectionTitle;

  /// Count of active tasks for a value
  ///
  /// In en, this message translates to:
  /// **'{count} active tasks'**
  String activeTasksCount(int count);

  /// Count of projects for a value
  ///
  /// In en, this message translates to:
  /// **'{count} projects'**
  String projectsCount(int count);

  /// Title for unassigned work section in values screen
  ///
  /// In en, this message translates to:
  /// **'Unassigned Work'**
  String get unassignedWorkTitle;

  /// Title for values setup gateway
  ///
  /// In en, this message translates to:
  /// **'Prioritize What Matters'**
  String get valuesGatewayTitle;

  /// Description for values setup gateway
  ///
  /// In en, this message translates to:
  /// **'Focus uses your personal values to recommend which tasks deserve your attention today.\n\nDefine what\'s important to you—like Health, Family, Career—and Focus will help you spend time on what truly matters.'**
  String get valuesGatewayDescription;

  /// Button to set up values
  ///
  /// In en, this message translates to:
  /// **'Set Up My Values'**
  String get setUpMyValues;

  /// Title for the My Day screen
  ///
  /// In en, this message translates to:
  /// **'My Day'**
  String get myDayTitle;

  /// Alert banner text for single item outside focus
  ///
  /// In en, this message translates to:
  /// **'1 item outside Focus'**
  String get myDayAlertBannerSingular;

  /// Alert banner text for multiple items outside focus
  ///
  /// In en, this message translates to:
  /// **'{count} items outside Focus'**
  String myDayAlertBannerPlural(int count);

  /// Button text to review excluded items
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get myDayAlertBannerReview;

  /// Excluded section title for Idealist persona
  ///
  /// In en, this message translates to:
  /// **'Needs Alignment'**
  String get excludedSectionNeedsAlignment;

  /// Excluded section title for Reflector persona
  ///
  /// In en, this message translates to:
  /// **'Worth Considering'**
  String get excludedSectionWorthConsidering;

  /// Excluded section title for Realist persona
  ///
  /// In en, this message translates to:
  /// **'Overdue Attention'**
  String get excludedSectionOverdueAttention;

  /// Excluded section title for Firefighter persona
  ///
  /// In en, this message translates to:
  /// **'Active Fires'**
  String get excludedSectionActiveFires;

  /// Excluded section title for Custom persona
  ///
  /// In en, this message translates to:
  /// **'Outside Focus'**
  String get excludedSectionOutsideFocus;

  /// Display name for urgent alert type
  ///
  /// In en, this message translates to:
  /// **'Urgent tasks'**
  String get alertTypeUrgent;

  /// Display name for overdue alert type
  ///
  /// In en, this message translates to:
  /// **'Overdue tasks'**
  String get alertTypeOverdue;

  /// Display name for no value alert type
  ///
  /// In en, this message translates to:
  /// **'Tasks without values'**
  String get alertTypeNoValue;

  /// Display name for low priority alert type
  ///
  /// In en, this message translates to:
  /// **'Low priority tasks'**
  String get alertTypeLowPriority;

  /// Display name for quota full alert type
  ///
  /// In en, this message translates to:
  /// **'Quota exceeded tasks'**
  String get alertTypeQuotaFull;

  /// Display name for critical severity
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get alertSeverityCritical;

  /// Display name for warning severity
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get alertSeverityWarning;

  /// Display name for notice severity
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get alertSeverityNotice;

  /// Section title for basic screen info
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get basicInfoSection;

  /// Subtitle for persona selection section
  ///
  /// In en, this message translates to:
  /// **'Choose a persona to control how tasks are prioritized'**
  String get personaSectionSubtitle;

  /// Section title for task limit setting
  ///
  /// In en, this message translates to:
  /// **'Task Limit'**
  String get taskLimitSection;

  /// Section title for source filter settings
  ///
  /// In en, this message translates to:
  /// **'Narrow Source'**
  String get sourceFilterSection;

  /// Subtitle for source filter section
  ///
  /// In en, this message translates to:
  /// **'Limit which tasks are considered'**
  String get sourceFilterSubtitle;

  /// Label shown while saving
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Button label for saving focus screen
  ///
  /// In en, this message translates to:
  /// **'Save Focus Screen'**
  String get saveFocusScreen;

  /// Label for maximum tasks slider
  ///
  /// In en, this message translates to:
  /// **'Maximum Tasks'**
  String get maxTasksLabel;

  /// Toggle label for showing excluded tasks section
  ///
  /// In en, this message translates to:
  /// **'Show excluded section'**
  String get showExcludedSection;

  /// Subtitle for show excluded section toggle
  ///
  /// In en, this message translates to:
  /// **'Display excluded tasks at the bottom'**
  String get showExcludedSectionSubtitle;

  /// Label for urgent task behavior dropdown
  ///
  /// In en, this message translates to:
  /// **'Urgent task handling'**
  String get urgentTaskBehaviorLabel;

  /// Dropdown option to ignore urgent tasks
  ///
  /// In en, this message translates to:
  /// **'Ignore urgent tasks'**
  String get urgentBehaviorIgnore;

  /// Dropdown option to warn about urgent tasks
  ///
  /// In en, this message translates to:
  /// **'Warn about urgent tasks'**
  String get urgentBehaviorWarnOnly;

  /// Dropdown option to include all urgent tasks
  ///
  /// In en, this message translates to:
  /// **'Include all urgent tasks'**
  String get urgentBehaviorIncludeAll;

  /// Format for displaying days count
  ///
  /// In en, this message translates to:
  /// **'{count} days'**
  String daysFormat(int count);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
