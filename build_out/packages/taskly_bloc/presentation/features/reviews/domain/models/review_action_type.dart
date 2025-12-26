enum ReviewActionType {
  /// Update entity (task/project)
  update,

  /// Complete entity
  complete,

  /// Archive entity
  archive,

  /// Delete entity
  delete,

  /// Skip entity (no action in this review)
  skip,
}
