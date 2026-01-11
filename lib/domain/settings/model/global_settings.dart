import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/app_theme_mode.dart';
import 'package:taskly_bloc/domain/models/settings/date_format_patterns.dart';

part 'global_settings.freezed.dart';

/// Global application settings.
@freezed
abstract class GlobalSettings with _$GlobalSettings {
  const factory GlobalSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default(GlobalSettings.defaultSeedArgb) int colorSchemeSeedArgb,
    String? localeCode,

    /// Fixed "home" timezone offset in minutes.
    ///
    /// This is intentionally stored as an offset (not device-local timezone) so
    /// the app's notion of "day" can be stable across travel.
    ///
    /// Note: this does not model DST transitions; it's a fixed offset.
    @Default(GlobalSettings.defaultHomeTimeZoneOffsetMinutes)
    int homeTimeZoneOffsetMinutes,
    @Default(DateFormatPatterns.defaultPattern) String dateFormatPattern,
    @Default(1.0) double textScaleFactor,
    @Default(false) bool onboardingCompleted,
  }) = _GlobalSettings;

  factory GlobalSettings.fromJson(Map<String, dynamic> json) {
    return GlobalSettings(
      themeMode: AppThemeMode.fromName(json['themeMode'] as String?),
      colorSchemeSeedArgb: _rgbHexToArgb(
        json['colorSchemeSeed'] as String?,
        fallbackArgb: defaultSeedArgb,
      ),
      localeCode: json['locale'] as String?,
      homeTimeZoneOffsetMinutes:
          (json['homeTimeZoneOffsetMinutes'] as num?)?.toInt() ??
          defaultHomeTimeZoneOffsetMinutes,
      dateFormatPattern:
          json['dateFormatPattern'] as String? ??
          DateFormatPatterns.defaultPattern,
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  /// Default home timezone offset minutes (GMT+10).
  ///
  /// This matches Australia (AEST) as a sensible product default.
  static const int defaultHomeTimeZoneOffsetMinutes = 10 * 60;

  /// Default seed color (Material Purple).
  static const int defaultSeedArgb = 0xFF6750A4;

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
}

/// Extension for JSON serialization (manual, not using json_serializable).
extension GlobalSettingsJson on GlobalSettings {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'themeMode': themeMode.name,
    'colorSchemeSeed': GlobalSettings._argbToRgbHexWithHash(
      colorSchemeSeedArgb,
    ),
    'locale': localeCode,
    'homeTimeZoneOffsetMinutes': homeTimeZoneOffsetMinutes,
    'dateFormatPattern': dateFormatPattern,
    'textScaleFactor': textScaleFactor,
    'onboardingCompleted': onboardingCompleted,
  };
}
