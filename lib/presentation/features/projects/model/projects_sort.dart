import 'package:taskly_bloc/l10n/l10n.dart';

enum ProjectsSortOrder {
  recentlyUpdated,
  alphabetical,
  priority,
  dueDate,
}

enum ProjectsValueSortOrder {
  lowestAverageRating,
  ratingTrendingDown,
  alphabetical,
}

extension ProjectsSortOrderLabels on ProjectsSortOrder {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ProjectsSortOrder.recentlyUpdated => l10n.sortRecentlyUpdated,
      ProjectsSortOrder.alphabetical => l10n.sortAlphabetical,
      ProjectsSortOrder.priority => l10n.sortPriority,
      ProjectsSortOrder.dueDate => l10n.sortDueDate,
    };
  }
}

extension ProjectsValueSortOrderLabels on ProjectsValueSortOrder {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ProjectsValueSortOrder.lowestAverageRating =>
        l10n.projectsSortValuesLowestAverageRating,
      ProjectsValueSortOrder.ratingTrendingDown =>
        l10n.projectsSortValuesTrendingDown,
      ProjectsValueSortOrder.alphabetical =>
        l10n.projectsSortValuesAlphabetical,
    };
  }
}
