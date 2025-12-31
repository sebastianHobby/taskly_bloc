import 'package:flutter/material.dart';
import 'package:taskly_bloc/core/l10n/l10n.dart';
import 'package:taskly_bloc/core/utils/talker_service.dart';

/// Utility class for converting iCal RRULE strings to human-readable format.
class RruleDisplayUtils {
  RruleDisplayUtils._();

  /// Parses an iCal RRULE string and returns a human-readable description.
  ///
  /// Example inputs:
  /// - `FREQ=DAILY` -> "Every day"
  /// - `FREQ=WEEKLY;BYDAY=MO,WE,FR` -> "Every week on Mon, Wed, Fri"
  /// - `FREQ=MONTHLY;INTERVAL=2` -> "Every 2 months"
  static String formatRrule(BuildContext context, String? rrule) {
    if (rrule == null || rrule.trim().isEmpty) {
      return '';
    }

    final l10n = context.l10n;
    final normalized = rrule.trim().toUpperCase();
    final parts = _parseRruleParts(normalized);

    final freq = parts['FREQ'];
    if (freq == null) {
      return rrule; // Return original if can't parse
    }

    final interval = int.tryParse(parts['INTERVAL'] ?? '1') ?? 1;
    final byDay = parts['BYDAY'];
    final byMonthDay = parts['BYMONTHDAY'];
    final count = parts['COUNT'];
    final until = parts['UNTIL'];

    // Build the base frequency string
    var result = _formatFrequency(l10n, freq, interval);

    // Add day specification for weekly
    if (freq == 'WEEKLY' && byDay != null) {
      final days = _formatDays(l10n, byDay);
      if (days.isNotEmpty) {
        result += ' ${l10n.rruleOn} $days';
      }
    }

    // Add day of month for monthly
    if (freq == 'MONTHLY' && byMonthDay != null) {
      result += ' ${l10n.rruleOnDay} $byMonthDay';
    }

    // Add ending condition
    if (count != null) {
      result += ' (${l10n.rruleTimes(int.tryParse(count) ?? 0)})';
    } else if (until != null) {
      final untilDate = _parseUntilDate(until);
      if (untilDate != null) {
        final localizations = MaterialLocalizations.of(context);
        result +=
            ' ${l10n.rruleUntil} ${localizations.formatShortDate(untilDate)}';
      }
    }

    return result;
  }

  /// Parses the RRULE string into key-value pairs.
  static Map<String, String> _parseRruleParts(String rrule) {
    // Remove RRULE: prefix if present
    var cleaned = rrule;
    if (cleaned.startsWith('RRULE:')) {
      cleaned = cleaned.substring(6);
    }

    final parts = <String, String>{};
    for (final part in cleaned.split(';')) {
      final keyValue = part.split('=');
      if (keyValue.length == 2) {
        parts[keyValue[0]] = keyValue[1];
      }
    }
    return parts;
  }

  /// Formats the frequency with interval.
  static String _formatFrequency(
    AppLocalizations l10n,
    String freq,
    int interval,
  ) {
    if (interval == 1) {
      return switch (freq) {
        'DAILY' => l10n.rruleDaily,
        'WEEKLY' => l10n.rruleWeekly,
        'MONTHLY' => l10n.rruleMonthly,
        'YEARLY' => l10n.rruleYearly,
        _ => freq.toLowerCase(),
      };
    }

    return switch (freq) {
      'DAILY' => l10n.rruleEveryNDays(interval),
      'WEEKLY' => l10n.rruleEveryNWeeks(interval),
      'MONTHLY' => l10n.rruleEveryNMonths(interval),
      'YEARLY' => l10n.rruleEveryNYears(interval),
      _ => '$interval $freq',
    };
  }

  /// Formats day abbreviations to localized names.
  static String _formatDays(AppLocalizations l10n, String byDay) {
    final dayMap = {
      'MO': l10n.dayMon,
      'TU': l10n.dayTue,
      'WE': l10n.dayWed,
      'TH': l10n.dayThu,
      'FR': l10n.dayFri,
      'SA': l10n.daySat,
      'SU': l10n.daySun,
    };

    final days = byDay.split(',');
    final formatted = days.map((d) => dayMap[d.trim()] ?? d).toList();
    return formatted.join(', ');
  }

  /// Parses the UNTIL date string.
  static DateTime? _parseUntilDate(String until) {
    try {
      // Format: YYYYMMDD or YYYYMMDDTHHMMSSZ
      if (until.length >= 8) {
        final year = int.parse(until.substring(0, 4));
        final month = int.parse(until.substring(4, 6));
        final day = int.parse(until.substring(6, 8));
        return DateTime(year, month, day);
      }
    } catch (e) {
      talker.debug('Failed to parse UNTIL date: $until');
      // Return null on parse error
    }
    return null;
  }
}
