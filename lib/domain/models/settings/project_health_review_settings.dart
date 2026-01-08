import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/settings/focus_mode.dart';

part 'project_health_review_settings.freezed.dart';
part 'project_health_review_settings.g.dart';

/// Settings for project-health coaching prompts (REVIEW items).
///
/// These settings control how project-level review items are generated from
/// allocation history and project/task metadata.
@freezed
abstract class ProjectHealthReviewSettings with _$ProjectHealthReviewSettings {
  const factory ProjectHealthReviewSettings({
    /// Rule #1: High-value project neglected.
    @Default(true) bool enableHighValueNeglected,

    /// Rule #2: No allocated tasks recently.
    @Default(true) bool enableNoAllocatedRecently,

    /// Rule #3: No allocatable tasks for > 1 day (time gated).
    @Default(true) bool enableNoAllocatableTasksGated,

    /// Allocation history window used for coverage + recency computations.
    @Default(14) int historyWindowDays,

    /// Minimum snapshot coverage days within [historyWindowDays] required to
    /// compute day-based rules.
    @Default(7) int minCoverageDays,

    /// Weight for the project's primary value when computing importance.
    @Default(1.0) double primaryValueWeight,

    /// Weight factor applied to the sum of secondary value weights.
    @Default(0.5) double secondaryValuesWeightFactor,

    /// Rule #1 importance threshold.
    @Default(7) int highValueImportanceThreshold,

    /// Rule #1: minimum days since last allocation to consider neglected.
    @Default(7) int highValueNeglectedDaysThreshold,

    /// Rule #1: max items returned.
    @Default(3) int highValueNeglectedTopK,

    /// Rule #2: minimum days since last allocation.
    @Default(14) int noAllocatedRecentlyDaysThreshold,

    /// Rule #2: max items returned.
    @Default(3) int noAllocatedRecentlyTopK,

    /// Rule #3: number of UTC days the condition must persist before surfacing.
    ///
    /// A value of 2 corresponds to "> 1 day".
    @Default(2) int noAllocatableGatingDays,

    /// Rule #3: max items returned.
    @Default(3) int noAllocatableTopK,

    /// Runtime gate state: first detected UTC day (date-only ISO string) per
    /// project for the "no allocatable tasks" rule.
    ///
    /// This is persisted in allocation settings to survive restarts.
    @Default(<String, String>{}) Map<String, String> noAllocatableFirstDayUtc,
  }) = _ProjectHealthReviewSettings;

  const ProjectHealthReviewSettings._();

  factory ProjectHealthReviewSettings.fromJson(Map<String, dynamic> json) =>
      _$ProjectHealthReviewSettingsFromJson(json);

  /// FocusMode defaults for project-health reviews.
  factory ProjectHealthReviewSettings.forFocusMode(FocusMode mode) {
    return switch (mode) {
      FocusMode.intentional => const ProjectHealthReviewSettings(
        enableHighValueNeglected: true,
        enableNoAllocatedRecently: true,
        enableNoAllocatableTasksGated: true,
        highValueImportanceThreshold: 9,
        highValueNeglectedDaysThreshold: 10,
        noAllocatedRecentlyDaysThreshold: 21,
        highValueNeglectedTopK: 2,
        noAllocatedRecentlyTopK: 2,
        noAllocatableTopK: 2,
      ),
      FocusMode.sustainable => const ProjectHealthReviewSettings(
        enableHighValueNeglected: true,
        enableNoAllocatedRecently: true,
        enableNoAllocatableTasksGated: true,
        highValueImportanceThreshold: 7,
        highValueNeglectedDaysThreshold: 7,
        noAllocatedRecentlyDaysThreshold: 14,
        highValueNeglectedTopK: 3,
        noAllocatedRecentlyTopK: 3,
        noAllocatableTopK: 3,
      ),
      FocusMode.responsive => const ProjectHealthReviewSettings(
        enableHighValueNeglected: false,
        enableNoAllocatedRecently: true,
        enableNoAllocatableTasksGated: true,
        highValueImportanceThreshold: 9,
        highValueNeglectedDaysThreshold: 14,
        noAllocatedRecentlyDaysThreshold: 21,
        highValueNeglectedTopK: 2,
        noAllocatedRecentlyTopK: 2,
        noAllocatableTopK: 2,
      ),
      FocusMode.personalized => const ProjectHealthReviewSettings(),
    };
  }
}
