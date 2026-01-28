import 'package:flutter/material.dart';

/// Utility class for date-related display logic.
///
/// Provides consistent date status checks and formatting used across
/// task and project list tiles.
class DateDisplayUtils {
  DateDisplayUtils._();

  /// Checks if the given due date is overdue (before today).
  static bool isOverdue(
    DateTime? deadline, {
    required DateTime now,
    bool isCompleted = false,
  }) {
    if (deadline == null || isCompleted) return false;
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isBefore(today);
  }

  /// Checks if the given due date is today.
  static bool isDueToday(
    DateTime? deadline, {
    required DateTime now,
    bool isCompleted = false,
  }) {
    if (deadline == null || isCompleted) return false;
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    return deadlineDay.isAtSameMomentAs(today);
  }

  /// Checks if the given due date is within the next few days.
  static bool isDueSoon(
    DateTime? deadline, {
    required DateTime now,
    bool isCompleted = false,
    int withinDays = 3,
  }) {
    if (deadline == null || isCompleted) return false;
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(deadline.year, deadline.month, deadline.day);
    final daysUntil = deadlineDay.difference(today).inDays;
    return daysUntil > 0 && daysUntil <= withinDays;
  }

  /// Formats a date relative to today (e.g., "Today", "Tomorrow", "In 3 days").
  static String formatRelativeDate(
    BuildContext context,
    DateTime date, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final dateDay = DateTime(date.year, date.month, date.day);
    final difference = dateDay.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1 && difference <= 7) return 'In $difference days';
    if (difference < -1 && difference >= -7) return '${-difference} days ago';

    final localizations = MaterialLocalizations.of(context);
    return localizations.formatShortDate(date);
  }

  /// Formats a date as "Dec 23, 2025".
  static String formatMonthDayYear(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }
}
