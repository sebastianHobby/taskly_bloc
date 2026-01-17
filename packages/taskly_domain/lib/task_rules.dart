/// Task filtering rule types.
///
/// This entrypoint intentionally exports task rule models including
/// `RelativeComparison`, which is hidden from `queries.dart` to avoid symbol
/// collisions with query predicate types.
library;

export 'src/filtering/task_rules.dart';
