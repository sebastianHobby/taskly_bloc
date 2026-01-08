/// Shared enum types used across multiple Drift table definitions.
///
/// This file prevents duplicate enum definitions that cause import conflicts
/// when multiple .drift.dart files define the same enum.
library;

// ignore_for_file: constant_identifier_names

/// Entity source for tracking system templates vs user-created content.
///
/// Used by:
/// - [AttentionRules] table
/// - [ScreenDefinitions] table
///
/// NOTE: Values must match Supabase enum values (snake_case).
/// Drift's textEnum() uses .name, so enum values must be snake_case.
enum EntitySource {
  /// Seeded by the system on first launch
  system_template,

  /// Created by the user
  user_created,

  /// Imported from external source (future feature)
  imported,
}
