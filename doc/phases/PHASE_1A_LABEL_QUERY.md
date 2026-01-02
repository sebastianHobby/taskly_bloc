# Phase 1A: Query Foundation - LabelQuery

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Create `LabelQuery` and `LabelPredicate` using **freezed** for consistency with other domain models.

**IMPORTANT**: Use freezed for all query and predicate classes. This enables automatic JSON serialization and integrates cleanly with other freezed models like `DataConfig` and `Section`.

**Decisions Implemented**: DR-003 (ValueQuery = LabelQuery typedef)

---

## Prerequisites

- None (this is the first phase)

---

## Task 1: Create LabelPredicate

**File**: `lib/domain/queries/label_predicate.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/label.dart';

part 'label_predicate.freezed.dart';
part 'label_predicate.g.dart';

/// Operators for string predicates.
enum StringOperator {
  @JsonValue('equals')
  equals,
  @JsonValue('contains')
  contains,
  @JsonValue('starts_with')
  startsWith,
  @JsonValue('ends_with')
  endsWith,
  @JsonValue('is_null')
  isNull,
  @JsonValue('is_not_null')
  isNotNull,
}

/// A single predicate in a label filter.
@Freezed(unionKey: 'type')
sealed class LabelPredicate with _$LabelPredicate {
  /// Filter by label type (label vs value).
  @FreezedUnionValue('type')
  const factory LabelPredicate.type({
    required LabelType labelType,
  }) = LabelTypePredicate;

  /// Filter by label name.
  @FreezedUnionValue('name')
  const factory LabelPredicate.name({
    required String value,
    @Default(StringOperator.contains) StringOperator operator,
  }) = LabelNamePredicate;

  /// Filter by label color.
  @FreezedUnionValue('color')
  const factory LabelPredicate.color({
    required String colorHex,
  }) = LabelColorPredicate;

  /// Filter by specific label ID.
  @FreezedUnionValue('id')
  const factory LabelPredicate.id({
    required String labelId,
  }) = LabelIdPredicate;

  /// Filter by multiple label IDs.
  @FreezedUnionValue('ids')
  const factory LabelPredicate.ids({
    required List<String> labelIds,
  }) = LabelIdsPredicate;

  factory LabelPredicate.fromJson(Map<String, dynamic> json) =>
      _$LabelPredicateFromJson(json);
}
```

---

## Task 2: Create LabelQuery

**File**: `lib/domain/queries/label_query.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/label.dart';
import 'package:taskly_bloc/domain/models/sort_preferences.dart';
import 'package:taskly_bloc/domain/queries/label_predicate.dart';
import 'package:taskly_bloc/domain/queries/query_filter.dart';

part 'label_query.freezed.dart';
part 'label_query.g.dart';

/// Unified query configuration for fetching labels with filtering and sorting.
@freezed
class LabelQuery with _$LabelQuery {
  const LabelQuery._();

  const factory LabelQuery({
    @Default(QueryFilter<LabelPredicate>.matchAll()) QueryFilter<LabelPredicate> filter,
    @Default([]) List<SortCriterion> sortCriteria,
  }) = _LabelQuery;

  factory LabelQuery.fromJson(Map<String, dynamic> json) =>
      _$LabelQueryFromJson(json);

  // ========================================================================
  // Factory Methods (convenience constructors)
  // ========================================================================

  /// Factory: All values (labels with type=value).
  factory LabelQuery.values({List<SortCriterion>? sortCriteria}) {
    return LabelQuery(
      filter: const QueryFilter<LabelPredicate>(
        shared: [LabelPredicate.type(labelType: LabelType.value)],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: All labels only (excluding values).
  factory LabelQuery.labelsOnly({List<SortCriterion>? sortCriteria}) {
    return LabelQuery(
      filter: const QueryFilter<LabelPredicate>(
        shared: [LabelPredicate.type(labelType: LabelType.label)],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Specific label by ID.
  factory LabelQuery.byId(String id) {
    return LabelQuery(
      filter: QueryFilter<LabelPredicate>(
        shared: [LabelPredicate.id(labelId: id)],
      ),
    );
  }

  /// Factory: Labels by multiple IDs.
  factory LabelQuery.byIds(List<String> ids) {
    return LabelQuery(
      filter: QueryFilter<LabelPredicate>(
        shared: [LabelPredicate.ids(labelIds: ids)],
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
  factory LabelQuery.search(String searchTerm, {List<SortCriterion>? sortCriteria}) {
    return LabelQuery(
      filter: QueryFilter<LabelPredicate>(
        shared: [
          LabelPredicate.name(
            value: searchTerm,
            operator: StringOperator.contains,
          ),
        ],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

  /// Factory: Labels by color.
  factory LabelQuery.byColor(String colorHex, {List<SortCriterion>? sortCriteria}) {
    return LabelQuery(
      filter: QueryFilter<LabelPredicate>(
        shared: [LabelPredicate.color(colorHex: colorHex)],
      ),
      sortCriteria: sortCriteria ?? _defaultSortCriteria,
    );
  }

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
    return filter.shared.any((p) => p is LabelIdPredicate || p is LabelIdsPredicate) ||
        filter.orGroups.expand((g) => g).any((p) => p is LabelIdPredicate || p is LabelIdsPredicate);
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

  // ========================================================================
  // Defaults
  // ========================================================================

  static const List<SortCriterion> _defaultSortCriteria = [
    SortCriterion(field: SortField.name, direction: SortDirection.ascending),
  ];
}
```

---

## Task 3: Update Queries Barrel Export

**File**: `lib/domain/queries/queries.dart`

Add exports for new query files:

```dart
export 'label_predicate.dart';
export 'label_query.dart';
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `label_predicate.freezed.dart` generated
- [ ] `label_predicate.g.dart` generated
- [ ] `label_query.freezed.dart` generated
- [ ] `label_query.g.dart` generated
- [ ] Can instantiate `LabelQuery.values()` without errors
- [ ] Can instantiate `LabelQuery.labelsOnly()` without errors
- [ ] `LabelPredicate.fromJson` works for all predicate types

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/domain/queries/label_predicate.dart` | Label filtering predicates (freezed sealed class) |
| `lib/domain/queries/label_query.dart` | Label query with sort criteria (freezed) |

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/queries/queries.dart` | Add new exports |

---

## Next Phase

Proceed to **Phase 1B: Query Foundation - Enhancements** after validation passes.
