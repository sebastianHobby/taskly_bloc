# 03 — SectionDataResult Test Migration (Typed Items)

## Objective

Rewrite `SectionDataResult` tests to validate the **new, typed data model**:
- Data sections contain `items: List<ScreenItem>` (no `primaryEntities`, no `primaryEntityType`).
- Convenience getters (`allTasks`, `allProjects`, `allValues`, `primaryCount`) are based on those typed items.

## Target file

- `test/domain/services/screens/section_data_result_test.dart`

## Exact migration steps

### 1) Add imports for new item types

Replace any old entity-type-driven imports with:
- `package:taskly_bloc/domain/models/screens/screen_item.dart`

Keep existing imports for Task/Project/Value fixtures.

### 2) Replace construction of `SectionDataResult.data`

**Before**
- `SectionDataResult.data(primaryEntities: [...], primaryEntityType: 'task')`

**After**
- `SectionDataResult.data(items: [ScreenItem.task(TestData.task()), ...])`

Use the exact typed variants:
- `ScreenItem.task(task)`
- `ScreenItem.project(project)`
- `ScreenItem.value(value)`

### 3) Replace assertions

#### A) Former `primaryEntityType` assertions

**Before**
- `expect(dataResult.primaryEntityType, 'task')`

**After**
- Assert on the typed items, e.g.
  - `expect(dataResult.items.whereType<ScreenItemTask>(), hasLength(n))`
  - `expect(dataResult.allTasks, hasLength(n))`

#### B) Former `primaryEntities` length assertions

**Before**
- `expect(dataResult.primaryEntities, hasLength(1))`

**After**
- `expect(dataResult.items, hasLength(1))`

### 4) Update coverage for convenience getters

Rewrite these groups to match new behavior:

#### `allTasks`
- Build `items` with multiple `ScreenItem.task(...)` and verify `result.allTasks` matches.
- Add a mixed list test:
  - `items: [ScreenItem.task(...), ScreenItem.project(...)]`
  - `allTasks` returns only tasks.

#### `allProjects`
- Similar: ensure only projects are returned.

#### `allValues`
- Similar: ensure only values are returned.

#### `primaryCount`
- For `DataSectionResult`, `primaryCount == items.length`.
- For `AllocationSectionResult`, `primaryCount == allocatedTasks.length`.
- For `AgendaSectionResult`, keep existing agenda computation expectations.

### 5) `relatedEntities` tests

`relatedEntities` remains `Map<String, List<Object>>`.
- Keep tests, but ensure types passed are `List<Object>` or specific typed lists cast to `Object`.

Example:
- `relatedEntities: {'projects': <Object>[TestData.project()]}`

(Or keep as-is if the code already compiles and the map is typed permissively.)

## Notes

- This rewrite should **not** change production code.
- The goal is to make tests reflect the model invariants:
  - The source of truth for entity type is the `ScreenItem` variant.

## Exit criteria

- No `primaryEntityType` appears anywhere in `test/domain/services/screens/section_data_result_test.dart`.
- Tests use `ScreenItem.*` constructors.
- `flutter analyze` no longer reports undefined named parameters for `SectionDataResult.data`.
