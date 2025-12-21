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
  String get valuesTitle => 'Values';

  @override
  String get labelsTitle => 'Labels';

  @override
  String get noProjectsFound => 'No projects found.';

  @override
  String get createProjectTooltip => 'Create project';

  @override
  String get createTaskTooltip => 'Create task';

  @override
  String get createValueTooltip => 'Create value';

  @override
  String get createLabelTooltip => 'Create label';

  @override
  String get noLabelsFound => 'No labels found.';

  @override
  String get genericErrorFallback => 'Something went wrong. Please try again.';

  @override
  String get taskNotFound => 'Task not found.';

  @override
  String get projectNotFound => 'Project not found.';

  @override
  String get valueNotFound => 'Value not found.';

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
  String get inboxTitle => 'Inbox';

  @override
  String get todayTitle => 'Today';

  @override
  String get upcomingTitle => 'Upcoming';
}
