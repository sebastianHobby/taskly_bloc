import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/alert_severity.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_rule.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_type.dart';

part 'allocation_alert_config.freezed.dart';
part 'allocation_alert_config.g.dart';

/// Configuration for allocation alerts.
///
/// Contains a list of rules defining which alert types are enabled
/// and at what severity level.
@freezed
abstract class AllocationAlertConfig with _$AllocationAlertConfig {
  const factory AllocationAlertConfig({
    /// Alert rules. Each type should appear at most once.
    @Default([]) List<AllocationAlertRule> rules,

    /// Whether alerts are globally enabled
    @Default(true) bool enabled,
  }) = _AllocationAlertConfig;
  const AllocationAlertConfig._();

  factory AllocationAlertConfig.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertConfigFromJson(json);

  /// Get severity for a specific alert type, or null if disabled
  AlertSeverity? severityFor(AllocationAlertType type) {
    final rule = rules.where((r) => r.type == type).firstOrNull;
    return rule?.severity;
  }

  /// Check if a specific alert type is enabled
  bool isTypeEnabled(AllocationAlertType type) => severityFor(type) != null;

  /// Get all enabled alert types
  List<AllocationAlertType> get enabledTypes =>
      rules.where((r) => r.isEnabled).map((r) => r.type).toList();

  /// Create a new config with a rule updated
  AllocationAlertConfig withRule(AllocationAlertRule rule) {
    final newRules = rules.where((r) => r.type != rule.type).toList();
    if (rule.isEnabled) {
      newRules.add(rule);
    }
    return copyWith(rules: newRules);
  }

  /// Create a new config with a type enabled at given severity
  AllocationAlertConfig withTypeEnabled(
    AllocationAlertType type,
    AlertSeverity severity,
  ) => withRule(AllocationAlertRule(type: type, severity: severity));

  /// Create a new config with a type disabled
  AllocationAlertConfig withTypeDisabled(AllocationAlertType type) =>
      withRule(AllocationAlertRule(type: type, severity: null));
}
