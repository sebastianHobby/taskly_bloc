/// How multiple values should be matched when filtering.
enum ValueMatchMode {
  /// Entity must have ANY of the specified values
  any,

  /// Entity must have ALL of the specified values
  all,

  /// Entity must have NONE of the specified values
  none,
}
