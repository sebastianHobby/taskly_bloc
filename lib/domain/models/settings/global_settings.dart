import 'package:intl/intl.dart';
import 'package:taskly_bloc/domain/models/settings/app_theme_mode.dart';
import 'package:taskly_bloc/domain/models/settings/date_format_patterns.dart';

/// Global application settings
class GlobalSettings {
  const GlobalSettings({
    this.themeMode = AppThemeMode.system,
    this.colorSchemeSeedArgb = _defaultSeedArgb,
    this.localeCode,
    this.dateFormatPattern = DateFormatPatterns.defaultPattern,
    this.textScaleFactor = 1.0,
    this.onboardingCompleted = false,
  });

  factory GlobalSettings.fromJson(Map<String, dynamic> json) {
    return GlobalSettings(
      themeMode: AppThemeMode.fromName(json['themeMode'] as String?),
      colorSchemeSeedArgb: _rgbHexToArgb(
        json['colorSchemeSeed'] as String?,
        fallbackArgb: _defaultSeedArgb,
      ),
      localeCode: json['locale'] as String?,
      dateFormatPattern:
          json['dateFormatPattern'] as String? ??
          DateFormatPatterns.defaultPattern,
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  static const int _defaultSeedArgb = 0xFF6750A4;

  /// Parses `#RRGGBB`, `RRGGBB`, `#RGB`, or `RGB` into an ARGB int.
  ///
  /// Uses an opaque alpha channel (`FF`). Returns [fallbackArgb] if invalid.
  static int _rgbHexToArgb(String? hex, {required int fallbackArgb}) {
    if (hex == null || hex.isEmpty) return fallbackArgb;

    final normalized = hex.replaceAll('#', '').toUpperCase();

    final String fullHex;
    if (normalized.length == 3) {
      fullHex = normalized.split('').map((c) => '$c$c').join();
    } else if (normalized.length == 6) {
      fullHex = normalized;
    } else {
      return fallbackArgb;
    }

    final rgb = int.tryParse(fullHex, radix: 16);
    if (rgb == null) return fallbackArgb;
    return 0xFF000000 | rgb;
  }

  /// Converts an ARGB int to `#RRGGBB` (alpha is ignored).
  static String _argbToRgbHexWithHash(int argb) {
    final rgb = argb & 0x00FFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  final AppThemeMode themeMode;

  /// Seed color stored as ARGB int (`0xAARRGGBB`).
  final int colorSchemeSeedArgb;

  /// Preferred locale language code (e.g. `en`), or null to follow system.
  final String? localeCode;

  /// ICU date format pattern (e.g., 'yMd', 'yMMMd', 'yMMMMd')
  final String dateFormatPattern;
  final double textScaleFactor;
  final bool onboardingCompleted;

  /// Get a DateFormat instance for this settings' pattern and locale
  DateFormat getDateFormat() {
    return DateFormatPatterns.getFormat(
      dateFormatPattern,
      localeCode,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'themeMode': themeMode.name,
    'colorSchemeSeed': _argbToRgbHexWithHash(colorSchemeSeedArgb),
    'locale': localeCode,
    'dateFormatPattern': dateFormatPattern,
    'textScaleFactor': textScaleFactor,
    'onboardingCompleted': onboardingCompleted,
  };

  GlobalSettings copyWith({
    AppThemeMode? themeMode,
    int? colorSchemeSeedArgb,
    String? localeCode,
    String? dateFormatPattern,
    double? textScaleFactor,
    bool? onboardingCompleted,
  }) {
    return GlobalSettings(
      themeMode: themeMode ?? this.themeMode,
      colorSchemeSeedArgb: colorSchemeSeedArgb ?? this.colorSchemeSeedArgb,
      localeCode: localeCode ?? this.localeCode,
      dateFormatPattern: dateFormatPattern ?? this.dateFormatPattern,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GlobalSettings &&
        other.themeMode == themeMode &&
        other.colorSchemeSeedArgb == colorSchemeSeedArgb &&
        other.localeCode == localeCode &&
        other.dateFormatPattern == dateFormatPattern &&
        other.textScaleFactor == textScaleFactor &&
        other.onboardingCompleted == onboardingCompleted;
  }

  @override
  int get hashCode => Object.hash(
    themeMode,
    colorSchemeSeedArgb,
    localeCode,
    dateFormatPattern,
    textScaleFactor,
    onboardingCompleted,
  );
}
