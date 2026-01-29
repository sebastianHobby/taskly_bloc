enum AnytimeSortOrder {
  recentlyUpdated,
  alphabetical,
  priority,
  dueDate,
}

extension AnytimeSortOrderLabels on AnytimeSortOrder {
  String get label {
    return switch (this) {
      AnytimeSortOrder.recentlyUpdated => 'Recently updated',
      AnytimeSortOrder.alphabetical => 'A–Z',
      AnytimeSortOrder.priority => 'Priority',
      AnytimeSortOrder.dueDate => 'Due date',
    };
  }
}
