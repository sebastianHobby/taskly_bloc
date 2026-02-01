enum ProjectsSortOrder {
  recentlyUpdated,
  alphabetical,
  priority,
  dueDate,
}

extension ProjectsSortOrderLabels on ProjectsSortOrder {
  String get label {
    return switch (this) {
      ProjectsSortOrder.recentlyUpdated => 'Recently updated',
      ProjectsSortOrder.alphabetical => 'A-Z',
      ProjectsSortOrder.priority => 'Priority',
      ProjectsSortOrder.dueDate => 'Due date',
    };
  }
}
