import 'package:taskly_bloc/domain/models/sort_preferences.dart';

class NextActionsSettings {
  const NextActionsSettings({
    this.tasksPerProject = 2,
    this.includeInboxTasks = true,
    this.excludeFutureStartDates = true,
    this.sortPreferences = const SortPreferences(),
  });

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

  final int tasksPerProject;
  final bool includeInboxTasks;
  final bool excludeFutureStartDates;
  final SortPreferences sortPreferences;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'tasksPerProject': tasksPerProject,
    'includeInboxTasks': includeInboxTasks,
    'excludeFutureStartDates': excludeFutureStartDates,
    'sortPreferences': sortPreferences.toJson(),
  };

  NextActionsSettings copyWith({
    int? tasksPerProject,
    bool? includeInboxTasks,
    bool? excludeFutureStartDates,
    SortPreferences? sortPreferences,
  }) {
    return NextActionsSettings(
      tasksPerProject: tasksPerProject ?? this.tasksPerProject,
      includeInboxTasks: includeInboxTasks ?? this.includeInboxTasks,
      excludeFutureStartDates:
          excludeFutureStartDates ?? this.excludeFutureStartDates,
      sortPreferences: sortPreferences ?? this.sortPreferences,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NextActionsSettings &&
        other.tasksPerProject == tasksPerProject &&
        other.includeInboxTasks == includeInboxTasks &&
        other.excludeFutureStartDates == excludeFutureStartDates &&
        other.sortPreferences == sortPreferences;
  }

  @override
  int get hashCode => Object.hash(
    tasksPerProject,
    includeInboxTasks,
    excludeFutureStartDates,
    sortPreferences,
  );
}
