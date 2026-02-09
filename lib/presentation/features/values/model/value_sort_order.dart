import 'package:taskly_bloc/l10n/l10n.dart';

enum ValueSortOrder {
  priority,
  alphabetical,
  mostActive,
}

extension ValueSortOrderLabels on ValueSortOrder {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ValueSortOrder.priority => l10n.valueSortPriorityLabel,
      ValueSortOrder.alphabetical => l10n.valueSortAlphabeticalLabel,
      ValueSortOrder.mostActive => l10n.valueSortMostActiveLabel,
    };
  }
}
