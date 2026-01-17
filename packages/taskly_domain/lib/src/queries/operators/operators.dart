/// Type-based comparison operators for query evaluation.
///
/// This library provides the canonical implementations for all comparison
/// operations used in filtering. Both in-memory evaluators and SQL builders
/// should use these definitions to ensure parity.
library;

export 'package:taskly_domain/src/queries/operators/bool_comparison.dart';
export 'package:taskly_domain/src/queries/operators/date_comparison.dart';
export 'package:taskly_domain/src/queries/operators/value_comparison.dart';
