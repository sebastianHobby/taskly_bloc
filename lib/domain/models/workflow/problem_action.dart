import 'package:freezed_annotation/freezed_annotation.dart';

part 'problem_action.freezed.dart';
part 'problem_action.g.dart';

/// Actions that can be taken to resolve detected problems.
///
/// These actions represent the quick-fix options shown in problem cards.
/// Each action variant carries the data needed to execute the fix.
@Freezed(unionKey: 'type')
sealed class ProblemAction with _$ProblemAction {
  const ProblemAction._();

  // === Date Actions (for urgent/overdue tasks) ===

  /// Reschedule the task to today
  @FreezedUnionValue('reschedule_today')
  const factory ProblemAction.rescheduleToday() = RescheduleToday;

  /// Reschedule the task to tomorrow
  @FreezedUnionValue('reschedule_tomorrow')
  const factory ProblemAction.rescheduleTomorrow() = RescheduleTomorrow;

  /// Reschedule the task to a specific number of days from now
  @FreezedUnionValue('reschedule_in_days')
  const factory ProblemAction.rescheduleInDays({
    required int days,
  }) = RescheduleInDays;

  /// Open date picker to select a new date
  @FreezedUnionValue('pick_date')
  const factory ProblemAction.pickDate() = PickDate;

  /// Remove the deadline entirely
  @FreezedUnionValue('clear_deadline')
  const factory ProblemAction.clearDeadline() = ClearDeadline;

  // === Value Assignment Actions (for unassigned tasks) ===

  /// Assign the task to a specific value/label
  @FreezedUnionValue('assign_value')
  const factory ProblemAction.assignValue({
    required String valueId,
    required String valueName,
  }) = AssignValue;

  /// Open value picker to select a value
  @FreezedUnionValue('pick_value')
  const factory ProblemAction.pickValue() = PickValue;

  // === Priority Actions (for high-priority overdue) ===

  /// Lower the priority by one level (P1→P2, P2→P3, P3→P4)
  @FreezedUnionValue('lower_priority')
  const factory ProblemAction.lowerPriority() = LowerPriority;

  /// Remove priority entirely (set to null)
  @FreezedUnionValue('remove_priority')
  const factory ProblemAction.removePriority() = RemovePriority;

  /// JSON serialization
  factory ProblemAction.fromJson(Map<String, dynamic> json) =>
      _$ProblemActionFromJson(json);

  /// Get a human-readable label for this action
  String get label => switch (this) {
    RescheduleToday() => 'Today',
    RescheduleTomorrow() => 'Tomorrow',
    RescheduleInDays(:final days) => 'In $days days',
    PickDate() => 'Pick date...',
    ClearDeadline() => 'Clear deadline',
    AssignValue(:final valueName) => valueName,
    PickValue() => 'Pick value...',
    LowerPriority() => 'Lower priority',
    RemovePriority() => 'Remove priority',
  };

  /// Get an icon name for this action (Material Icons)
  String get iconName => switch (this) {
    RescheduleToday() => 'today',
    RescheduleTomorrow() => 'event',
    RescheduleInDays() => 'date_range',
    PickDate() => 'calendar_month',
    ClearDeadline() => 'event_busy',
    AssignValue() => 'label',
    PickValue() => 'label_outline',
    LowerPriority() => 'arrow_downward',
    RemovePriority() => 'remove_circle_outline',
  };
}
