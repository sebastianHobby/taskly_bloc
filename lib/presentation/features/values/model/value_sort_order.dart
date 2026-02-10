import 'package:taskly_bloc/l10n/l10n.dart';

enum ValueSortOrder {
  alphabetical,
  mostActive,
}

extension ValueSortOrderLabels on ValueSortOrder {
  String label(AppLocalizations l10n) {
    return switch (this) {
      ValueSortOrder.alphabetical => l10n.valueSortAlphabeticalLabel,
      ValueSortOrder.mostActive => l10n.valueSortMostActiveLabel,
    };
  }
}
