import 'package:freezed_annotation/freezed_annotation.dart';

part 'screen_preferences.freezed.dart';

/// User preferences for a specific screen.
///
/// Stored in `screen_preferences`.
///
/// This replaces the legacy `sort_order` and `is_active` columns that used to
/// live on `screen_definitions` for system screens.
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
