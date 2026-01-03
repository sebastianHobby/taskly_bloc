import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';

part 'next_actions_settings.freezed.dart';

/// Settings for the Next Actions feature.
@freezed
abstract class NextActionsSettings with _$NextActionsSettings {
  const factory NextActionsSettings({
    @Default(2) int tasksPerProject,
    @Default(true) bool includeInboxTasks,
    @Default(true) bool excludeFutureStartDates,
    @Default(SortPreferences()) SortPreferences sortPreferences,
  }) = _NextActionsSettings;

  factory NextActionsSettings.fromJson(Map<String, dynamic> json) {
    final tasksPerProject = json['tasksPerProject'] as int?;

    return NextActionsSettings(
      tasksPerProject: tasksPerProject == null || tasksPerProject < 1
          ? 1
          : tasksPerProject,
      includeInboxTasks: json['includeInboxTasks'] as bool? ?? true,
      excludeFutureStartDates: json['excludeFutureStartDates'] as bool? ?? true,
      sortPreferences: json['sortPreferences'] == null
          ? const SortPreferences()
          : SortPreferences.fromJson(
              json['sortPreferences'] as Map<String, dynamic>,
            ),
    );
  }
}

/// Extension for JSON serialization.
extension NextActionsSettingsJson on NextActionsSettings {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'tasksPerProject': tasksPerProject,
    'includeInboxTasks': includeInboxTasks,
    'excludeFutureStartDates': excludeFutureStartDates,
    'sortPreferences': sortPreferences.toJson(),
  };
}
