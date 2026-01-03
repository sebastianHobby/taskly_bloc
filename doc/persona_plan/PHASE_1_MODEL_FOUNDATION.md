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

> **NOTE**: This is a **single file** containing enums, config class, and nested settings classes.
> It replaces the current `allocation_settings.dart`. The old file will be deleted.

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'allocation_config.freezed.dart';
part 'allocation_config.g.dart';

// ============================================================================
// ENUMS
// ============================================================================

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

// ============================================================================
// MODELS
// ============================================================================

/// Top-level allocation configuration model.
/// 
/// Contains nested settings for strategy behavior and display preferences.
/// This replaces the old `AllocationSettings` class with a cleaner structure.
@freezed
abstract class AllocationConfig with _$AllocationConfig {
  const factory AllocationConfig({
    @Default(10) int dailyLimit,
    @Default(AllocationPersona.realist) AllocationPersona persona,
    @Default(StrategySettings()) StrategySettings strategySettings,
    @Default(DisplaySettings()) DisplaySettings displaySettings,
  }) = _AllocationConfig;

  factory AllocationConfig.fromJson(Map<String, dynamic> json) =>
      _$AllocationConfigFromJson(json);
}

/// Strategy-related settings controlling allocation behavior.
/// 
/// Uses orthogonal feature flags that can be combined (e.g., urgency + neglect).
/// Provides factory constructors for persona presets.
@freezed
abstract class StrategySettings with _$StrategySettings {
  const factory StrategySettings({
    /// How to handle urgent tasks without value alignment.
    @Default(UrgentTaskBehavior.warnOnly) UrgentTaskBehavior urgentTaskBehavior,
    
    /// Days before task deadline = urgent.
    @Default(3) int taskUrgencyThresholdDays,
    
    /// Days before project deadline = urgent.
    @Default(7) int projectUrgencyThresholdDays,
    
    /// Boost multiplier for urgent tasks with value alignment.
    /// Set to 1.0 to disable urgency boosting.
    @Default(1.0) double urgencyBoostMultiplier,
    
    /// Enable neglect-based weighting (Reflector mode feature).
    @Default(false) bool enableNeglectWeighting,
    
    /// Days to look back for neglect calculation.
    @Default(7) int neglectLookbackDays,
    
    /// Weight of neglect score vs base weight (0.0-1.0).
    /// Default 0.7 matches Reflector persona preset.
    @Default(0.7) double neglectInfluence,
  }) = _StrategySettings;

  factory StrategySettings.fromJson(Map<String, dynamic> json) =>
      _$StrategySettingsFromJson(json);

  /// Factory: Returns preset settings for the given persona.
  factory StrategySettings.forPersona(AllocationPersona persona) {
    switch (persona) {
      case AllocationPersona.idealist:
        return const StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.ignore,
          urgencyBoostMultiplier: 1.0,
          enableNeglectWeighting: false,
        );
      case AllocationPersona.reflector:
        return const StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
          urgencyBoostMultiplier: 1.0,
          enableNeglectWeighting: true,
          neglectLookbackDays: 7,
          neglectInfluence: 0.7,
        );
      case AllocationPersona.realist:
        return const StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
          urgencyBoostMultiplier: 1.5,
          enableNeglectWeighting: false,
        );
      case AllocationPersona.firefighter:
        return const StrategySettings(
          urgentTaskBehavior: UrgentTaskBehavior.includeAll,
          urgencyBoostMultiplier: 2.0,
          enableNeglectWeighting: false,
        );
      case AllocationPersona.custom:
        // Custom returns defaults - user configures individually
        return const StrategySettings();
    }
  }
}

/// Display-related settings controlling UI behavior.
/// 
/// Note: Warning visibility is controlled by `StrategySettings.urgentTaskBehavior`,
/// not by DisplaySettings. The UI simply renders whatever warnings the allocator
/// generates. Set `urgentTaskBehavior = ignore` to suppress urgent task warnings.
@freezed
abstract class DisplaySettings with _$DisplaySettings {
  const factory DisplaySettings({
    /// Show count of value-less tasks in Focus list footer.
    @Default(true) bool showOrphanTaskCount,
    
    /// Show recommended next task on project cards.
    @Default(true) bool showProjectNextTask,
  }) = _DisplaySettings;

  factory DisplaySettings.fromJson(Map<String, dynamic> json) =>
      _$DisplaySettingsFromJson(json);
}
```

---

### 3. Delete `lib/domain/models/settings/allocation_settings.dart`

This file is completely replaced by `allocation_config.dart`. Delete it entirely.

**Remove these types:**
- `AllocationStrategyType` enum (only 2 of 6 implemented, personas replace this)
- `AllocationSettings` class (replaced by `AllocationConfig`)

---

### 4. `lib/domain/models/priority/allocation_result.dart`

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

### 5. `lib/domain/models/settings.dart`

**Update exports:**
```dart
// Remove this line:
// export 'settings/allocation_settings.dart';

// Add this line (single file contains enums + classes):
export 'settings/allocation_config.dart';
```

---

## Step-by-Step Implementation

### Step 1: Create the config file (single file with enums + classes)
Create `lib/domain/models/settings/allocation_config.dart` containing:
- `AllocationPersona` enum (5 values)
- `UrgentTaskBehavior` enum (3 values)
- `AllocationConfig` class (top-level config)
- `StrategySettings` class (algorithm settings)
- `DisplaySettings` class (UI preferences)

### Step 2: Update settings barrel export
Update `lib/domain/models/settings.dart` to export the new file.

### Step 4: Delete old settings file
Delete `lib/domain/models/settings/allocation_settings.dart`.

### Step 5: Wait for freezed generation
Wait ~45s for build_runner to regenerate `.freezed.dart` and `.g.dart` files.

### Step 6: Update AllocatedTask
Add `isUrgentOverride` field with `@Default(false)`.

### Step 7: Update WarningType
Add `projectDeadlineApproaching` value with `@JsonValue`.

### Step 8: Fix compilation errors
After freezed regenerates, find all usages of `AllocationSettings` and update them to use `AllocationConfig`.

### Step 9: Run flutter analyze
```bash
flutter analyze
```
Fix all errors and warnings.

---

## Verification Checklist

- [ ] `allocation_config.dart` created as single file containing:
  - [ ] `AllocationPersona` enum (5 values: idealist, reflector, realist, firefighter, custom)
  - [ ] `UrgentTaskBehavior` enum (3 values: ignore, warnOnly, includeAll)
  - [ ] `AllocationConfig` class (top-level config)
  - [ ] `StrategySettings` class (with feature flags)
  - [ ] `DisplaySettings` class (UI preferences)
- [ ] `StrategySettings.forPersona()` factory returns correct presets
- [ ] `allocation_settings.dart` has been deleted
- [ ] `settings.dart` exports new files, not old file
- [ ] `AllocationConfig` has `dailyLimit` field (default: `10`)
- [ ] `AllocationConfig` has `persona` field (default: `realist`)
- [ ] `AllocationConfig` has nested `strategy` field (type: `StrategySettings`)
- [ ] `AllocationConfig` has nested `display` field (type: `DisplaySettings`)
- [ ] `StrategySettings` has `urgencyBoostMultiplier` field (default: `1.0`)
- [ ] `StrategySettings` has `enableNeglectWeighting` field (default: `false`)
- [ ] `AllocatedTask` has `isUrgentOverride` field (default: `false`)
- [ ] `WarningType` has `projectDeadlineApproaching` value
- [ ] `.freezed.dart` and `.g.dart` files regenerated successfully
- [ ] `flutter analyze` passes with 0 errors and 0 warnings

---

## Notes

- **Greenfield approach**: This is a complete replacement, not a migration. Delete old file, create new file.
- **Build runner**: Assume it's running in watch mode. After modifying freezed files, wait ~45s for regeneration.
- **Feature flags are orthogonal**: `urgencyBoostMultiplier` and `enableNeglectWeighting` can both be enabled for Custom mode combos.
- **JSON serialization**: All enums use `@JsonValue` annotations for persistence.
- **Persona presets**: `StrategySettings.forPersona()` provides the starting point; users can modify from there.
