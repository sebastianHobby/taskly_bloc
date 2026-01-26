import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:taskly_domain/src/allocation/model/allocation_exception_rule.dart';
import 'package:taskly_domain/src/allocation/model/focus_mode.dart';

part 'allocation_config.freezed.dart';
part 'allocation_config.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

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

/// Controls how project next actions are used during allocation.
enum NextActionPolicy {
  @JsonValue('off')
  off,

  @JsonValue('prefer')
  prefer,

  @JsonValue('require')
  require,
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
    /// How many suggestions to show per generated batch in the My Day ritual.
    ///
    /// This controls how many focus suggestions are generated/shown at a time.
    @Default(7) int suggestionsPerBatch,

    /// Whether the user has explicitly selected a focus mode.
    @Default(false) bool hasSelectedFocusMode,

    /// The focus mode controlling allocation behavior.
    @Default(FocusMode.sustainable) FocusMode focusMode,
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
/// Provides factory constructors for focus-mode presets.
@freezed
abstract class StrategySettings with _$StrategySettings {
  const factory StrategySettings({
    /// How to handle urgent tasks without value alignment.
    @Default(UrgentTaskBehavior.warnOnly) UrgentTaskBehavior urgentTaskBehavior,

    /// Days before task deadline = urgent.
    @Default(3) int taskUrgencyThresholdDays,

    /// Days before project deadline = urgent.
    @Default(7) int projectUrgencyThresholdDays,

    /// Enable neglect-based weighting (Reflector mode feature).
    @Default(false) bool enableNeglectWeighting,

    /// How many anchor projects to select per batch.
    @Default(2) int anchorCount,

    /// Minimum tasks to select per anchor project.
    @Default(1) int tasksPerAnchorMin,

    /// Maximum tasks to select per anchor project.
    @Default(2) int tasksPerAnchorMax,

    /// How next actions are used during selection.
    @Default(NextActionPolicy.prefer) NextActionPolicy nextActionPolicy,

    /// Days since last progress before a project receives rotation pressure.
    @Default(7) int rotationPressureDays,

    /// Only anchor projects that have actionable tasks.
    @Default(true) bool readinessFilter,

    /// Extra free slots beyond anchor allocation.
    @Default(0) int freeSlots,

    /// Count routine selections against value quotas during allocation.
    @Default(true) bool countRoutineSelectionsAgainstValueQuotas,
  }) = _StrategySettings;
  const StrategySettings._();

  factory StrategySettings.fromJson(Map<String, dynamic> json) =>
      _$StrategySettingsFromJson(json);

  /// Factory: Returns preset settings for the given focus mode.
  factory StrategySettings.forFocusMode(FocusMode mode) {
    return switch (mode) {
      FocusMode.intentional => const StrategySettings(
        urgentTaskBehavior: UrgentTaskBehavior.ignore,
        taskUrgencyThresholdDays: 3,
        projectUrgencyThresholdDays: 7,
        enableNeglectWeighting: false,
      ),
      FocusMode.sustainable => const StrategySettings(
        urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
        taskUrgencyThresholdDays: 3,
        projectUrgencyThresholdDays: 7,
        enableNeglectWeighting: true,
      ),
      FocusMode.responsive => const StrategySettings(
        urgentTaskBehavior: UrgentTaskBehavior.includeAll,
        taskUrgencyThresholdDays: 3,
        projectUrgencyThresholdDays: 7,
        enableNeglectWeighting: false,
      ),
      FocusMode.personalized => const StrategySettings(),
    };
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
