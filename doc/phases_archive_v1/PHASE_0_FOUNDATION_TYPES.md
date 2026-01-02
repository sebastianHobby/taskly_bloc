# Phase 0: Foundation Types

> ⚠️ **ARCHIVED DOCUMENT**
> 
> This document is **out of date** and has been superseded by new architecture decisions.
> It is kept as reference only. See `/doc/ARCHITECTURE_DECISIONS.md` for current decisions
> and `/doc/phases/` for the updated implementation plan.
>
> Key changes affecting this phase:
> - DR-002: Query embedded in DataConfig
> - DR-003: ValueQuery = LabelQuery typedef
> - DR-004: LabelMatchMode enum
> - DR-017: Unified Screen Model
> - DR-018: Problem Detection as SupportBlock
> - DR-019: WorkflowProgressBlock system-only

---

## AI Implementation Instructions

### Environment Setup
- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each file creation. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

### Phase Goal
Create all new domain model types WITHOUT breaking existing code. This is purely additive.

---

## Task 1: Create LabelQuery

**File**: `lib/domain/queries/label_query.dart`

**Pattern Reference**: Copy structure from `lib/domain/queries/task_query.dart` and `lib/domain/queries/project_query.dart`

**Requirements**:
```dart
// Create LabelQuery with:
// - LabelPredicate sealed class (similar to TaskPredicate)
// - LabelQuery class with filter and sortCriteria
// - Support filtering by: id, name, type (LabelType enum), color
// - Include JSON serialization (@JsonSerializable)
// - Include freezed annotations

// Predicates needed:
// - LabelIdPredicate (matches specific label ID)
// - LabelTypePredicate (LabelType.label or LabelType.value)
// - LabelNamePredicate (contains, equals)
// - LabelColorPredicate (optional, for filtering by color)
```

**Validation**:
1. Run `flutter analyze` - expect 0 errors
2. Verify `.freezed.dart` and `.g.dart` files generate

---

## Task 2: Create ValueQuery

**File**: `lib/domain/queries/value_query.dart`

**Note**: Values are Labels with `type == LabelType.value`. ValueQuery is a specialized wrapper.

**Requirements**:
```dart
// ValueQuery wraps LabelQuery but enforces type=value constraint
// This provides type safety when working specifically with values

@freezed
class ValueQuery with _$ValueQuery {
  const factory ValueQuery({
    QueryFilter<LabelPredicate>? additionalFilter,
    @Default([]) List<SortCriterion> sortCriteria,
  }) = _ValueQuery;
  
  const ValueQuery._();
  
  /// Converts to LabelQuery with type=value constraint baked in
  LabelQuery toLabelQuery() => LabelQuery(
    filter: QueryFilter(
      shared: [
        const LabelTypePredicate(type: LabelType.value),
        ...?additionalFilter?.shared,
      ],
      orGroups: additionalFilter?.orGroups ?? [],
    ),
    sortCriteria: sortCriteria,
  );
}
```

---

## Task 3: Create DataConfig Sealed Class

**File**: `lib/domain/models/screens/data_config.dart`

**Requirements**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';
import 'package:taskly_bloc/domain/queries/value_query.dart';

part 'data_config.freezed.dart';
part 'data_config.g.dart';

/// Configuration for fetching a single entity type.
/// Each variant is type-safe and prevents invalid query combinations.
@Freezed(unionKey: 'type')
sealed class DataConfig with _$DataConfig {
  /// Task data configuration
  @FreezedUnionValue('task')
  const factory DataConfig.task({
    required TaskQuery query,
  }) = TaskDataConfig;
  
  /// Project data configuration
  @FreezedUnionValue('project')
  const factory DataConfig.project({
    required ProjectQuery query,
  }) = ProjectDataConfig;
  
  /// Label data configuration
  @FreezedUnionValue('label')
  const factory DataConfig.label({
    LabelQuery? query, // null = all labels (excluding values)
  }) = LabelDataConfig;
  
  /// Value data configuration (labels with type=value)
  @FreezedUnionValue('value')
  const factory DataConfig.value({
    ValueQuery? query, // null = all values
  }) = ValueDataConfig;

  factory DataConfig.fromJson(Map<String, dynamic> json) =>
      _$DataConfigFromJson(json);
}
```

---

## Task 4: Create RelatedDataConfig Sealed Class

**File**: `lib/domain/models/screens/related_data_config.dart`

**Requirements**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

part 'related_data_config.freezed.dart';
part 'related_data_config.g.dart';

/// Configuration for fetching related entities within a DataSection.
/// Related entities have a parent-child relationship with the primary entity.
@Freezed(unionKey: 'type')
sealed class RelatedDataConfig with _$RelatedDataConfig {
  /// Tasks related to primary entity (project, label, or value)
  @FreezedUnionValue('tasks')
  const factory RelatedDataConfig.tasks({
    TaskQuery? additionalFilter, // Extra filtering beyond relationship
  }) = RelatedTasksConfig;
  
  /// Projects related to primary entity (label or value)
  @FreezedUnionValue('projects')
  const factory RelatedDataConfig.projects({
    ProjectQuery? additionalFilter,
  }) = RelatedProjectsConfig;
  
  /// Special 3-level hierarchy for Values: Value → Project → Task
  /// Only valid when primary is ValueDataConfig
  @FreezedUnionValue('valueHierarchy')
  const factory RelatedDataConfig.valueHierarchy({
    /// Include tasks that inherit value from their parent project
    @Default(true) bool includeInheritedTasks,
    /// Additional filter for projects in hierarchy
    ProjectQuery? projectFilter,
    /// Additional filter for tasks in hierarchy
    TaskQuery? taskFilter,
  }) = ValueHierarchyConfig;

  factory RelatedDataConfig.fromJson(Map<String, dynamic> json) =>
      _$RelatedDataConfigFromJson(json);
}
```

---

## Task 5: Create Section Sealed Class

**File**: `lib/domain/models/screens/section.dart`

**Requirements**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/related_data_config.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';

part 'section.freezed.dart';
part 'section.g.dart';

/// A section within a screen or workflow step.
/// Screens are composed of ordered sections.
@Freezed(unionKey: 'type')
sealed class Section with _$Section {
  /// Data section displaying entities
  @FreezedUnionValue('data')
  const factory Section.data({
    required DataConfig config,
    @Default([]) List<RelatedDataConfig> relatedData,
    /// Optional section title (shown as header)
    String? title,
  }) = DataSection;
  
  /// Support content (banners, stats, analytics)
  @FreezedUnionValue('support')
  const factory Section.support({
    required SupportBlockConfig config,
  }) = SupportSection;
  
  /// Navigation links (system screens only - Settings)
  @FreezedUnionValue('navigation')
  const factory Section.navigation({
    required List<NavigationItem> items,
    String? groupTitle,
  }) = NavigationSection;
  
  /// Allocation section (Next Actions - uses AllocationOrchestrator)
  @FreezedUnionValue('allocation')
  const factory Section.allocation({
    /// Max tasks to allocate
    @Default(10) int maxTasks,
  }) = AllocationSection;

  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);
}

/// Navigation item for NavigationSection
@freezed
class NavigationItem with _$NavigationItem {
  const factory NavigationItem({
    required String id,
    required String title,
    required String route,
    String? iconName, // Material icon name as string for serialization
    String? subtitle,
  }) = _NavigationItem;

  factory NavigationItem.fromJson(Map<String, dynamic> json) =>
      _$NavigationItemFromJson(json);
}

/// Support block configuration
/// References existing SupportBlock types from support_block.dart
@freezed
class SupportBlockConfig with _$SupportBlockConfig {
  const factory SupportBlockConfig({
    required SupportBlockType blockType,
    /// Additional configuration per block type
    Map<String, dynamic>? parameters,
  }) = _SupportBlockConfig;

  factory SupportBlockConfig.fromJson(Map<String, dynamic> json) =>
      _$SupportBlockConfigFromJson(json);
}

/// Types of support blocks
enum SupportBlockType {
  reviewBanner,      // "X tasks need review" banner
  problemBanner,     // Problem detection banner
  analyticsSummary,  // Stats card
  moodTrend,         // Wellbeing mood chart
  correlations,      // Wellbeing correlations
}
```

---

## Task 6: Create SectionDisplaySettings

**File**: `lib/domain/models/screens/section_display_settings.dart`

**Requirements**:
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'section_display_settings.freezed.dart';
part 'section_display_settings.g.dart';

/// User preferences for how a section displays its data.
/// Stored separately from section definition, keyed by screenId + sectionIndex.
@freezed
class SectionDisplaySettings with _$SectionDisplaySettings {
  const factory SectionDisplaySettings({
    /// How to display related entities
    @Default(RelatedDisplayMode.nested) RelatedDisplayMode relatedDisplayMode,
    
    /// Field to group primary entities by
    GroupByField? groupBy,
    
    /// Sort criteria (overrides DataConfig default)
    List<SectionSortCriterion>? sortOverride,
    
    /// Show completed items
    @Default(false) bool showCompleted,
    
    /// IDs of collapsed groups (for persistence)
    @Default({}) Set<String> collapsedGroupIds,
    
    /// Layout variant within the section
    @Default(SectionLayout.list) SectionLayout layout,
  }) = _SectionDisplaySettings;

  factory SectionDisplaySettings.fromJson(Map<String, dynamic> json) =>
      _$SectionDisplaySettingsFromJson(json);
}

/// How related entities are displayed within a data section
enum RelatedDisplayMode {
  /// Related entities nested under each parent (tree structure)
  nested,
  /// Related entities in separate list, grouped by parent
  flat,
  /// Related entities not shown (primary only)
  hidden,
}

/// Fields available for grouping
enum GroupByField {
  none,
  project,
  label,
  value,
  priority,
  dueDate,
  status,
}

/// Sort criterion for sections
@freezed
class SectionSortCriterion with _$SectionSortCriterion {
  const factory SectionSortCriterion({
    required SectionSortField field,
    @Default(SortDirection.ascending) SortDirection direction,
  }) = _SectionSortCriterion;

  factory SectionSortCriterion.fromJson(Map<String, dynamic> json) =>
      _$SectionSortCriterionFromJson(json);
}

enum SectionSortField {
  name,
  createdAt,
  updatedAt,
  deadlineDate,
  startDate,
  priority,
  custom,
}

enum SortDirection {
  ascending,
  descending,
}

/// Layout variants for sections
enum SectionLayout {
  list,       // Standard list view
  grid,       // Grid/card view
  kanban,     // Kanban columns (by status/priority)
  tree,       // Hierarchical tree view
  calendar,   // Calendar view (if date-based)
}
```

---

## Task 7: Update Barrel Export

**File**: `lib/domain/models/screens/screens.dart` (create if not exists)

**Requirements**:
```dart
// Export all screen-related models
export 'data_config.dart';
export 'related_data_config.dart';
export 'section.dart';
export 'section_display_settings.dart';
// Keep existing exports
export 'screen_definition.dart';
export 'view_definition.dart'; // Keep for now, deprecated later
export 'entity_selector.dart'; // Keep for now, deprecated later
export 'display_config.dart';  // Keep for now, deprecated later
export 'support_block.dart';
export 'screen_category.dart';
```

---

## Task 8: Update Queries Barrel Export

**File**: `lib/domain/queries/queries.dart`

**Requirements**:
Add exports for new query files:
```dart
export 'label_query.dart';
export 'value_query.dart';
// ... existing exports
```

---

## Validation Checklist

After completing all tasks:

1. [ ] Run `flutter analyze` - expect 0 errors, 0 warnings
2. [ ] Verify all `.freezed.dart` files generated
3. [ ] Verify all `.g.dart` files generated (JSON serialization)
4. [ ] Confirm no existing code was modified (except barrel exports)
5. [ ] Confirm all new types can be instantiated without errors

---

## Files Created This Phase

| File | Purpose |
|------|---------|
| `lib/domain/queries/label_query.dart` | Query/filter for labels |
| `lib/domain/queries/value_query.dart` | Query wrapper for values |
| `lib/domain/models/screens/data_config.dart` | Primary entity config |
| `lib/domain/models/screens/related_data_config.dart` | Related entity config |
| `lib/domain/models/screens/section.dart` | Section sealed class |
| `lib/domain/models/screens/section_display_settings.dart` | User display preferences |

## Files Modified This Phase

| File | Change |
|------|--------|
| `lib/domain/queries/queries.dart` | Add new exports |
| `lib/domain/models/screens/screens.dart` | Add new exports |

---

## Next Phase
Proceed to **Phase 1: Data Fetching Layer** after all validation passes.
