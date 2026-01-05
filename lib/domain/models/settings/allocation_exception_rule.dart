import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

part 'allocation_exception_rule.freezed.dart';
part 'allocation_exception_rule.g.dart';

/// A user-defined rule that triggers alerts for tasks that match specific conditions.
///
/// Used in the "Safety Net" feature to catch tasks that might be missed by the
/// active persona (e.g., "If deadline < 2 days, show Critical alert").
@freezed
class AllocationExceptionRule with _$AllocationExceptionRule {
  const factory AllocationExceptionRule({
    required String id,
    required String name,

    /// Human readable description of the rule logic (e.g. "Deadline < 2 days")
    required String description,

    /// The conditions that must be met for this rule to trigger.
    /// All predicates must match (AND logic).
    required List<TaskPredicate> conditions,
    @Default(true) bool enabled,

    /// The severity of the alert to generate when this rule matches.
    @Default(AlertSeverity.warning) AlertSeverity severity,
  }) = _AllocationExceptionRule;

  factory AllocationExceptionRule.fromJson(Map<String, dynamic> json) =>
      _$AllocationExceptionRuleFromJson(json);
}
