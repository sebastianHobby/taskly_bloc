import 'package:freezed_annotation/freezed_annotation.dart';

part 'screen_preferences.freezed.dart';

/// User preferences for a specific screen.
///
/// Stored in `AppSettings.screenPreferences` keyed by screenKey.
/// This replaces the `sort_order` and `is_active` columns from the
/// screen_definitions table for system screens.
@freezed
abstract class ScreenPreferences with _$ScreenPreferences {
  const factory ScreenPreferences({
    /// Custom sort order. Null means use default from template.
    int? sortOrder,

    /// Whether the screen is visible in navigation.
    @Default(true) bool isActive,
  }) = _ScreenPreferences;

  factory ScreenPreferences.fromJson(Map<String, dynamic> json) {
    return ScreenPreferences(
      sortOrder: json['sortOrder'] as int?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

/// Extension for JSON serialization.
extension ScreenPreferencesJson on ScreenPreferences {
  Map<String, dynamic> toJson() => {
    if (sortOrder != null) 'sortOrder': sortOrder,
    'isActive': isActive,
  };
}
