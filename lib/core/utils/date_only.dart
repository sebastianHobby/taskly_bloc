/// Date-only helpers.
///
/// The app stores and displays task/project scheduling as dates (no time).
/// These helpers normalize any incoming DateTime values to midnight.
library;

/// Returns a new [DateTime] at midnight (UTC) for the given date.
///
/// Using UTC for date-only values prevents accidental day shifts when the user
/// travels or when values are parsed/serialized across time zones.
DateTime dateOnly(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

/// Like [dateOnly], but returns null when [value] is null.
DateTime? dateOnlyOrNull(DateTime? value) =>
    value == null ? null : dateOnly(value);

/// Encodes a date-only [DateTime] as a Postgres `date` string (`YYYY-MM-DD`).
///
/// The time portion is ignored.
String encodeDateOnly(DateTime value) {
  final d = dateOnly(value);
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}

/// Like [encodeDateOnly], but returns null when [value] is null.
String? encodeDateOnlyOrNull(DateTime? value) =>
    value == null ? null : encodeDateOnly(value);

/// Parses a Postgres `date` string (`YYYY-MM-DD`) into a UTC-midnight
/// [DateTime].
///
/// Throws a [FormatException] if [value] is not a valid date.
DateTime parseDateOnly(String value) {
  final match = RegExp(r'^(\\d{4})-(\\d{2})-(\\d{2})$').firstMatch(value);
  if (match == null) {
    throw FormatException('Invalid date-only string: $value');
  }

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);

  return DateTime.utc(year, month, day);
}

/// Best-effort parse for persisted date-only strings.
///
/// Accepts either:
/// - `YYYY-MM-DD` (preferred)
/// - legacy ISO-8601 timestamps (will be normalized to date-only)
DateTime? tryParseDateOnly(String? value) {
  if (value == null || value.isEmpty) return null;

  if (RegExp(r'^\\d{4}-\\d{2}-\\d{2}$').hasMatch(value)) {
    return parseDateOnly(value);
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;

  // Preserve the calendar date represented by the parsed value (in its own
  // timezone), then normalize to UTC-midnight.
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}
