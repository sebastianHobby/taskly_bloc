import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_domain/domain/priority/model/allocation_preference.dart';

/// Three-mode urgency handling for Focus screens (DR-015).
///
/// Provides a simplified mental model for users instead of multiple
/// interacting controls (strategy + slider + checkbox).
enum UrgencyMode {
  /// ⚖️ Values Only - Pure value-based selection, deadlines ignored.
  ///
  /// Technical mapping:
  /// - `strategyType: proportional`
  /// - `urgencyInfluence: 0.0`
  @JsonValue('values_only')
  valuesOnly,

  /// 🔀 Balanced - Values + deadlines combined.
  ///
  /// Shows urgency slider for fine-tuning (default 40%).
  ///
  /// Technical mapping:
  /// - `strategyType: urgencyWeighted`
  /// - `urgencyInfluence: 0.0-1.0` (adjustable)
  @JsonValue('balanced')
  balanced,

  /// 🚨 Urgent First - Urgent tasks always appear first.
  ///
  /// Remaining slots filled by value-based selection.
  /// May exceed maximum task limit.
  ///
  /// Technical mapping:
  /// - `strategyType: proportional`
  /// - `alwaysIncludeUrgent: true`
  @JsonValue('urgent_first')
  urgentFirst,
}

/// Extension methods for [UrgencyMode].
extension UrgencyModeExtension on UrgencyMode {
  /// Display name for UI.
  String get displayName => switch (this) {
    UrgencyMode.valuesOnly => 'Values Only',
    UrgencyMode.balanced => 'Balanced',
    UrgencyMode.urgentFirst => 'Urgent First',
  };

  /// Icon for the mode.
  String get emoji => switch (this) {
    UrgencyMode.valuesOnly => '⚖️',
    UrgencyMode.balanced => '🔀',
    UrgencyMode.urgentFirst => '🚨',
  };

  /// Description for UI.
  String get description => switch (this) {
    UrgencyMode.valuesOnly => 'Pure value alignment. Deadlines are ignored.',
    UrgencyMode.balanced =>
      'Combines values with deadlines. Adjust the balance with the slider.',
    UrgencyMode.urgentFirst =>
      'Urgent tasks always appear. May exceed your task limit.',
  };

  /// Whether this mode shows the urgency influence slider.
  bool get showsUrgencySlider => this == UrgencyMode.balanced;

  /// Whether this mode may exceed the task limit.
  bool get mayExceedLimit => this == UrgencyMode.urgentFirst;

  /// Convert to allocation strategy type.
  AllocationStrategyType get strategyType => switch (this) {
    UrgencyMode.valuesOnly => AllocationStrategyType.proportional,
    UrgencyMode.balanced => AllocationStrategyType.urgencyWeighted,
    UrgencyMode.urgentFirst => AllocationStrategyType.proportional,
  };

  /// Default urgency influence for this mode.
  double get defaultUrgencyInfluence => switch (this) {
    UrgencyMode.valuesOnly => 0.0,
    UrgencyMode.balanced => 0.4,
    UrgencyMode.urgentFirst => 0.0,
  };

  /// Whether urgent tasks are always included regardless of values.
  bool get alwaysIncludeUrgent => this == UrgencyMode.urgentFirst;

  /// Create from strategy settings.
  static UrgencyMode fromStrategy({
    required AllocationStrategyType strategyType,
    required double urgencyInfluence,
    required bool alwaysIncludeUrgent,
  }) {
    if (alwaysIncludeUrgent) {
      return UrgencyMode.urgentFirst;
    }
    if (strategyType == AllocationStrategyType.urgencyWeighted) {
      return UrgencyMode.balanced;
    }
    if (urgencyInfluence == 0.0) {
      return UrgencyMode.valuesOnly;
    }
    // Default to balanced if unclear
    return UrgencyMode.balanced;
  }
}
