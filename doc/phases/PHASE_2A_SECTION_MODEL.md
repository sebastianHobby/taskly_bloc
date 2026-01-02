# Phase 2A: Section Model

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Create the `Section` sealed class and supporting types (`DataConfig`, `RelatedDataConfig`).

**Decisions Implemented**: DR-001, DR-002, DR-005, DR-017

---

## Prerequisites

- Phase 1A complete (LabelQuery exists)
- Phase 1B complete (LabelMatchMode exists)

---

## Task 1: Create DataConfig

**File**: `lib/domain/models/screens/data_config.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';
import 'package:taskly_bloc/domain/queries/label_query.dart';

part 'data_config.freezed.dart';
part 'data_config.g.dart';

/// Configuration for fetching a single entity type.
/// Each variant embeds its query directly (DR-002).
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

  /// Label data configuration (excludes values by default)
  @FreezedUnionValue('label')
  const factory DataConfig.label({
    LabelQuery? query,
  }) = LabelDataConfig;

  /// Value data configuration (DR-003: values are labels with type=value)
  @FreezedUnionValue('value')
  const factory DataConfig.value({
    LabelQuery? query,
  }) = ValueDataConfig;

  factory DataConfig.fromJson(Map<String, dynamic> json) =>
      _$DataConfigFromJson(json);
}
```

---

## Task 2: Create RelatedDataConfig

**File**: `lib/domain/models/screens/related_data_config.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/queries/task_query.dart';
import 'package:taskly_bloc/domain/queries/project_query.dart';

part 'related_data_config.freezed.dart';
part 'related_data_config.g.dart';

/// Configuration for fetching related entities within a section.
/// Related entities have a parent-child relationship with the primary entity.
@Freezed(unionKey: 'type')
sealed class RelatedDataConfig with _$RelatedDataConfig {
  /// Tasks related to primary entity (project, label, or value)
  @FreezedUnionValue('tasks')
  const factory RelatedDataConfig.tasks({
    TaskQuery? additionalFilter,
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
    @Default(true) bool includeInheritedTasks,
    ProjectQuery? projectFilter,
    TaskQuery? taskFilter,
  }) = ValueHierarchyConfig;

  factory RelatedDataConfig.fromJson(Map<String, dynamic> json) =>
      _$RelatedDataConfigFromJson(json);
}
```

---

## Task 3: Create Section Sealed Class

**File**: `lib/domain/models/screens/section.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/data_config.dart';
import 'package:taskly_bloc/domain/models/screens/related_data_config.dart';
import 'package:taskly_bloc/domain/models/screens/display_config.dart';

part 'section.freezed.dart';
part 'section.g.dart';

/// A section within a screen (DR-017: Unified Screen Model).
/// All screens are composed of 1+ sections.
@Freezed(unionKey: 'type')
sealed class Section with _$Section {
  /// Data section displaying entities
  @FreezedUnionValue('data')
  const factory Section.data({
    required DataConfig config,
    @Default([]) List<RelatedDataConfig> relatedData,
    /// Display configuration (grouping, sorting, etc.)
    DisplayConfig? display,
    /// Optional section title
    String? title,
  }) = DataSection;

  /// Allocation section (Focus/Next Actions - uses AllocationOrchestrator)
  @FreezedUnionValue('allocation')
  const factory Section.allocation({
    /// Source filter for allocation (optional - defaults to all tasks)
    TaskQuery? sourceFilter,
    /// Max tasks to allocate (overrides global setting if set)
    int? maxTasks,
    /// Optional section title
    String? title,
  }) = AllocationSection;

  /// Agenda section (date-grouped tasks like Today, Upcoming)
  @FreezedUnionValue('agenda')
  const factory Section.agenda({
    required AgendaDateField dateField,
    @Default(AgendaGrouping.standard) AgendaGrouping grouping,
    /// Additional filter on top of date grouping
    TaskQuery? additionalFilter,
    /// Optional section title
    String? title,
  }) = AgendaSection;

  factory Section.fromJson(Map<String, dynamic> json) =>
      _$SectionFromJson(json);
}

/// Date field for agenda grouping
enum AgendaDateField {
  @JsonValue('deadline_date')
  deadlineDate,
  @JsonValue('start_date')
  startDate,
  @JsonValue('scheduled_for')
  scheduledFor,
}

/// Grouping strategy for agenda sections
enum AgendaGrouping {
  @JsonValue('standard')
  standard, // Today, Tomorrow, This Week, Later
  @JsonValue('by_date')
  byDate, // Group by actual date
  @JsonValue('overdue_first')
  overdueFirst, // Overdue, Today, Tomorrow, etc.
}
```

**Note**: NavigationSection removed per DR-001. Support blocks are handled separately at screen level.

---

## Task 4: Update Screens Barrel Export

**File**: `lib/domain/models/screens/screens.dart`

Create or update to include:

```dart
export 'data_config.dart';
export 'related_data_config.dart';
export 'section.dart';
// Existing exports
export 'screen_definition.dart';
export 'display_config.dart';
export 'support_block.dart';
export 'screen_category.dart';
export 'trigger_config.dart';
// Legacy (to be removed in Phase 2C)
export 'view_definition.dart';
export 'entity_selector.dart';
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `data_config.freezed.dart` generated
- [ ] `data_config.g.dart` generated
- [ ] `related_data_config.freezed.dart` generated
- [ ] `related_data_config.g.dart` generated
- [ ] `section.freezed.dart` generated
- [ ] `section.g.dart` generated
- [ ] Can instantiate `Section.data(config: DataConfig.task(query: TaskQuery()))` without errors
- [ ] Can instantiate `Section.allocation()` without errors

---

## Files Created

| File | Purpose |
|------|---------|
| `lib/domain/models/screens/data_config.dart` | Primary entity configuration |
| `lib/domain/models/screens/related_data_config.dart` | Related entity configuration |
| `lib/domain/models/screens/section.dart` | Section sealed class |

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/models/screens/screens.dart` | Add new exports |

---

## Next Phase

Proceed to **Phase 2B: Schema Update** after validation passes.
