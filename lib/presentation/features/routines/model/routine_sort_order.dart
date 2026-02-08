enum RoutineSortOrder {
  scheduledFirst,
  alphabetical,
  priority,
  valueName,
  mostRecent,
}

extension RoutineSortOrderLabels on RoutineSortOrder {
  String get label {
    return switch (this) {
      RoutineSortOrder.scheduledFirst => 'Scheduled first',
      RoutineSortOrder.alphabetical => 'A–Z',
      RoutineSortOrder.priority => 'Value priority',
      RoutineSortOrder.valueName => 'Value name (A-Z)',
      RoutineSortOrder.mostRecent => 'Most recent',
    };
  }
}
