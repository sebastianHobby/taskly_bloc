import 'package:flutter/foundation.dart';

/// A normalized filter representation supporting a single OR level.
///
/// Semantics:
/// - Always apply [shared] (AND).
/// - If [orGroups] is empty: the filter is just [shared].
/// - If [orGroups] is non-empty: the filter is [shared] AND (group1 OR group2 ...)
///   where each group is an AND of predicates.
@immutable
class QueryFilter<TPredicate> {
  const QueryFilter({
    this.shared = const [],
    this.orGroups = const [],
  });

  const QueryFilter.matchAll() : this();

  final List<TPredicate> shared;
  final List<List<TPredicate>> orGroups;

  Map<String, dynamic> toJson(
    Map<String, dynamic> Function(TPredicate predicate) predicateToJson,
  ) {
    return <String, dynamic>{
      'shared': shared.map(predicateToJson).toList(growable: false),
      'orGroups': orGroups
          .map(
            (group) => group.map(predicateToJson).toList(growable: false),
          )
          .toList(growable: false),
    };
  }

  static QueryFilter<TPredicate> fromJson<TPredicate>(
    Map<String, dynamic> json,
    TPredicate Function(Map<String, dynamic> json) predicateFromJson,
  ) {
    final sharedRaw = (json['shared'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    final orGroupsRaw =
        (json['orGroups'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<List<dynamic>>()
            .toList(growable: false);

    final shared = sharedRaw.map(predicateFromJson).toList(growable: false);
    final orGroups = orGroupsRaw
        .map(
          (group) => group
              .whereType<Map<String, dynamic>>()
              .map(predicateFromJson)
              .toList(growable: false),
        )
        .toList(growable: false);

    return QueryFilter<TPredicate>(shared: shared, orGroups: orGroups);
  }

  bool get isMatchAll => shared.isEmpty && orGroups.isEmpty;

  /// Returns DNF terms where each term is an AND-list of predicates.
  ///
  /// - If [orGroups] is empty, returns a single term containing [shared].
  /// - Otherwise returns one term per OR-group, with [shared] prepended.
  List<List<TPredicate>> toDnfTerms() {
    if (orGroups.isEmpty) return [List<TPredicate>.from(shared)];
    return orGroups
        .map((group) => <TPredicate>[...shared, ...group])
        .toList(growable: false);
  }

  QueryFilter<TPredicate> copyWith({
    List<TPredicate>? shared,
    List<List<TPredicate>>? orGroups,
  }) {
    return QueryFilter<TPredicate>(
      shared: shared ?? this.shared,
      orGroups: orGroups ?? this.orGroups,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QueryFilter<TPredicate> &&
        listEquals(other.shared, shared) &&
        _listListEquals(other.orGroups, orGroups);
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(shared),
    Object.hashAll(orGroups.map(Object.hashAll)),
  );

  @override
  String toString() {
    if (isMatchAll) return 'QueryFilter.matchAll()';
    return 'QueryFilter(shared: $shared, orGroups: $orGroups)';
  }

  bool _listListEquals(List<List<TPredicate>> a, List<List<TPredicate>> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!listEquals(a[i], b[i])) return false;
    }
    return true;
  }
}

/// Extension methods for [QueryFilter].
extension QueryFilterExtension<T> on QueryFilter<T> {
  /// Merge with another filter (combines shared predicates and orGroups).
  QueryFilter<T> merge(QueryFilter<T>? other) {
    if (other == null) return this;
    return QueryFilter<T>(
      shared: [...shared, ...other.shared],
      orGroups: [...orGroups, ...other.orGroups],
    );
  }
}
