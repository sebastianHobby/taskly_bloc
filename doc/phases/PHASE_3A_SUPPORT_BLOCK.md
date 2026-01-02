# Phase 3A: SupportBlock Evolution

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Enhance `SupportBlock` with new variants including `ProblemSummaryBlock` and mark system-only blocks.

**Decisions Implemented**: DR-018 (Problem Detection as SupportBlock), DR-019 (System-only blocks)

---

## Prerequisites

- Phase 2C complete (ScreenDefinition updated)

---

## Task 1: Review Existing SupportBlock

First, read the existing `support_block.dart` file to understand current structure.

**File**: `lib/domain/models/screens/support_block.dart`

The existing file should have these variants (implemented previously):
- `WorkflowProgressBlock` - Shows workflow step progress
- `QuickActionsBlock` - Shows quick action buttons
- `ContextSummaryBlock` - Shows context/project info
- `RelatedEntitiesBlock` - Shows related items
- `StatsBlock` - Shows statistics

---

## Task 2: Add ProblemSummaryBlock

**File**: `lib/domain/models/screens/support_block.dart`

Add the new `ProblemSummaryBlock` variant to the sealed class:

```dart
/// Shows a summary of detected problems (DR-018)
/// Can display counts, list, or both based on configuration
@FreezedUnionValue('problemSummary')
const factory SupportBlock.problemSummary({
  /// Problem types to include (null = all)
  List<String>? problemTypes,
  /// Show count badge
  @Default(true) bool showCount,
  /// Show problem list (expandable)
  @Default(false) bool showList,
  /// Maximum problems to show in list
  @Default(5) int maxListItems,
  /// Custom title (default: "Issues")
  String? title,
  /// Position in support section
  @Default(0) int order,
}) = ProblemSummaryBlock;
```

---

## Task 3: Add System-Only Flag

Per DR-019, some blocks should only be added by the system, not by users in the screen builder.

Add documentation and a helper method:

```dart
/// Extension methods for SupportBlock
extension SupportBlockExtensions on SupportBlock {
  /// Whether this block type can only be added by the system (DR-019).
  /// Users cannot add these in the screen builder UI.
  bool get isSystemOnly => switch (this) {
        WorkflowProgressBlock() => true,
        _ => false,
      };

  /// Whether this block type is available in the screen builder UI.
  bool get isUserConfigurable => !isSystemOnly;
}
```

---

## Task 4: Add Optional EmptyStateBlock

For consistency in displaying empty states:

```dart
/// Shows a custom empty state message when section has no data
@FreezedUnionValue('emptyState')
const factory SupportBlock.emptyState({
  required String message,
  String? icon,
  String? actionLabel,
  String? actionRoute,
  @Default(0) int order,
}) = EmptyStateBlock;
```

---

## Task 5: Complete SupportBlock File

Ensure the complete file looks like:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'support_block.freezed.dart';
part 'support_block.g.dart';

/// Support blocks provide auxiliary UI elements for screens (DR-018, DR-019).
/// These are rendered in a designated support section, typically above or beside main content.
@Freezed(unionKey: 'type')
sealed class SupportBlock with _$SupportBlock {
  /// Shows workflow step progress (system-only per DR-019)
  @FreezedUnionValue('workflowProgress')
  const factory SupportBlock.workflowProgress({
    @Default(0) int order,
  }) = WorkflowProgressBlock;

  /// Shows quick action buttons
  @FreezedUnionValue('quickActions')
  const factory SupportBlock.quickActions({
    required List<QuickAction> actions,
    @Default(0) int order,
  }) = QuickActionsBlock;

  /// Shows context/project information summary
  @FreezedUnionValue('contextSummary')
  const factory SupportBlock.contextSummary({
    String? title,
    @Default(true) bool showDescription,
    @Default(true) bool showMetadata,
    @Default(0) int order,
  }) = ContextSummaryBlock;

  /// Shows related entities as links/chips
  @FreezedUnionValue('relatedEntities')
  const factory SupportBlock.relatedEntities({
    required List<String> entityTypes,
    @Default(5) int maxItems,
    @Default(0) int order,
  }) = RelatedEntitiesBlock;

  /// Shows statistics/metrics
  @FreezedUnionValue('stats')
  const factory SupportBlock.stats({
    required List<StatConfig> stats,
    @Default(0) int order,
  }) = StatsBlock;

  /// Shows a summary of detected problems (DR-018)
  @FreezedUnionValue('problemSummary')
  const factory SupportBlock.problemSummary({
    List<String>? problemTypes,
    @Default(true) bool showCount,
    @Default(false) bool showList,
    @Default(5) int maxListItems,
    String? title,
    @Default(0) int order,
  }) = ProblemSummaryBlock;

  /// Shows a custom empty state message
  @FreezedUnionValue('emptyState')
  const factory SupportBlock.emptyState({
    required String message,
    String? icon,
    String? actionLabel,
    String? actionRoute,
    @Default(0) int order,
  }) = EmptyStateBlock;

  factory SupportBlock.fromJson(Map<String, dynamic> json) =>
      _$SupportBlockFromJson(json);
}

/// A quick action button configuration
@freezed
class QuickAction with _$QuickAction {
  const factory QuickAction({
    required String label,
    required String actionId,
    String? icon,
    Map<String, dynamic>? params,
  }) = _QuickAction;

  factory QuickAction.fromJson(Map<String, dynamic> json) =>
      _$QuickActionFromJson(json);
}

/// A statistic configuration
@freezed
class StatConfig with _$StatConfig {
  const factory StatConfig({
    required String label,
    required String metricId,
    String? format,
    String? icon,
  }) = _StatConfig;

  factory StatConfig.fromJson(Map<String, dynamic> json) =>
      _$StatConfigFromJson(json);
}

/// Extension methods for SupportBlock
extension SupportBlockExtensions on SupportBlock {
  /// Whether this block type can only be added by the system (DR-019).
  bool get isSystemOnly => switch (this) {
        WorkflowProgressBlock() => true,
        _ => false,
      };

  /// Whether this block type is available in the screen builder UI.
  bool get isUserConfigurable => !isSystemOnly;
}
```

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `support_block.freezed.dart` regenerated
- [ ] `support_block.g.dart` regenerated
- [ ] `ProblemSummaryBlock` variant exists
- [ ] `EmptyStateBlock` variant exists
- [ ] `isSystemOnly` extension works
- [ ] `WorkflowProgressBlock().isSystemOnly == true`
- [ ] `QuickActionsBlock(...).isSystemOnly == false`

---

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/models/screens/support_block.dart` | Add new variants, extension |

---

## Next Phase

Proceed to **Phase 3B: SupportBlock Integration** after validation passes.
