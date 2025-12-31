import 'package:intl/intl.dart';

/// Common date format patterns for use with intl DateFormat.
/// These follow the ICU date format patterns.
class DateFormatPatterns {
  static const String short = 'yMd'; // 12/30/2025
  static const String medium = 'yMMMd'; // Dec 30, 2025
  static const String long = 'yMMMMd'; // December 30, 2025
  static const String full = 'yMMMMEEEEd'; // Monday, December 30, 2025

  static const String defaultPattern = medium;

  /// Get localized DateFormat for the given pattern and locale
  static DateFormat getFormat(String pattern, [String? locale]) {
    try {
      return DateFormat(pattern, locale);
    } catch (e) {
      // Fallback to default pattern if invalid
      return DateFormat(defaultPattern, locale);
    }
  }
}
