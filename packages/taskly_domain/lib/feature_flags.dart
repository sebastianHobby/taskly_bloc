/// Build-time feature flags for Taskly domain behavior.
///
/// These flags are compile-time constants that must be provided via
/// `--dart-define` when building the app.
abstract final class TasklyFeatureFlags {
  /// Enables task-level secondary value tags.
  ///
  /// Default is `false` (feature off).
  static const bool taskSecondaryValuesEnabled = bool.fromEnvironment(
    'TASKLY_TASK_SECONDARY_VALUES',
    defaultValue: false,
  );
}
