import 'package:freezed_annotation/freezed_annotation.dart';

/// Defines the user's focus mode for task allocation.
///
/// Each focus mode represents a different approach to task prioritization:
/// - [intentional]: Important over urgent - pure value alignment, deep work on primary values
/// - [sustainable]: Growing all values - balanced approach with neglect recovery
/// - [responsive]: Time-sensitive first - urgency-focused, handles urgent tasks regardless of value
/// - [personalized]: Your own formula - user-defined settings combining all features
enum FocusMode {
  @JsonValue('intentional')
  intentional,

  @JsonValue('sustainable')
  sustainable,

  @JsonValue('responsive')
  responsive,

  @JsonValue('personalized')
  personalized,
}

/// Extension for focus mode UI elements and configuration.
extension FocusModeX on FocusMode {
  /// Human-readable name for display.
  String get displayName => switch (this) {
    FocusMode.intentional => 'Intentional',
    FocusMode.sustainable => 'Sustainable',
    FocusMode.responsive => 'Responsive',
    FocusMode.personalized => 'Personalized',
  };

  /// Short tagline for the focus mode.
  String get tagline => switch (this) {
    FocusMode.intentional => 'Important over urgent',
    FocusMode.sustainable => 'Growing all values',
    FocusMode.responsive => 'Time-sensitive first',
    FocusMode.personalized => 'Your own formula',
  };

  /// Longer description explaining the focus mode behavior.
  String get description => switch (this) {
    FocusMode.intentional =>
      'Deep work on primary values. Focuses on what matters most to you, '
          'filtering out urgency-driven distractions.',
    FocusMode.sustainable =>
      'Balanced approach across all values. Boosts neglected areas to '
          'maintain equilibrium and prevent burnout.',
    FocusMode.responsive =>
      'Urgency-first prioritization. Ensures time-sensitive tasks get '
          'attention regardless of their value alignment.',
    FocusMode.personalized =>
      'Custom configuration of all parameters. Fine-tune importance, '
          'urgency, synergy, and balance weights.',
  };

  /// Icon name for the focus mode (Material icons).
  String get iconName => switch (this) {
    FocusMode.intentional => 'target', // 🎯
    FocusMode.sustainable => 'eco', // 🌱
    FocusMode.responsive => 'bolt', // ⚡
    FocusMode.personalized => 'tune', // 🎛️
  };

  /// Section title for excluded tasks in My Day view.
  String get excludedSectionTitle => switch (this) {
    FocusMode.intentional => 'Needs Alignment',
    FocusMode.sustainable => 'Worth Considering',
    FocusMode.responsive => 'Active Fires',
    FocusMode.personalized => 'Outside Focus',
  };

  /// Converts legacy AllocationPersona name to FocusMode.
  ///
  /// Mapping:
  /// - idealist → intentional
  /// - realist → sustainable
  /// - firefighter → responsive
  /// - reflector → sustainable (merged)
  /// - custom → personalized
  static FocusMode fromLegacyPersona(String persona) {
    return switch (persona.toLowerCase()) {
      'idealist' => FocusMode.intentional,
      'realist' => FocusMode.sustainable,
      'firefighter' => FocusMode.responsive,
      'reflector' => FocusMode.sustainable, // Merged into sustainable
      'custom' => FocusMode.personalized,
      _ => FocusMode.sustainable, // Default fallback
    };
  }
}
