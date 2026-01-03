# Phase 1: Model Foundation

> **Status**: Not Started  
> **Effort**: 3-4 days  
> **Dependencies**: None

---

## AI Implementation Instructions

### General Guidelines
1. **Follow existing patterns** - Match code style, naming conventions, and architecture patterns already in the codebase
2. **Do NOT run or update tests** - If tests break, leave them; they will be fixed separately
3. **Run `flutter analyze` at end of phase** - Fix ALL errors and warnings before marking phase complete
4. **Format code** - Use `dart format` or the dart_format tool for Dart files

### Build Runner
- **Assume `build_runner` is running in watch mode** in background
- **Do NOT run `dart run build_runner build` manually**
- After creating/modifying freezed files, wait for `.freezed.dart` / `.g.dart` files to regenerate
- If generated files don't update after ~45 seconds, there's likely a **syntax error in the source .dart file** - review and fix

### Freezed Syntax (Project Convention)
- Use **`sealed class`** for union types (multiple factory constructors / variants):
  ```dart
  @freezed
  sealed class MyEvent with _$MyEvent {
    const factory MyEvent.started() = _Started;
    const factory MyEvent.loaded(Data data) = _Loaded;
  }
  ```
- Use **`abstract class`** for single-class models with copyWith:
  ```dart
  @freezed
  abstract class MyModel with _$MyModel {
    const factory MyModel({
      required String id,
      required String name,
    }) = _MyModel;
  }
  ```

### Compatibility - IMPORTANT
- **No backwards compatibility** - Remove old fields/code completely
- **No deprecation annotations** - Just delete obsolete code
- **No migration logic** - Clean break, assume fresh state

---

## Objective

Create a new `AllocationConfig` model with clean separation of concerns, replacing the legacy `AllocationSettings`:
- Create `AllocationConfig` as the top-level configuration
- Create `StrategySettings` for algorithm configuration (feature flags, not enum-based)
- Create `DisplaySettings` for UI preferences
- Define `AllocationPersona` and `UrgentTaskBehavior` enums
- Update `AllocatedTask` and `WarningType`
- Delete old `AllocationSettings`

---

## Files to Create

### 1. `lib/domain/models/settings/allocation_config.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'allocation_config.freezed.dart';
part 'allocation_config.g.dart';

/// Defines the allocation behavior personality.
/// 
/// Each persona represents a different approach to task prioritization:
/// - [idealist]: Pure value alignment, no urgency consideration
/// - [reflector]: Prioritizes neglected values based on recent activity
/// - [realist]: Balanced approach with urgency warnings (recommended)
/// - [firefighter]: Urgency-first, includes all urgent tasks regardless of value
/// - [custom]: User-defined settings (allows combining all features)
enum AllocationPersona {
  @JsonValue('idealist')
  idealist,

  @JsonValue('reflector')
  reflector,

  @JsonValue('realist')
  realist,

  @JsonValue('firefighter')
  firefighter,

  @JsonValue('custom')
  custom,
}

/// Defines how urgent tasks without values are handled during allocation.
/// 
/// - [ignore]: Urgent value-less tasks are excluded, no warnings
/// - [warnOnly]: Urgent value-less tasks excluded but generate warnings
/// - [includeAll]: Urgent value-less tasks included in Focus list
enum UrgentTaskBehavior {
  @JsonValue('ignore')
  ignore,

  @JsonValue('warnOnly')
  warnOnly,

  @JsonValue('includeAll')
  includeAll,
}
```

---

## Files to Modify

### 2. `lib/domain/models/settings/allocation_settings.dart`

**Remove these enums entirely:**
- `AllocationStrategyType` enum (only 2 of 6 implemented, personas replace this)
- `UrgencyMode` enum (replaced by `UrgentTaskBehavior` + persona presets)

**Remove these fields:**
- `strategyType` (replaced by persona → strategy mapping in orchestrator)
- `urgencyInfluence` (replaced by `valueAlignedUrgencyBoost`)
- `alwaysIncludeUrgent` (replaced by `urgentTaskBehavior`)
- `showExcludedUrgentWarning` (replaced by `urgentTaskBehavior`)
- `minimumTasksPerCategory` (unused, unimplemented strategy)
- `topNCategories` (unused, unimplemented strategy)

**Remove these methods:**
- `urgencyMode` getter
- `withUrgencyMode()` method

**Add these fields:**

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `persona` | `AllocationPersona` | `realist` | Active allocation persona |
| `urgentTaskBehavior` | `UrgentTaskBehavior` | `warnOnly` | How to handle urgent value-less tasks |
| `taskUrgencyThresholdDays` | `int` | `3` | Days before deadline = urgent (tasks) |
| `projectUrgencyThresholdDays` | `int` | `7` | Days before deadline = urgent (projects) |
| `valueAlignedUrgencyBoost` | `double` | `1.5` | Boost multiplier for urgent tasks with values |
| `reflectorLookbackDays` | `int` | `7` | Days to look back for neglect calculation |
| `neglectInfluence` | `double` | `0.7` | Weight of neglect score vs base weight (0-1) |
| `showOrphanTaskCount` | `bool` | `true` | Show count of value-less tasks in Focus footer |
| `showProjectNextTask` | `bool` | `true` | Show recommended next task on projects |

**Expected result structure:**
```dart
@freezed
abstract class AllocationSettings with _$AllocationSettings {
  const factory AllocationSettings({
    // Existing fields...
    @Default(10) int dailyLimit,
    @Default(AllocationMethod.urgencyWeighted) AllocationMethod allocationMethod,
    @Default(true) bool showWarnings,
    
    // NEW persona fields
    @Default(AllocationPersona.realist) AllocationPersona persona,
    @Default(UrgentTaskBehavior.warnOnly) UrgentTaskBehavior urgentTaskBehavior,
    @Default(3) int taskUrgencyThresholdDays,
    @Default(7) int projectUrgencyThresholdDays,
    @Default(1.5) double valueAlignedUrgencyBoost,
    @Default(7) int reflectorLookbackDays,
    @Default(0.7) double neglectInfluence,
    @Default(true) bool showOrphanTaskCount,
    @Default(true) bool showProjectNextTask,
  }) = _AllocationSettings;

  factory AllocationSettings.fromJson(Map<String, dynamic> json) =>
      _$AllocationSettingsFromJson(json);
}
```

---

### 3. `lib/domain/models/priority/allocation_result.dart`

**Add to `AllocatedTask`:**
```dart
/// True if this task was included due to urgency override (Firefighter mode)
/// rather than value-based allocation.
@Default(false) bool isUrgentOverride,
```

**Add to `WarningType` enum:**
```dart
/// A project's deadline is approaching within the configured threshold.
@JsonValue('projectDeadlineApproaching')
projectDeadlineApproaching,
```

---

### 4. `lib/domain/models/settings.dart`

**Add export:**
```dart
export 'settings/allocation_persona.dart';
```

---

## Step-by-Step Implementation

### Step 1: Create the enums file
Create `lib/domain/models/settings/allocation_persona.dart` with both enums.

### Step 2: Update settings barrel export
Add export to `lib/domain/models/settings.dart`.

### Step 3: Modify AllocationSettings
1. Add import for `allocation_persona.dart`
2. Remove `alwaysIncludeUrgent` field
3. Remove `showExcludedUrgentWarning` field  
4. Add all 9 new fields with defaults
5. Wait for freezed generation (~45s)

### Step 4: Update AllocatedTask
Add `isUrgentOverride` field with `@Default(false)`.

### Step 5: Update WarningType
Add `projectDeadlineApproaching` value with `@JsonValue`.

### Step 6: Fix compilation errors
After freezed regenerates, check for any usages of removed fields and update them.

### Step 7: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `allocation_persona.dart` created with `AllocationPersona` enum (5 values)
- [ ] `allocation_persona.dart` contains `UrgentTaskBehavior` enum (3 values)
- [ ] `settings.dart` exports `allocation_persona.dart`
- [ ] `AllocationSettings` has `persona` field (default: `realist`)
- [ ] `AllocationSettings` has `urgentTaskBehavior` field (default: `warnOnly`)
- [ ] `AllocationSettings` has `taskUrgencyThresholdDays` field (default: `3`)
- [ ] `AllocationSettings` has `projectUrgencyThresholdDays` field (default: `7`)
- [ ] `AllocationSettings` has `valueAlignedUrgencyBoost` field (default: `1.5`)
- [ ] `AllocationSettings` has `reflectorLookbackDays` field (default: `7`)
- [ ] `AllocationSettings` has `neglectInfluence` field (default: `0.7`)
- [ ] `AllocationSettings` has `showOrphanTaskCount` field (default: `true`)
- [ ] `AllocationSettings` has `showProjectNextTask` field (default: `true`)
- [ ] `AllocationSettings` does NOT have `alwaysIncludeUrgent` field
- [ ] `AllocationSettings` does NOT have `showExcludedUrgentWarning` field
- [ ] `AllocatedTask` has `isUrgentOverride` field (default: `false`)
- [ ] `WarningType` has `projectDeadlineApproaching` value
- [ ] `.freezed.dart` and `.g.dart` files regenerated successfully
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## Notes

- **Build runner**: Assume it's running in watch mode. After modifying freezed files, wait ~45s for regeneration.
- **No backwards compatibility**: Remove old fields completely, don't deprecate.
- **JSON serialization**: All enums use `@JsonValue` annotations for persistence.
