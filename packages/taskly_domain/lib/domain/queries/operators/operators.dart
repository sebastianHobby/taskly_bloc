/// Type-based comparison operators for query evaluation.
///
/// This library provides the canonical implementations for all comparison
/// operations used in filtering. Both in-memory evaluators and SQL builders
/// should use these definitions to ensure parity.
library;

export 'bool_comparison.dart';
export 'date_comparison.dart';
export 'value_comparison.dart';
