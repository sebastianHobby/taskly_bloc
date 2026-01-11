import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_display_settings.freezed.dart';

/// Display settings for a specific page.
@freezed
abstract class PageDisplaySettings with _$PageDisplaySettings {
  const factory PageDisplaySettings({
    @Default(true) bool hideCompleted,
    @Default(false) bool completedSectionCollapsed,
    @Default(true) bool showNextActionsBanner,
  }) = _PageDisplaySettings;

  factory PageDisplaySettings.fromJson(Map<String, dynamic> json) {
    return PageDisplaySettings(
      hideCompleted: json['hideCompleted'] as bool? ?? true,
      completedSectionCollapsed:
          json['completedSectionCollapsed'] as bool? ?? false,
      showNextActionsBanner: json['showNextActionsBanner'] as bool? ?? true,
    );
  }
}

/// Extension for JSON serialization.
extension PageDisplaySettingsJson on PageDisplaySettings {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'hideCompleted': hideCompleted,
    'completedSectionCollapsed': completedSectionCollapsed,
    'showNextActionsBanner': showNextActionsBanner,
  };
}
