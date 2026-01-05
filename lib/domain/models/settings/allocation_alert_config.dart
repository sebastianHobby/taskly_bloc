import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_rule.dart';

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
}
