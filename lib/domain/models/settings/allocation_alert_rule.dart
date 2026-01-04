import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';

part 'allocation_alert_rule.freezed.dart';
part 'allocation_alert_rule.g.dart';

/// A single alert rule configuration.
///
/// Defines which alert type to check and at what severity.
/// null severity means disabled.
@freezed
abstract class AllocationAlertRule with _$AllocationAlertRule {
  const factory AllocationAlertRule({
    required AllocationAlertType type,

    /// Severity for this rule. null = disabled.
    AlertSeverity? severity,
  }) = _AllocationAlertRule;
  const AllocationAlertRule._();

  factory AllocationAlertRule.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertRuleFromJson(json);

  bool get isEnabled => severity != null;
}
