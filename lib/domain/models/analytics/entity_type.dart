/// Entity types for analytics and navigation.
enum EntityType {
  task,
  project,
  value;

  /// URL segment for routing (e.g., 'task' → '/task/:id').
  String get urlSegment => name;

  /// Parse entity type from string.
  static EntityType fromString(String value) {
    return EntityType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Unknown entity type: $value'),
    );
  }
}
