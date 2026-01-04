import 'package:json_annotation/json_annotation.dart';

/// Alert types for allocation exclusions.
///
/// Each type maps to a specific condition on ExcludedTask.
/// User enables/disables types and sets severity per type.
enum AllocationAlertType {
  /// Task is urgent but not in Focus
  /// Source: ExcludedTask.isUrgent == true
  @JsonValue('urgent_excluded')
  urgentExcluded,

  /// Task is overdue but not in Focus
  /// Source: ExcludedTask.task.deadlineDate < now
  @JsonValue('overdue_excluded')
  overdueExcluded,

  /// Task has no value assigned
  /// Source: ExcludedTask.exclusionType == noCategory
  @JsonValue('no_value_excluded')
  noValueExcluded,

  /// Task filtered due to low priority
  /// Source: ExcludedTask.exclusionType == lowPriority
  @JsonValue('low_priority_excluded')
  lowPriorityExcluded,

  /// Task excluded because category quota reached
  /// Source: ExcludedTask.exclusionType == categoryLimitReached
  @JsonValue('quota_full_excluded')
  quotaFullExcluded,
}

/// Extension for display properties
extension AllocationAlertTypeX on AllocationAlertType {
  String get displayName => switch (this) {
    AllocationAlertType.urgentExcluded => 'Urgent tasks',
    AllocationAlertType.overdueExcluded => 'Overdue tasks',
    AllocationAlertType.noValueExcluded => 'Tasks without values',
    AllocationAlertType.lowPriorityExcluded => 'Low priority tasks',
    AllocationAlertType.quotaFullExcluded => 'Quota exceeded tasks',
  };

  String get description => switch (this) {
    AllocationAlertType.urgentExcluded =>
      'Alert when urgent tasks are not included in Focus',
    AllocationAlertType.overdueExcluded =>
      'Alert when overdue tasks are not included in Focus',
    AllocationAlertType.noValueExcluded =>
      'Alert when tasks without assigned values are excluded',
    AllocationAlertType.lowPriorityExcluded =>
      'Alert when tasks are filtered due to low priority',
    AllocationAlertType.quotaFullExcluded =>
      'Alert when tasks are excluded because category quota is full',
  };

  /// Icon name for this alert type (Material Icons)
  String get iconName => switch (this) {
    AllocationAlertType.urgentExcluded => 'bolt',
    AllocationAlertType.overdueExcluded => 'schedule',
    AllocationAlertType.noValueExcluded => 'label_off',
    AllocationAlertType.lowPriorityExcluded => 'low_priority',
    AllocationAlertType.quotaFullExcluded => 'playlist_add_check',
  };
}
