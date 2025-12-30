/// Type-safe enums for filtering UI components.
library;

/// Selection mode for filter criteria.
///
/// Replaces stringly-typed 'all' / 'specific' values.
enum SelectionMode {
  /// Apply to all entities (no filtering).
  all,

  /// Apply only to specific selected entities.
  specific;

  /// Get display label for the given entity type.
  String label(String entityName) => switch (this) {
    SelectionMode.all => 'All $entityName',
    SelectionMode.specific => 'Specific $entityName',
  };

  /// Get short label without entity name.
  String get shortLabel => switch (this) {
    SelectionMode.all => 'All',
    SelectionMode.specific => 'Specific',
  };
}
