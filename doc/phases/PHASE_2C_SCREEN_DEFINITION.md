# Phase 2C: Screen Definition Update

## AI Implementation Instructions

- **build_runner**: Running in watch mode automatically. Do NOT run manually.
- If `.freezed.dart` or `.g.dart` files don't generate after ~30 seconds, assume syntax error in the source `.dart` file.
- **Validation**: Run `flutter analyze` after each phase/subphase. Fix ALL errors and warnings before proceeding.
- **Tests**: IGNORE tests during implementation. Do not run or update test files - do not fix errors for compilation of tests.
- **Forms**: Prefer `flutter_form_builder` fields and extensions where applicable.
- **Reuse**: Check existing patterns in codebase before creating new ones.

---

## Goal

Update `ScreenDefinition` to use `List<Section>` and `List<SupportBlock>`. Delete legacy `ViewDefinition` and `EntitySelector`.

**Decisions Implemented**: DR-017 (Unified Screen Model), Clean Slate (no backward compatibility)

---

## Prerequisites

- Phase 2A complete (Section model exists)
- Phase 2B complete (sectionsConfigConverter updated)

---

## Task 1: Update ScreenDefinition Model

**File**: `lib/domain/models/screens/screen_definition.dart`

Update the class to use the new schema:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:taskly_bloc/domain/models/screens/section.dart';
import 'package:taskly_bloc/domain/models/screens/support_block.dart';
import 'package:taskly_bloc/domain/models/screens/trigger_config.dart';

part 'screen_definition.freezed.dart';
part 'screen_definition.g.dart';

/// Type of screen
enum ScreenType {
  @JsonValue('list')
  list,
  @JsonValue('dashboard')
  dashboard,
  @JsonValue('focus')
  focus,
  @JsonValue('workflow')
  workflow,
  // Legacy - kept for migration only, will be removed
  @JsonValue('collection')
  collection,
}

/// A screen definition describing layout, sections, and support blocks.
@freezed
class ScreenDefinition with _$ScreenDefinition {
  const factory ScreenDefinition({
    required String id,
    required String name,
    required ScreenType screenType,
    /// Sections that make up the screen (DR-017)
    required List<Section> sections,
    /// Support blocks (problem indicators, navigation, etc.)
    @Default([]) List<SupportBlock> supportBlocks,
    /// Icon for display in navigation
    String? icon,
    /// Description for screen builder UI
    String? description,
    /// Whether this is a system-provided screen
    @Default(false) bool isSystem,
    /// Display order in navigation
    @Default(0) int displayOrder,
    /// Screen-level triggers
    @Default([]) List<TriggerConfig> triggers,
    /// Audit fields
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ScreenDefinition;

  const ScreenDefinition._();

  factory ScreenDefinition.fromJson(Map<String, dynamic> json) =>
      _$ScreenDefinitionFromJson(json);
}
```

**Key Changes:**
- Removed `entityType` field
- Removed `selectorConfig` field
- Removed `displayConfig` field (now per-section)
- Removed `viewType` field
- Added `sections` field (required)
- Added `supportBlocks` field
- Added `screenType` field with new enum values

---

## Task 2: Delete ViewDefinition

**Action**: DELETE FILE

**File**: `lib/domain/models/screens/view_definition.dart`

Delete this file completely - it is no longer needed.

---

## Task 3: Delete EntitySelector

**Action**: DELETE FILE

**File**: `lib/domain/models/screens/entity_selector.dart`

Delete this file completely - entity selection is now handled by `DataConfig` within sections.

---

## Task 4: Update Screens Barrel Export

**File**: `lib/domain/models/screens/screens.dart`

Remove deleted exports:

```dart
export 'data_config.dart';
export 'related_data_config.dart';
export 'section.dart';
export 'screen_definition.dart';
export 'display_config.dart';
export 'support_block.dart';
export 'screen_category.dart';
export 'trigger_config.dart';
// REMOVED: view_definition.dart
// REMOVED: entity_selector.dart
```

---

## Task 5: Find and Fix Import References

Search the codebase for any imports of the deleted files and fix them:

```bash
# Search for references (for awareness, not to run)
grep -r "view_definition.dart" lib/
grep -r "entity_selector.dart" lib/
grep -r "ViewDefinition" lib/
grep -r "EntitySelector" lib/
```

**Expected Files to Update:**
- Repository classes that used ViewDefinition
- Bloc classes that used ViewDefinition
- Widget classes that used ViewDefinition
- Any mappers or converters

**Fix Strategy:**
1. If code references ViewDefinition, update to use ScreenDefinition with sections
2. If code references EntitySelector, update to use DataConfig within Section
3. Comment out or delete code that cannot be immediately migrated (will be rebuilt in later phases)

---

## Task 6: Remove EntityType from ScreenType

**File**: `lib/data/drift/features/screen_tables.drift.dart`

The `EntityType` enum should no longer be used in screen_definitions. Verify it's removed from the table definition.

If `EntityType` is still used elsewhere in the codebase (e.g., for tasks, projects), it can remain but should not be in ScreenDefinitions.

---

## Validation Checklist

- [ ] `flutter analyze` returns 0 errors, 0 warnings (ignore test file errors)
- [ ] `view_definition.dart` deleted
- [ ] `entity_selector.dart` deleted
- [ ] `ScreenDefinition` compiles with new fields
- [ ] No import errors for deleted files
- [ ] `screens.dart` barrel exports are correct

---

## Files Deleted

| File | Reason |
|------|--------|
| `lib/domain/models/screens/view_definition.dart` | Replaced by Section |
| `lib/domain/models/screens/entity_selector.dart` | Replaced by DataConfig |

## Files Modified

| File | Change |
|------|--------|
| `lib/domain/models/screens/screen_definition.dart` | Rewrite with sections/supportBlocks |
| `lib/domain/models/screens/screens.dart` | Remove deleted exports |
| Various files with ViewDefinition imports | Fix or comment out |

---

## Migration Notes

This is a **breaking change**. All existing ScreenDefinition data in the database is now invalid. Phase 8 (System Screen Seeder) will recreate all system screens with the new structure.

---

## Next Phase

Proceed to **Phase 3A: SupportBlock Evolution** after validation passes.
