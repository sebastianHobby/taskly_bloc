/// How multiple labels should be matched when filtering.
enum LabelMatchMode {
  /// Entity must have ANY of the specified labels
  any,

  /// Entity must have ALL of the specified labels
  all,

  /// Entity must have NONE of the specified labels
  none,
}
