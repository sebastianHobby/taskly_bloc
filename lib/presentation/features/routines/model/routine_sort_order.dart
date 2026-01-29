enum RoutineSortOrder {
  scheduledFirst,
  alphabetical,
  priority,
  mostRecent,
}

extension RoutineSortOrderLabels on RoutineSortOrder {
  String get label {
    return switch (this) {
      RoutineSortOrder.scheduledFirst => 'Scheduled first',
      RoutineSortOrder.alphabetical => 'A–Z',
      RoutineSortOrder.priority => 'Priority',
      RoutineSortOrder.mostRecent => 'Most recent',
    };
  }
}
