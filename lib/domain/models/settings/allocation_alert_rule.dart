import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';
import 'package:taskly_bloc/domain/queries/task_predicate.dart';

part 'allocation_alert_rule.freezed.dart';
part 'allocation_alert_rule.g.dart';

/// A single alert rule configuration.
///
/// Defines a condition to check and the severity of the alert if matched.
@freezed
abstract class AllocationAlertRule with _$AllocationAlertRule {
  const factory AllocationAlertRule({
    required String id,
    required String name,
    @JsonKey(fromJson: _conditionFromJson, toJson: _conditionToJson)
    required QueryFilter<TaskPredicate> condition,
    required AlertSeverity severity,
    @Default(true) bool enabled,
  }) = _AllocationAlertRule;
  const AllocationAlertRule._();

  factory AllocationAlertRule.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertRuleFromJson(json);
}

QueryFilter<TaskPredicate> _conditionFromJson(Map<String, dynamic> json) {
  return QueryFilter.fromJson(json, TaskPredicate.fromJson);
}

Map<String, dynamic> _conditionToJson(QueryFilter<TaskPredicate> filter) {
  return filter.toJson((p) => p.toJson());
}
