import 'package:flutter/material.dart';
import 'package:taskly_bloc/presentation/shared/utils/date_display_utils.dart';

/// Centralized date-label formatting policy for the UI.
///
/// Policy:
/// - Relative labels within 7 days (past/future)
/// - Otherwise use `MaterialLocalizations.formatShortDate`
class DateLabelFormatter {
  DateLabelFormatter._();

  /// Formats a date using the globally selected policy.
  static String format(BuildContext context, DateTime date) {
    return DateDisplayUtils.formatRelativeDate(context, date);
  }
}
