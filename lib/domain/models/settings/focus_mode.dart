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
    FocusMode.sustainable => 'Balance values and urgency',
    FocusMode.responsive => 'Time-sensitive first',
    FocusMode.personalized => 'Your own formula',
  };

  /// Tagline used in the Focus Setup wizard cards.
  String get wizardTagline => switch (this) {
    FocusMode.intentional => 'Important over urgent',
    FocusMode.sustainable => 'Balance values and urgency',
    FocusMode.responsive => 'Time-sensitive first',
    FocusMode.personalized => 'Your own formula',
  };

  /// Short description used in the Focus Setup wizard cards.
  String get wizardDescription => switch (this) {
    FocusMode.intentional =>
      'Focuses on what matters most to you, filtering out distractions.',
    FocusMode.sustainable =>
      'Focus on maintaining balance across all your values and meeting deadlines.',
    FocusMode.responsive =>
      'Ensures time-sensitive tasks get attention regardless of their value alignment.',
    FocusMode.personalized =>
      'Fine-tune importance, urgency, synergy, and balance weights.',
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
}
