import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:taskly_bloc/domain/models/settings/allocation_exception_rule.dart';

part 'allocation_config.freezed.dart';
part 'allocation_config.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Defines the allocation behavior personality.
///
/// Each persona represents a different approach to task prioritization:
/// - [idealist]: Pure value alignment, no urgency consideration
/// - [reflector]: Prioritizes neglected values based on recent activity
/// - [realist]: Balanced approach with urgency warnings (recommended)
/// - [firefighter]: Urgency-first, includes all urgent tasks regardless of value
/// - [custom]: User-defined settings (allows combining all features)
enum AllocationPersona {
  @JsonValue('idealist')
  idealist,

  @JsonValue('reflector')
  reflector,

  @JsonValue('realist')
  realist,

  @JsonValue('firefighter')
  firefighter,

  @JsonValue('custom')
  custom,
}

/// Defines how urgent tasks without values are handled during allocation.
///
/// - [ignore]: Urgent value-less tasks are excluded, no warnings
/// - [warnOnly]: Urgent value-less tasks excluded but generate warnings
/// - [includeAll]: Urgent value-less tasks included in Focus list
enum UrgentTaskBehavior {
  @JsonValue('ignore')
  ignore,

  @JsonValue('warnOnly')
  warnOnly,

  @JsonValue('includeAll')
  includeAll,
}

// ============================================================================
// MODELS
// ============================================================================

/// Top-level allocation configuration model.
///
/// Contains nested settings for strategy behavior and display preferences.
/// This replaces the old `AllocationSettings` class with a cleaner structure.
@freezed
abstract class AllocationConfig with _$AllocationConfig {
  const factory AllocationConfig({
    @Default(10) int dailyLimit,
    @Default(AllocationPersona.realist) AllocationPersona persona,
    @Default(StrategySettings()) StrategySettings strategySettings,
    @Default(DisplaySettings()) DisplaySettings displaySettings,
    @Default([]) List<AllocationExceptionRule> exceptionRules,
  }) = _AllocationConfig;

  factory AllocationConfig.fromJson(Map<String, dynamic> json) =>
      _$AllocationConfigFromJson(json);
}

/// Strategy-related settings controlling allocation behavior.
///
/// Uses orthogonal feature flags that can be combined (e.g., urgency + neglect).
/// Provides factory constructors for persona presets.
@freezed
abstract class StrategySettings with _$StrategySettings {
  const factory StrategySettings({
    /// How to handle urgent tasks without value alignment.
    @Default(UrgentTaskBehavior.warnOnly) UrgentTaskBehavior urgentTaskBehavior,

    /// Days before task deadline = urgent.
    @Default(3) int taskUrgencyThresholdDays,

    /// Days before project deadline = urgent.
    @Default(7) int projectUrgencyThresholdDays,

    /// Boost multiplier for urgent tasks with value alignment.
    /// Set to 1.0 to disable urgency boosting.
    @Default(1.0) double urgencyBoostMultiplier,

    /// Enable neglect-based weighting (Reflector mode feature).
    @Default(false) bool enableNeglectWeighting,

    /// Days to look back for neglect calculation.
    @Default(7) int neglectLookbackDays,

    /// Weight of neglect score vs base weight (0.0-1.0).
    /// Default 0.7 matches Reflector persona preset.
    @Default(0.7) double neglectInfluence,

    /// Weight given to value priority.
    @Default(1.0) double valuePriorityWeight,

    /// Boost given to task priority.
    @Default(1.0) double taskPriorityBoost,

    /// Penalty for recency.
    @Default(0.0) double recencyPenalty,

    /// Weight for start date proximity.
    @Default(0.0) double startDateProximity,

    /// Multiplier for overdue emergency tasks.
    @Default(1.0) double overdueEmergencyMultiplier,
  }) = _StrategySettings;
  const StrategySettings._();

  factory StrategySettings.fromJson(Map<String, dynamic> json) =>
      _$StrategySettingsFromJson(json);

  /// Factory: Returns preset settings for the given persona.
  factory StrategySettings.forPersona(AllocationPersona persona) {
    switch (persona) {
      case AllocationPersona.idealist:
        return const StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.ignore,
          urgencyBoostMultiplier: 1,
          enableNeglectWeighting: false,
          valuePriorityWeight: 2,
          taskPriorityBoost: 0.5,
          recencyPenalty: 0,
          startDateProximity: 0,
          overdueEmergencyMultiplier: 1,
        );
      case AllocationPersona.reflector:
        return const StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
          urgencyBoostMultiplier: 1,
          enableNeglectWeighting: true,
          neglectLookbackDays: 7,
          neglectInfluence: 0.7,
          valuePriorityWeight: 1,
          taskPriorityBoost: 0.5,
          recencyPenalty: 0.2,
          startDateProximity: 0,
          overdueEmergencyMultiplier: 1,
        );
      case AllocationPersona.realist:
        return const StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
          urgencyBoostMultiplier: 1.5,
          enableNeglectWeighting: false,
          valuePriorityWeight: 1.5,
          taskPriorityBoost: 1,
          recencyPenalty: 0.1,
          startDateProximity: 0.5,
          overdueEmergencyMultiplier: 1.5,
        );
      case AllocationPersona.firefighter:
        return const StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.includeAll,
          urgencyBoostMultiplier: 2,
          enableNeglectWeighting: false,
          valuePriorityWeight: 0.5,
          taskPriorityBoost: 2,
          recencyPenalty: 0,
          startDateProximity: 1,
          overdueEmergencyMultiplier: 3,
        );
      case AllocationPersona.custom:
        // Custom returns defaults - user configures individually
        return const StrategySettings();
    }
  }
}

/// Display-related settings controlling UI behavior.
///
/// Note: Warning visibility is controlled by `StrategySettings.urgentTaskBehavior`,
/// not by DisplaySettings. The UI simply renders whatever warnings the allocator
/// generates. Set `urgentTaskBehavior = ignore` to suppress urgent task warnings.
@freezed
abstract class DisplaySettings with _$DisplaySettings {
  const factory DisplaySettings({
    /// Show count of value-less tasks in Focus list footer.
    @Default(true) bool showOrphanTaskCount,

    /// Show recommended next task on project cards.
    @Default(true) bool showProjectNextTask,

    /// Gap warning threshold percentage (0-100).
    /// Show warning when actual % differs from target % by this amount.
    /// Range: 5-50, Default: 15
    @Default(15) int gapWarningThresholdPercent,

    /// Number of weeks to show in value trend sparklines.
    /// Range: 2-12, Default: 4
    @Default(4) int sparklineWeeks,
  }) = _DisplaySettings;

  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      _$DisplaySettingsFromJson(json);
}

/// Extension for persona-specific UI elements
extension AllocationPersonaX on AllocationPersona {
  /// Section title for excluded tasks in My Day view
  String get excludedSectionTitle => switch (this) {
    AllocationPersona.idealist => 'Needs Alignment',
    AllocationPersona.reflector => 'Worth Considering',
    AllocationPersona.realist => 'Overdue Attention',
    AllocationPersona.firefighter => 'Active Fires',
    AllocationPersona.custom => 'Outside Focus',
  };
}
