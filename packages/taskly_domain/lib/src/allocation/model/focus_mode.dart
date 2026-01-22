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
    // Two-mode UX: keep legacy enum values for persistence/back-compat,
    // but map them to the closest user-facing day style.
    FocusMode.intentional => 'Invest in values',
    FocusMode.sustainable => 'Invest in values',
    FocusMode.responsive => 'Protect deadlines',
    FocusMode.personalized => 'Invest in values',
  };

  /// Short tagline for the focus mode.
  String get tagline => switch (this) {
    FocusMode.intentional => 'Deadlines are guardrails.',
    FocusMode.sustainable => 'Deadlines are guardrails.',
    FocusMode.responsive => 'Handle time risk first.',
    FocusMode.personalized => 'Deadlines are guardrails.',
  };

  /// Tagline used in the Focus Setup wizard cards.
  String get wizardTagline => tagline;

  /// Short description used in the Focus Setup wizard cards.
  String get wizardDescription => switch (this) {
    FocusMode.intentional =>
      'Suggested picks are chosen from your values. Time-sensitive tasks still '
          'show up so nothing slips.',
    FocusMode.sustainable =>
      'Suggested picks are chosen from your values. Time-sensitive tasks still '
          'show up so nothing slips.',
    FocusMode.responsive =>
      'Time-sensitive tasks come first. Once you’re safe, Suggested picks fill '
          'the rest with value-aligned work.',
    FocusMode.personalized =>
      'Suggested picks are chosen from your values. Time-sensitive tasks still '
          'show up so nothing slips.',
  };

  /// Longer description explaining the focus mode behavior.
  String get description => switch (this) {
    FocusMode.intentional =>
      'Values-first suggestions with clear, explicit guardrails for deadlines '
          'and start dates.',
    FocusMode.sustainable =>
      'Values-first suggestions with clear, explicit guardrails for deadlines '
          'and start dates.',
    FocusMode.responsive =>
      'Deadline-first triage: focus on what’s at risk, then fill remaining '
          'attention with value-aligned suggestions.',
    FocusMode.personalized =>
      'Values-first suggestions with clear, explicit guardrails for deadlines '
          'and start dates.',
  };

  /// Icon name for the focus mode (Material icons).
  String get iconName => switch (this) {
    FocusMode.intentional => 'target',
    FocusMode.sustainable => 'target',
    FocusMode.responsive => 'bolt',
    FocusMode.personalized => 'target',
  };
}
