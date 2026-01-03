import 'package:flutter/foundation.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/label_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';

/// Type alias for LabelQuery when querying values (labels with type=value).
/// Values are just labels with LabelType.value, so they share the same query.
/// Use [LabelQuery.values()] factory for convenience. (DR-003)
typedef ValueQuery = LabelQuery;

/// Unified query configuration for fetching labels with filtering and sorting.
@immutable
class LabelQuery {
  const LabelQuery({
    this.filter = const QueryFilter<LabelPredicate>.matchAll(),
    this.sortCriteria = const <SortCriterion>[],
  });

  factory LabelQuery.fromJson(Map<String, dynamic> json) {
    return LabelQuery(
      filter: QueryFilter.fromJson<LabelPredicate>(
        json['filter'] as Map<String, dynamic>? ?? const <String, dynamic>{},
        LabelPredicate.fromJson,
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

  /// Factory: All values (labels with type=value).
  factory LabelQuery.values({List<SortCriterion>? sortCriteria}) {
    return LabelQuery(
      filter: const QueryFilter<LabelPredicate>(
        shared: [LabelTypePredicate(labelType: LabelType.value)],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: All labels only (excluding values).
  factory LabelQuery.labelsOnly({List<SortCriterion>? sortCriteria}) {
    return LabelQuery(
      filter: const QueryFilter<LabelPredicate>(
        shared: [LabelTypePredicate(labelType: LabelType.label)],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Specific label by ID.
  factory LabelQuery.byId(String id) {
    return LabelQuery(
      filter: QueryFilter<LabelPredicate>(
        shared: [LabelIdPredicate(labelId: id)],
      ),
    );
  }

  /// Factory: Labels by multiple IDs.
  factory LabelQuery.byIds(List<String> ids) {
    return LabelQuery(
      filter: QueryFilter<LabelPredicate>(
        shared: [LabelIdsPredicate(labelIds: ids)],
      ),
    );
  }

  /// Factory: All labels and values (no filtering).
  factory LabelQuery.all({List<SortCriterion>? sortCriteria}) {
    return LabelQuery(
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Search by name.
  factory LabelQuery.search(
    String searchTerm, {
    List<SortCriterion>? sortCriteria,
  }) {
    return LabelQuery(
      filter: QueryFilter<LabelPredicate>(
        shared: [
          LabelNamePredicate(
            value: searchTerm,
            operator: StringOperator.contains,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Labels by color.
  factory LabelQuery.byColor(
    String colorHex, {
    List<SortCriterion>? sortCriteria,
  }) {
    return LabelQuery(
      filter: QueryFilter<LabelPredicate>(
        shared: [LabelColorPredicate(colorHex: colorHex)],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Filtering predicates to apply.
  final QueryFilter<LabelPredicate> filter;

  /// Sort criteria for ordering results.
  final List<SortCriterion> sortCriteria;

  // ========================================================================
  // Helper Properties
  // ========================================================================

  /// Whether this query filters by label type.
  bool get hasTypeFilter {
    return filter.shared.any((p) => p is LabelTypePredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is LabelTypePredicate);
  }

  /// Whether this query filters by specific IDs.
  bool get hasIdFilter {
    return filter.shared.any(
          (p) => p is LabelIdPredicate || p is LabelIdsPredicate,
        ) ||
        filter.orGroups
            .expand((g) => g)
            .any((p) => p is LabelIdPredicate || p is LabelIdsPredicate);
  }

  // ========================================================================
  // Modification Methods
  // ========================================================================

  /// Add an additional predicate to the shared filter.
  LabelQuery addPredicate(LabelPredicate predicate) {
    return copyWith(
      filter: filter.copyWith(
        shared: [...filter.shared, predicate],
      ),
    );
  }

  /// Creates a copy of this LabelQuery with the given fields replaced.
  LabelQuery copyWith({
    QueryFilter<LabelPredicate>? filter,
    List<SortCriterion>? sortCriteria,
  }) {
    return LabelQuery(
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
    return other is LabelQuery &&
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
