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
    FocusMode.sustainable => 'Balanced',
    FocusMode.responsive => 'Responsive',
    FocusMode.personalized => 'Personalized',
  };

  /// Short tagline for the focus mode.
  String get tagline => switch (this) {
    FocusMode.intentional => 'Do what matters most today.',
    FocusMode.sustainable => 'Stay steady, stay aligned.',
    FocusMode.responsive => 'Handle what’s time-sensitive first.',
    FocusMode.personalized => 'Run today your way.',
  };

  /// Tagline used in the Focus Setup wizard cards.
  String get wizardTagline => tagline;

  /// Short description used in the Focus Setup wizard cards.
  String get wizardDescription => switch (this) {
    FocusMode.intentional =>
      'Do what matters most, not what shouts loudest. Value-first prioritization '
          'with fewer urgent distractions.',
    FocusMode.sustainable =>
      'A calibrated mix of importance and urgency. Keeps momentum across values '
          'while staying realistic about deadlines.',
    FocusMode.responsive =>
      'Clear the time-sensitive stuff with confidence. Due-date-first '
          'prioritization to prevent slips.',
    FocusMode.personalized =>
      'Run today your way—without fighting the defaults. Custom weights for '
          'importance/urgency/balance.',
  };

  /// Longer description explaining the focus mode behavior.
  String get description => switch (this) {
    FocusMode.intentional =>
      'Deep work on primary values. Focuses on what matters most to you, '
          'filtering out urgency-driven distractions.',
    FocusMode.sustainable =>
      'A calibrated approach that balances importance and urgency to keep '
          'momentum across values, without overcommitting.',
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
    FocusMode.sustainable => 'tune', // 🎛️
    FocusMode.responsive => 'bolt', // ⚡
    FocusMode.personalized => 'tune', // 🎛️
  };
}
