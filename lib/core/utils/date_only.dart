/// Date-only helpers.
///
/// The app stores and displays task/project scheduling as dates (no time).
/// These helpers normalize any incoming DateTime values to midnight.
library;

/// Returns a new [DateTime] at midnight (local time) for the given date.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

/// Like [dateOnly], but returns null when [value] is null.
DateTime? dateOnlyOrNull(DateTime? value) =>
    value == null ? null : dateOnly(value);
