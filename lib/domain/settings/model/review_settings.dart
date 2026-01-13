import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_settings.freezed.dart';
part 'review_settings.g.dart';

/// Types of periodic reviews available to the user.
enum ReviewType {
  @JsonValue('valuesAlignment')
  valuesAlignment,

  @JsonValue('progress')
  progress,

  @JsonValue('journalInsights')
  journalInsights,

  @JsonValue('balance')
  balance,

  @JsonValue('pinnedTasksCheck')
  pinnedTasksCheck,
}

/// Extension for ReviewType display and configuration.
extension ReviewTypeX on ReviewType {
  /// Human-readable name for display.
  String get displayName => switch (this) {
    ReviewType.valuesAlignment => 'Values Alignment',
    ReviewType.progress => 'Progress',
    ReviewType.journalInsights => 'Journal Insights',
    ReviewType.balance => 'Balance',
    ReviewType.pinnedTasksCheck => 'Pinned Tasks Check',
  };

  /// Description of what this review covers.
  String get description => switch (this) {
    ReviewType.valuesAlignment =>
      'Reflect on whether tasks align with your values',
    ReviewType.progress => 'Review completed tasks and achievements',
    ReviewType.journalInsights => 'Review mood and journaling patterns',
    ReviewType.balance => 'Assess value distribution and neglect',
    ReviewType.pinnedTasksCheck => 'Review and update pinned tasks',
  };

  /// Default frequency in days for this review type.
  int get defaultFrequencyDays => switch (this) {
    ReviewType.valuesAlignment => 14,
    ReviewType.progress => 7,
    ReviewType.journalInsights => 7,
    ReviewType.balance => 14,
    ReviewType.pinnedTasksCheck => 7,
  };
}

/// Configuration for a single review type.
@freezed
abstract class ReviewTypeConfig with _$ReviewTypeConfig {
  const factory ReviewTypeConfig({
    /// Whether this review type is enabled.
    @Default(true) bool enabled,

    /// How often to prompt for this review (in days).
    @Default(7) int frequencyDays,

    /// When this review was last completed.
    DateTime? lastCompletedAt,
  }) = _ReviewTypeConfig;

  factory ReviewTypeConfig.fromJson(Map<String, dynamic> json) =>
      _$ReviewTypeConfigFromJson(json);
}

/// User's review preferences and settings.
///
/// Controls which reviews are enabled, their frequency, and tracks
/// when each was last completed to determine when reviews are due.
@freezed
abstract class ReviewSettings with _$ReviewSettings {
  const factory ReviewSettings({
    /// Configuration for values alignment review.
    @Default(ReviewTypeConfig(frequencyDays: 14))
    ReviewTypeConfig valuesAlignment,

    /// Configuration for progress review.
    @Default(ReviewTypeConfig(frequencyDays: 7)) ReviewTypeConfig progress,

    /// Configuration for journal insights review.
    @Default(ReviewTypeConfig(frequencyDays: 7))
    ReviewTypeConfig journalInsights,

    /// Configuration for balance review.
    @Default(ReviewTypeConfig(frequencyDays: 14)) ReviewTypeConfig balance,

    /// Configuration for pinned tasks check.
    @Default(ReviewTypeConfig(frequencyDays: 7))
    ReviewTypeConfig pinnedTasksCheck,
  }) = _ReviewSettings;
  const ReviewSettings._();

  factory ReviewSettings.fromJson(Map<String, dynamic> json) =>
      _$ReviewSettingsFromJson(json);

  /// Gets the configuration for a specific review type.
  ReviewTypeConfig getConfig(ReviewType type) => switch (type) {
    ReviewType.valuesAlignment => valuesAlignment,
    ReviewType.progress => progress,
    ReviewType.journalInsights => journalInsights,
    ReviewType.balance => balance,
    ReviewType.pinnedTasksCheck => pinnedTasksCheck,
  };

  /// Checks if a specific review type is due based on last completion.
  bool isDue(ReviewType type, {DateTime? now}) {
    final config = getConfig(type);
    if (!config.enabled) return false;
    if (config.lastCompletedAt == null) return true;

    final currentTime = now ?? DateTime.now();
    final daysSince = currentTime.difference(config.lastCompletedAt!).inDays;
    return daysSince >= config.frequencyDays;
  }

  /// Returns all review types that are currently due.
  List<ReviewType> getDueReviews({DateTime? now}) {
    return ReviewType.values.where((type) => isDue(type, now: now)).toList();
  }

  /// Returns a copy with the specified review type marked as completed.
  ReviewSettings markCompleted(ReviewType type, {DateTime? completedAt}) {
    final time = completedAt ?? DateTime.now();
    return switch (type) {
      ReviewType.valuesAlignment => copyWith(
        valuesAlignment: valuesAlignment.copyWith(lastCompletedAt: time),
      ),
      ReviewType.progress => copyWith(
        progress: progress.copyWith(lastCompletedAt: time),
      ),
      ReviewType.journalInsights => copyWith(
        journalInsights: journalInsights.copyWith(lastCompletedAt: time),
      ),
      ReviewType.balance => copyWith(
        balance: balance.copyWith(lastCompletedAt: time),
      ),
      ReviewType.pinnedTasksCheck => copyWith(
        pinnedTasksCheck: pinnedTasksCheck.copyWith(lastCompletedAt: time),
      ),
    };
  }

  /// Returns a copy with the specified review type's configuration updated.
  ReviewSettings updateConfig(ReviewType type, ReviewTypeConfig config) {
    return switch (type) {
      ReviewType.valuesAlignment => copyWith(valuesAlignment: config),
      ReviewType.progress => copyWith(progress: config),
      ReviewType.journalInsights => copyWith(journalInsights: config),
      ReviewType.balance => copyWith(balance: config),
      ReviewType.pinnedTasksCheck => copyWith(pinnedTasksCheck: config),
    };
  }
}
