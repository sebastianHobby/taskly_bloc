import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskly_bloc/presentation/shared/services/time/now_service.dart';
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
    final now = context.read<NowService>().nowLocal();
    return DateDisplayUtils.formatRelativeDate(context, date, now: now);
  }
}
