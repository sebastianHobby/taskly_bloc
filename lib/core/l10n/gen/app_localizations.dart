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
