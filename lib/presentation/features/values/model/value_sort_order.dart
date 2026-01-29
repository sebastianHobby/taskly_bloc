enum ValueSortOrder {
  priority,
  alphabetical,
  mostActive,
}

extension ValueSortOrderLabels on ValueSortOrder {
  String get label {
    return switch (this) {
      ValueSortOrder.priority => 'Priority',
      ValueSortOrder.alphabetical => 'A–Z',
      ValueSortOrder.mostActive => 'Most active',
    };
  }
}
