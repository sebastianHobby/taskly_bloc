import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_config.dart';
import 'package:taskly_bloc/domain/models/settings/allocation_alert_templates.dart';

part 'allocation_alert_settings.freezed.dart';
part 'allocation_alert_settings.g.dart';

/// User settings for allocation alerts.
///
/// Stored separately from AllocationConfig to allow independent customization.
/// Persisted via SettingsRepository with key 'allocation_alerts'.
@freezed
abstract class AllocationAlertSettings with _$AllocationAlertSettings {
  const factory AllocationAlertSettings({
    /// Current alert configuration
    @Default(AllocationAlertConfig()) AllocationAlertConfig config,

    /// Whether user has customized from persona default
    @Default(false) bool isCustomized,

    /// Last applied template ID (for UI display)
    String? appliedTemplateId,
  }) = _AllocationAlertSettings;
  const AllocationAlertSettings._();

  factory AllocationAlertSettings.fromJson(Map<String, dynamic> json) =>
      _$AllocationAlertSettingsFromJson(json);

  /// Default settings (Reflector template)
  static const defaults = AllocationAlertSettings(
    config: AllocationAlertTemplates.reflector,
    appliedTemplateId: 'reflector',
  );

  /// Apply a template, resetting customization flag
  AllocationAlertSettings applyTemplate(AlertTemplateInfo template) =>
      AllocationAlertSettings(
        config: template.config,
        isCustomized: false,
        appliedTemplateId: template.id,
      );

  /// Update config, marking as customized
  AllocationAlertSettings withConfig(AllocationAlertConfig newConfig) =>
      copyWith(
        config: newConfig,
        isCustomized: true,
      );
}
