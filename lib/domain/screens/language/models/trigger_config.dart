import 'package:freezed_annotation/freezed_annotation.dart';

part 'trigger_config.freezed.dart';
part 'trigger_config.g.dart';

/// Trigger configuration for screens.
@freezed
abstract class TriggerConfig with _$TriggerConfig {
  /// Trigger based on RRULE schedule
  const factory TriggerConfig.schedule({
    required String rrule,
    DateTime? nextTriggerDate,
  }) = ScheduleTrigger;

  /// Trigger when entities haven't been reviewed in X days
  const factory TriggerConfig.notReviewedSince({
    required int days,
  }) = NotReviewedSinceTrigger;

  /// Manual trigger only
  const factory TriggerConfig.manual() = ManualTrigger;

  factory TriggerConfig.fromJson(Map<String, dynamic> json) =>
      _$TriggerConfigFromJson(json);
}
