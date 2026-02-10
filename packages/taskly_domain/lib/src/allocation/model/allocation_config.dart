import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:taskly_domain/src/allocation/model/focus_mode.dart';

part 'allocation_config.freezed.dart';
part 'allocation_config.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

/// Controls the signal used for task suggestions.
enum SuggestionSignal {
  @JsonValue('behavior')
  behaviorBased,

  @JsonValue('ratings')
  ratingsBased,
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
    @Default(10) int suggestionsPerBatch,

    /// Whether the user has explicitly selected a focus mode.
    @Default(false) bool hasSelectedFocusMode,

    /// The focus mode controlling allocation behavior.
    @Default(FocusMode.sustainable) FocusMode focusMode,
    @Default(StrategySettings()) StrategySettings strategySettings,
    @Default(DisplaySettings()) DisplaySettings displaySettings,

    /// What signal drives suggestion weighting.
    @Default(SuggestionSignal.ratingsBased) SuggestionSignal suggestionSignal,
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
    /// Days before task deadline = urgent.
    @Default(3) int taskUrgencyThresholdDays,

    /// Enable neglect-based weighting (Reflector mode feature).
    @Default(true) bool enableNeglectWeighting,

    /// How many anchor projects to select per batch.
    @Default(2) int anchorCount,

    /// Minimum tasks to select per anchor project.
    @Default(1) int tasksPerAnchorMin,

    /// Maximum tasks to select per anchor project.
    @Default(2) int tasksPerAnchorMax,

    /// Days since last progress before a project receives rotation pressure.
    @Default(3) int rotationPressureDays,

    /// Only anchor projects that have actionable tasks.
    @Default(true) bool readinessFilter,

    /// Extra free slots beyond anchor allocation.
    @Default(0) int freeSlots,
  }) = _StrategySettings;
  const StrategySettings._();

  factory StrategySettings.fromJson(Map<String, dynamic> json) =>
      _$StrategySettingsFromJson(json);
}

/// Display-related settings controlling UI behavior.
///
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
