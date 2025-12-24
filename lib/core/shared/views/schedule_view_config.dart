import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/domain.dart';
import 'package:taskly_bloc/features/tasks/utils/task_selector.dart';

/// Configuration for a schedule view (Today, Upcoming, etc.).
///
/// This class encapsulates all the parameters that differentiate one schedule
/// view from another, enabling a single reusable view implementation.
class ScheduleViewConfig {
  const ScheduleViewConfig({
    required this.pageKey,
    required this.titleBuilder,
    required this.taskSelectorFactory,
    required this.projectMatcher,
    required this.emptyStateBuilder,
    this.bannerBuilder,
    this.defaultSortPreferences = const SortPreferences(),
    this.availableSortFields = const [
      SortField.deadlineDate,
      SortField.startDate,
      SortField.name,
    ],
    this.showBannerToggleInSettings = false,
  });

  /// The settings key for persisting sort preferences (use SettingsPageKey constants).
  final String pageKey;

  /// Builds the page title, typically using localization.
  final String Function(BuildContext context) titleBuilder;

  /// Factory to create a TaskSelectorConfig for this view.
  ///
  /// [now] is the current DateTime, and [sortCriteria] are the current sort
  /// preferences to apply.
  final TaskSelectorConfig Function(
    DateTime now,
    List<SortCriterion> sortCriteria,
  )
  taskSelectorFactory;

  /// Determines whether a project matches this view's date criteria.
  ///
  /// [startDate] and [deadlineDate] are the project's dates.
  /// [cutoffDay] is the reference day for comparison (e.g., today or tomorrow).
  final bool Function(
    DateTime? startDate,
    DateTime? deadlineDate,
    DateTime cutoffDay,
  )
  projectMatcher;

  /// Builds the empty state widget when no tasks or projects exist.
  final Widget Function(BuildContext context) emptyStateBuilder;

  /// Optional builder for a banner widget shown above the content.
  ///
  /// Returns null if no banner should be shown.
  final Widget? Function(BuildContext context)? bannerBuilder;

  /// Default sort preferences if none are saved in settings.
  final SortPreferences defaultSortPreferences;

  /// Available sort fields shown in the sort sheet.
  final List<SortField> availableSortFields;

  /// Whether to show the banner notification toggle in settings.
  /// Only applicable for views that have a bannerBuilder.
  final bool showBannerToggleInSettings;

  /// Returns the cutoff day for project matching.
  ///
  /// Override in subclasses to provide different cutoff logic.
  DateTime getCutoffDay(DateTime now) => now;
}

/// Configuration for the Today schedule view.
class TodayScheduleConfig extends ScheduleViewConfig {
  TodayScheduleConfig({
    required super.titleBuilder,
    required super.emptyStateBuilder,
    super.bannerBuilder,
  }) : super(
         pageKey: SettingsPageKey.today,
         taskSelectorFactory: (now, sortCriteria) => TaskSelector.today(
           now: now,
           sortCriteria: sortCriteria,
         ),
         projectMatcher: _matchesOnOrBeforeDay,
         showBannerToggleInSettings: true,
       );

  static bool _matchesOnOrBeforeDay(
    DateTime? startDate,
    DateTime? deadlineDate,
    DateTime cutoffDay,
  ) {
    bool matchesDate(DateTime? candidate) {
      if (candidate == null) return false;
      final day = DateTime(candidate.year, candidate.month, candidate.day);
      return !day.isAfter(cutoffDay);
    }

    return matchesDate(startDate) || matchesDate(deadlineDate);
  }

  @override
  DateTime getCutoffDay(DateTime now) => DateTime(now.year, now.month, now.day);
}

/// Configuration for the Upcoming schedule view.
class UpcomingScheduleConfig extends ScheduleViewConfig {
  UpcomingScheduleConfig({
    required super.titleBuilder,
    required super.emptyStateBuilder,
  }) : super(
         pageKey: SettingsPageKey.upcoming,
         taskSelectorFactory: (now, sortCriteria) => TaskSelector.upcoming(
           now: now,
           sortCriteria: sortCriteria,
         ),
         projectMatcher: _matchesOnOrAfterDay,
       );

  static bool _matchesOnOrAfterDay(
    DateTime? startDate,
    DateTime? deadlineDate,
    DateTime cutoffDay,
  ) {
    bool matchesDate(DateTime? candidate) {
      if (candidate == null) return false;
      final day = DateTime(candidate.year, candidate.month, candidate.day);
      return !day.isBefore(cutoffDay);
    }

    return matchesDate(startDate) || matchesDate(deadlineDate);
  }

  @override
  DateTime getCutoffDay(DateTime now) =>
      DateTime(now.year, now.month, now.day + 1);
}
