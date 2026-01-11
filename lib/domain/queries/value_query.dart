import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/presentation/shared/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/value_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';

/// Unified query configuration for fetching values with filtering and sorting.
@immutable
class ValueQuery {
  const ValueQuery({
    this.filter = const QueryFilter<ValuePredicate>.matchAll(),
    this.sortCriteria = const <SortCriterion>[],
  });

  factory ValueQuery.fromJson(Map<String, dynamic> json) {
    return ValueQuery(
      filter: QueryFilter.fromJson<ValuePredicate>(
        json['filter'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        ValuePredicate.fromJson,
      ),
      sortCriteria:
          (json['sortCriteria'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(SortCriterion.fromJson)
              .toList(growable: false) ??
          const <SortCriterion>[],
    );
  }

  // ========================================================================
  // Factory Methods (convenience constructors)
  // ========================================================================

  /// Factory: Specific value by ID.
  factory ValueQuery.byId(String id) {
    return ValueQuery(
      filter: QueryFilter<ValuePredicate>(
        shared: [ValueIdPredicate(valueId: id)],
      ),
    );
  }

  /// Factory: Values by multiple IDs.
  factory ValueQuery.byIds(List<String> ids) {
    return ValueQuery(
      filter: QueryFilter<ValuePredicate>(
        shared: [ValueIdsPredicate(valueIds: ids)],
      ),
    );
  }

  /// Factory: All values (no filtering).
  factory ValueQuery.all({List<SortCriterion>? sortCriteria}) {
    return ValueQuery(
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Search by name.
  factory ValueQuery.search(
    String searchTerm, {
    List<SortCriterion>? sortCriteria,
  }) {
    return ValueQuery(
      filter: QueryFilter<ValuePredicate>(
        shared: [
          ValueNamePredicate(
            value: searchTerm,
            operator: StringOperator.contains,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Values by color.
  factory ValueQuery.byColor(
    String colorHex, {
    List<SortCriterion>? sortCriteria,
  }) {
    return ValueQuery(
      filter: QueryFilter<ValuePredicate>(
        shared: [ValueColorPredicate(colorHex: colorHex)],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Filtering predicates to apply.
  final QueryFilter<ValuePredicate> filter;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query filters by specific IDs.
  bool get hasIdFilter {
    return filter.shared.any(
          (p) => p is ValueIdPredicate || p is ValueIdsPredicate,
        ) ||
        filter.orGroups
            .expand((g) => g)
            .any((p) => p is ValueIdPredicate || p is ValueIdsPredicate);
  }

  // ========================================================================
  // Modification Methods
  // ========================================================================

  /// Add an additional predicate to the shared filter.
  ValueQuery addPredicate(ValuePredicate predicate) {
    return copyWith(
      filter: filter.copyWith(
        shared: [...filter.shared, predicate],
      ),
    );
  }

  /// Creates a copy of this ValueQuery with the given fields replaced.
  ValueQuery copyWith({
    QueryFilter<ValuePredicate>? filter,
    List<SortCriterion>? sortCriteria,
  }) {
    return ValueQuery(
      filter: filter ?? this.filter,
      sortCriteria: sortCriteria ?? this.sortCriteria,
    );
  }

  // ========================================================================
  // JSON Serialization
  // ========================================================================

  Map<String, dynamic> toJson() => <String, dynamic>{
    'filter': filter.toJson((p) => p.toJson()),
    'sortCriteria': sortCriteria.map((s) => s.toJson()).toList(),
  };

  // ========================================================================
  // Equality & Hash
  // ========================================================================

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ValueQuery &&
        other.filter == filter &&
        listEquals(other.sortCriteria, sortCriteria);
  }

  @override
  int get hashCode => Object.hash(filter, Object.hashAll(sortCriteria));

  // ========================================================================
  // Defaults
  // ========================================================================

  static const List<SortCriterion> _defaultSortCriteria = [
    SortCriterion(field: SortField.name, direction: SortDirection.ascending),
  ];
}
