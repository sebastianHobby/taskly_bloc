# Allocation Personas Implementation Plan

> **Status**: Planning  
> **Created**: 2026-01-03  
> **Source**: [VALUES_SCREEN_CONCEPT.md](../concepts/VALUES_SCREEN_CONCEPT.md)

---

## AI Implementation Instructions

### General Guidelines
1. **Follow existing patterns** - Match code style, naming conventions, and architecture patterns already in the codebase
2. **Do NOT run or update tests** - If tests break, leave them; they will be fixed separately
3. **Run `flutter analyze` at end of each phase** - Fix ALL errors and warnings before marking phase complete
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

### Domain Layer Rules
- Models must be immutable (`@immutable` annotation for non-freezed classes)
- JSON serialization via `fromJson`/`toJson` methods
- Enums should have `@JsonValue` annotations for persistence

### Service Layer Rules
- Services should depend on repository contracts, not implementations
- Use constructor injection for dependencies
- Keep business logic in services, not BLoCs

### Presentation Layer Rules
- Use BLoC pattern for state management
- Widgets should be stateless where possible
- Use `context.l10n` for all user-facing strings
- Follow Material 3 theming conventions

### Compatibility - IMPORTANT
- **No backwards compatibility** - Remove old fields/code completely
- **No deprecation annotations** - Just delete obsolete code
- **No migration logic** - Clean break, assume fresh state
- Update `fromJson`/`toJson` to only handle new schema

---

## Architecture Decisions

### Personas as Templates
Personas are **high-level templates** that configure detailed allocation settings. Users select a persona, which sets sensible defaults. The "Custom" persona reveals all underlying settings for power users and allows combining features (e.g., urgency boost + neglect weighting together).

### Model Architecture

The allocation system uses a **greenfield redesign** with clean separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                     AllocationConfig                        │
│  (Top-level user preferences - replaces AllocationSettings) │
├─────────────────────────────────────────────────────────────┤
│  persona: AllocationPersona         // Template selector    │
│  dailyLimit: int                    // Max tasks in Focus   │
│  strategySettings: StrategySettings // Algorithm config     │
│  displaySettings: DisplaySettings   // UI preferences       │
└─────────────────────────────────────────────────────────────┘
```

### Feature-Based Strategy Settings

Instead of mutually exclusive strategy types, allocation features are **orthogonal flags** that can be combined:

```dart
@freezed
abstract class StrategySettings with _$StrategySettings {
  const factory StrategySettings({
    // Urgency features
    @Default(UrgentTaskBehavior.warnOnly) UrgentTaskBehavior urgentTaskBehavior,
    @Default(3) int taskUrgencyThresholdDays,
    @Default(7) int projectUrgencyThresholdDays,
    @Default(1.5) double urgencyBoostMultiplier,  // 1.0 = disabled
    
    // Neglect features (Reflector)
    @Default(false) bool enableNeglectWeighting,
    @Default(7) int neglectLookbackDays,
    @Default(0.5) double neglectInfluence,
  }) = _StrategySettings;
}
```

### Auto-Switch to Custom on Modification
When a user modifies ANY setting from a preset persona, the system automatically switches to `AllocationPersona.custom`. This provides a clear mental model: presets are presets, any deviation = custom.

### Code to REMOVE (Redundant Under New Model)

| Item | Reason |
|------|--------|
| `AllocationSettings` class | Replaced by `AllocationConfig` with nested settings |
| `AllocationStrategyType` enum | Only 2 of 6 values implemented; feature flags replace this |
| `UrgencyMode` enum | Replaced by `UrgentTaskBehavior` + persona presets |
| `withUrgencyMode()` method | No longer needed |
| `urgencyMode` getter | No longer needed |
| `urgencyInfluence` field | Replaced by `urgencyBoostMultiplier` (different semantic) |
| `alwaysIncludeUrgent` field | Replaced by `UrgentTaskBehavior.includeAll` |
| `showExcludedUrgentWarning` field | Replaced by `UrgentTaskBehavior.warnOnly` |
| `minimumTasksPerCategory` field | Unused, unimplemented strategy |
| `topNCategories` field | Unused, unimplemented strategy |

### Code to KEEP

| Item | Reason |
|------|--------|
| `AllocationStrategy` interface | Core abstraction for pluggable allocators |
| `ProportionalAllocator` | Used by Idealist persona |
| `UrgencyWeightedAllocator` | Used by Realist/Firefighter personas |
| `ValueRanking` / `ValueRankItem` | Existing value weight storage |
| `pinTask()`/`unpinTask()` | Existing functionality, reused in Phase 5 |

### Persona → Features Mapping

| Persona | urgentTaskBehavior | urgencyBoostMultiplier | enableNeglectWeighting | neglectInfluence |
|---------|-------------------|------------------------|------------------------|------------------|
| **Idealist** | `ignore` | `1.0` (disabled) | `false` | - |
| **Reflector** | `warnOnly` | `1.0` (disabled) | `true` | `0.7` |
| **Realist** | `warnOnly` | `1.5` | `false` | - |
| **Firefighter** | `includeAll` | `2.0` | `false` | - |
| **Custom** | *user choice* | *user choice* | *user choice* | *user choice* |

### Custom Mode: Combining Features

The Custom persona allows combining urgency and neglect features together:

```dart
// Example: Urgency boost + Neglect weighting combo
StrategySettings(
  urgentTaskBehavior: UrgentTaskBehavior.warnOnly,
  urgencyBoostMultiplier: 1.5,  // Urgent tasks with values get boosted
  enableNeglectWeighting: true,  // ALSO adjust weights by neglect
  neglectInfluence: 0.5,
)
// Result: Neglected values get weight boost, then urgent tasks within those get score boost
```

### Orchestrator Strategy Selection

```dart
AllocationStrategy _selectStrategy(StrategySettings settings) {
  // Neglect takes precedence if enabled
  if (settings.enableNeglectWeighting) {
    return NeglectBasedAllocator(
      lookbackDays: settings.neglectLookbackDays,
      neglectInfluence: settings.neglectInfluence,
      urgencyBoostMultiplier: settings.urgencyBoostMultiplier,
    );
  }
  
  // Urgency-weighted if boost > 1.0
  if (settings.urgencyBoostMultiplier > 1.0) {
    return UrgencyWeightedAllocator();
  }
  
  // Default: pure proportional
  return ProportionalAllocator();
}
```

### Localization Requirements
- All UI strings must be added to both `app_en.arb` (English) and `app_es.arb` (Spanish)
- Follow existing pattern in the arb files
- Add strings within each phase, not deferred

---

## Phase Summary

| Phase | Name | Effort | Dependencies |
|-------|------|--------|--------------|
| 1 | Model Foundation | 3-4 days | None |
| 2 | Urgency Unification | 2-3 days | Phase 1 |
| 3 | Persona Selection UI | 2-3 days | Phase 1 |
| 4 | Orphan Task Handling | 1-2 days | Phase 2 |
| 5 | Project Enhancements | 3-4 days | Phase 2 |
| 6 | Reflector Mode | 4-5 days | Phase 2 |
| 7 | Enhanced Values Screen | 5-7 days | Phase 2, 6 |
| 8 | Values Gateway | 1-2 days | Phase 1 |

**Total Estimate**: 21-30 days

---

## Phase 1: Model Foundation

**Goal**: Create new `AllocationConfig` model with nested `StrategySettings` and `DisplaySettings`, replacing the old `AllocationSettings`.

### Files to Create
| File | Purpose |
|------|---------|
| `lib/domain/models/settings/allocation_config.dart` | New top-level config with `AllocationPersona`, `StrategySettings`, `DisplaySettings` |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/domain/models/settings/allocation_settings.dart` | DELETE entirely (replaced by `allocation_config.dart`) |
| `lib/domain/models/priority/allocation_result.dart` | Add `isUrgentOverride` to `AllocatedTask`, add `projectDeadlineApproaching` to `WarningType` |
| `lib/domain/models/settings.dart` | Update exports |
| `lib/domain/interfaces/settings_repository_contract.dart` | Update method signatures |
| `lib/data/repositories/settings_repository.dart` | Update implementation |

### New Enums
```dart
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

enum UrgentTaskBehavior {
  @JsonValue('ignore')
  ignore,
  @JsonValue('warnOnly')
  warnOnly,
  @JsonValue('includeAll')
  includeAll,
}
```

### New Models Structure
```dart
@freezed
abstract class AllocationConfig with _$AllocationConfig {
  const factory AllocationConfig({
    @Default(AllocationPersona.realist) AllocationPersona persona,
    @Default(10) int dailyLimit,
    @Default(StrategySettings()) StrategySettings strategySettings,
    @Default(DisplaySettings()) DisplaySettings displaySettings,
  }) = _AllocationConfig;
}

@freezed
abstract class StrategySettings with _$StrategySettings {
  const factory StrategySettings({
    @Default(UrgentTaskBehavior.warnOnly) UrgentTaskBehavior urgentTaskBehavior,
    @Default(3) int taskUrgencyThresholdDays,
    @Default(7) int projectUrgencyThresholdDays,
    @Default(1.5) double urgencyBoostMultiplier,
    @Default(false) bool enableNeglectWeighting,
    @Default(7) int neglectLookbackDays,
    @Default(0.5) double neglectInfluence,
  }) = _StrategySettings;
  
  factory StrategySettings.forPersona(AllocationPersona persona);
}

@freezed
abstract class DisplaySettings with _$DisplaySettings {
  const factory DisplaySettings({
    @Default(true) bool showWarnings,
    @Default(true) bool showOrphanTaskCount,
    @Default(true) bool showProjectNextTask,
  }) = _DisplaySettings;
}
```

### Acceptance Criteria
- [ ] `AllocationConfig` model created with nested settings
- [ ] `StrategySettings` has all urgency and neglect fields
- [ ] `StrategySettings.forPersona()` factory returns correct presets
- [ ] `DisplaySettings` has UI preference fields
- [ ] Old `AllocationSettings` file deleted
- [ ] `AllocatedTask` has `isUrgentOverride` field
- [ ] `WarningType` has `projectDeadlineApproaching` value
- [ ] Repository contracts and implementations updated
- [ ] `flutter analyze` passes with no errors/warnings

---

## Phase 2: Urgency Unification

**Goal**: Create shared urgency detection and implement `UrgentTaskBehavior` logic in allocators.

### Files to Create
| File | Purpose |
|------|---------|
| `lib/domain/services/allocation/urgency_detector.dart` | Shared urgency detection logic |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/domain/services/allocation/allocation_orchestrator.dart` | Use `UrgencyDetector`, handle `UrgentTaskBehavior`, generate project warnings, use `AllocationConfig` |
| `lib/domain/services/allocation/allocation_strategy.dart` | Update `AllocationParameters` to accept `StrategySettings` |
| `lib/domain/services/allocation/proportional_allocator.dart` | Use `UrgentTaskBehavior` from settings |
| `lib/domain/services/allocation/urgency_weighted_allocator.dart` | Handle `includeAll` to include value-less urgent tasks, use `urgencyBoostMultiplier` |

### UrgencyDetector Interface
```dart
class UrgencyDetector {
  const UrgencyDetector({
    required this.taskThresholdDays,
    required this.projectThresholdDays,
  });
  
  final int taskThresholdDays;
  final int projectThresholdDays;
  
  bool isTaskUrgent(Task task);
  bool isProjectUrgent(Project project);
  List<Task> findUrgentTasks(List<Task> tasks);
  List<Project> findUrgentProjects(List<Project> projects);
  List<Task> findUrgentValuelessTasks(List<Task> tasks);
  
  factory UrgencyDetector.fromSettings(StrategySettings settings);
}
```

### Acceptance Criteria
- [ ] `UrgencyDetector` class created with task/project methods
- [ ] Hardcoded `urgencyThresholdDays = 3` removed from orchestrator
- [ ] `AllocationParameters` accepts `StrategySettings`
- [ ] `includeAll` behavior includes value-less urgent tasks in Focus with `isUrgentOverride = true`
- [ ] `warnOnly` generates warnings for excluded urgent tasks
- [ ] `ignore` produces no warnings for urgent tasks
- [ ] Project deadline warnings generated using `projectDeadlineApproaching`
- [ ] `flutter analyze` passes with no errors/warnings

---

## Phase 3: Persona Selection UI

**Goal**: Replace technical strategy selection with persona-based UI, with auto-switch to Custom on any modification.

### Files to Create
| File | Purpose |
|------|---------|
| `lib/presentation/features/next_action/widgets/persona_selection_card.dart` | Card widget for each persona |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/presentation/features/next_action/view/allocation_settings_page.dart` | Complete redesign with persona selection, uses `AllocationConfig` |

### UI Requirements
- Persona selection cards (Idealist, Reflector, Realist, Firefighter, Custom)
- "Recommended" badge on Realist
- Expandable "How it works" for each persona
- Threshold settings section (task days, project days)
- Display toggles (orphan count, project next task)
- Daily limit input
- Custom mode shows all settings when selected
- **Auto-switch to Custom when ANY setting is modified from preset**

### Auto-Switch Behavior
```dart
void _onSettingChanged<T>(T currentValue, T newValue, T presetValue) {
  if (_config.persona != AllocationPersona.custom && newValue != presetValue) {
    setState(() {
      _config = _config.copyWith(persona: AllocationPersona.custom);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switched to Custom mode')),
    );
  }
}
```

### Acceptance Criteria
- [ ] `PersonaSelectionCard` widget created
- [ ] Settings page shows 5 persona options
- [ ] Selecting persona applies preset via `StrategySettings.forPersona()`
- [ ] **Auto-switch to Custom when any setting is modified from preset**
- [ ] Custom persona reveals full settings panel (urgency + neglect features)
- [ ] Threshold inputs functional
- [ ] Display toggles functional
- [ ] `flutter analyze` passes with no errors/warnings

---

## Phase 4: Orphan Task Handling

**Goal**: Show count of tasks without values in Focus footer.

### Files to Create
| File | Purpose |
|------|---------|
| `lib/presentation/features/next_action/widgets/orphan_task_footer.dart` | Footer showing orphan count |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/domain/services/analytics/analytics_service.dart` | Add `getOrphanTaskCount` method |
| `lib/data/features/analytics/services/analytics_service_impl.dart` | Implement `getOrphanTaskCount` |
| `lib/presentation/features/next_action/view/next_actions_page.dart` | Add orphan footer when enabled |

### Analytics Method
```dart
/// Get count of tasks without values (and optionally without deadlines)
Future<int> getOrphanTaskCount({bool excludeWithDeadline = false});
```

### Acceptance Criteria
- [ ] `getOrphanTaskCount` method added to analytics service
- [ ] `OrphanTaskFooter` widget created
- [ ] Footer shows count and "View" button
- [ ] Footer respects `showOrphanTaskCount` setting
- [ ] Tapping "View" navigates to orphan task list
- [ ] `flutter analyze` passes with no errors/warnings

---

## Phase 5: Project Enhancements

**Goal**: Add project deadline warnings and "Next Task" recommendation.

### Files to Create
| File | Purpose |
|------|---------|
| `lib/domain/services/allocation/project_next_task_resolver.dart` | Determines recommended next task for a project |
| `lib/presentation/features/projects/widgets/project_next_task_card.dart` | Card showing recommended task |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/domain/services/allocation/allocation_orchestrator.dart` | Generate project deadline warnings |
| `lib/presentation/features/projects/view/project_list_view.dart` | Show next task in list tiles |
| `lib/presentation/features/projects/view/project_detail_view.dart` | Show recommended task header |

### ProjectNextTaskResolver Interface
```dart
class ProjectNextTaskResolver {
  Task? getNextTask({
    required Project project,
    required List<Task> projectTasks,
    required AllocationSettings settings,
  });
}
```

### Acceptance Criteria
- [ ] `ProjectNextTaskResolver` class created
- [ ] Project deadline warnings generated when within threshold
- [ ] Project list tiles show "→ Next: [task name]"
- [ ] Project detail shows highlighted "Recommended Next Action" card
- [ ] "Start" button pins task to Focus
- [ ] Respects `showProjectNextTask` setting
- [ ] `flutter analyze` passes with no errors/warnings

---

## Phase 6: Reflector Mode

**Goal**: Implement neglect-based allocation for Reflector persona, with support for combining with urgency features in Custom mode.

### Files to Create
| File | Purpose |
|------|---------|
| `lib/domain/services/allocation/neglect_based_allocator.dart` | Allocator that prioritizes neglected values, optionally applies urgency boost |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/domain/services/analytics/analytics_service.dart` | Add `getRecentCompletionsByValue` method |
| `lib/data/features/analytics/services/analytics_service_impl.dart` | Implement completions query |
| `lib/domain/services/allocation/allocation_orchestrator.dart` | Use neglect allocator when `enableNeglectWeighting` is true |

### NeglectBasedAllocator
```dart
class NeglectBasedAllocator implements AllocationStrategy {
  const NeglectBasedAllocator({
    required this.lookbackDays,
    required this.neglectInfluence,
    required this.urgencyBoostMultiplier,  // Supports combo with urgency
  });
  
  // When urgencyBoostMultiplier > 1.0, applies urgency boost AFTER neglect weighting
}
```

### Algorithm
```
For each value:
  recentCompletions = countCompletions(value, last N days)
  expectedCompletions = totalCompletions * (valueWeight / totalWeight)
  neglectScore = expectedCompletions - recentCompletions

// Higher neglectScore = prioritized in Focus
// Values you've been ignoring rise to the top

// If urgencyBoostMultiplier > 1.0, also apply urgency boost to urgent tasks
```

### Acceptance Criteria
- [ ] `getRecentCompletionsByValue` method added to analytics
- [ ] `NeglectBasedAllocator` class created implementing `AllocationStrategy`
- [ ] Allocator accepts `urgencyBoostMultiplier` for Custom combo mode
- [ ] Reflector persona uses neglect-based allocation
- [ ] Lookback period configurable via `neglectLookbackDays`
- [ ] `neglectInfluence` controls blend with base value weights
- [ ] **Custom mode can enable neglect + urgency boost together**
- [ ] `flutter analyze` passes with no errors/warnings

---

## Phase 7: Enhanced Values Screen

**Goal**: Transform simple values list into rich dashboard with statistics and trends.

### Files to Create
| File | Purpose |
|------|---------|
| `lib/presentation/features/labels/widgets/enhanced_value_card.dart` | Rich card with stats |
| `lib/presentation/features/labels/widgets/value_detail_modal.dart` | Expandable detail view |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/domain/services/analytics/analytics_service.dart` | Add value distribution methods |
| `lib/data/features/analytics/services/analytics_service_impl.dart` | Implement value analytics |
| `lib/presentation/features/labels/view/value_overview_view.dart` | Major rewrite with new cards |

### New Analytics Methods
```dart
/// Get completion distribution by value over a date range
Future<Map<String, double>> getValueCompletionDistribution({
  required DateRange range,
});

/// Get active task/project count per value
Future<Map<String, ValueActivityStats>> getValueActivityStats();
```

### UI Features
- Drag-to-reorder with auto-weight calculation
- Actual % vs Target % display
- Gap warnings (±15% threshold)
- 4-week trend sparkline
- Mood correlation per value
- "Unassigned Work" section at bottom

### Acceptance Criteria
- [ ] `getValueCompletionDistribution` method added
- [ ] `getValueActivityStats` method added
- [ ] `EnhancedValueCard` shows rank, weight, actual %, target %, gap
- [ ] Drag-to-reorder updates weights automatically
- [ ] `ValueDetailModal` shows trend chart and correlation
- [ ] Unassigned work section displays at bottom
- [ ] `flutter analyze` passes with no errors/warnings

---

## Phase 8: Values Gateway

**Goal**: Require values setup before using Focus/allocation features.

### Files to Create
| File | Purpose |
|------|---------|
| `lib/presentation/features/next_action/widgets/values_required_gateway.dart` | Full-screen prompt |

### Files to Modify
| File | Changes |
|------|---------|
| `lib/presentation/features/next_action/view/next_actions_page.dart` | Show gateway when 0 values |

### UI Requirements
- Full-screen when user has 0 values defined
- Explains purpose of values
- "Set Up My Values" button → navigates to values screen
- "Show all tasks by deadline only" skip option
- Remember skip preference

### Acceptance Criteria
- [ ] `ValuesRequiredGateway` widget created
- [ ] Gateway shown when `valueLabels.isEmpty`
- [ ] "Set Up" navigates to values screen
- [ ] "Skip" option available with preference storage
- [ ] `flutter analyze` passes with no errors/warnings

---

## File Change Summary

### New Files (11)
```
lib/domain/models/settings/allocation_config.dart
lib/domain/services/allocation/urgency_detector.dart
lib/domain/services/allocation/neglect_based_allocator.dart
lib/domain/services/allocation/project_next_task_resolver.dart
lib/presentation/features/next_action/widgets/persona_selection_card.dart
lib/presentation/features/next_action/widgets/orphan_task_footer.dart
lib/presentation/features/next_action/widgets/values_required_gateway.dart
lib/presentation/features/labels/widgets/enhanced_value_card.dart
lib/presentation/features/labels/widgets/value_detail_modal.dart
lib/presentation/features/projects/widgets/project_next_task_card.dart
```

### Files to DELETE
```
lib/domain/models/settings/allocation_settings.dart
```

### Modified Files (15+)
```
lib/domain/models/settings.dart
lib/domain/models/priority/allocation_result.dart
lib/domain/interfaces/settings_repository_contract.dart
lib/data/repositories/settings_repository.dart
lib/domain/services/allocation/allocation_orchestrator.dart
lib/domain/services/allocation/allocation_strategy.dart
lib/domain/services/allocation/proportional_allocator.dart
lib/domain/services/allocation/urgency_weighted_allocator.dart
lib/domain/services/analytics/analytics_service.dart
lib/data/features/analytics/services/analytics_service_impl.dart
lib/presentation/features/next_action/view/allocation_settings_page.dart
lib/presentation/features/next_action/view/next_actions_page.dart
lib/presentation/features/labels/view/value_overview_view.dart
lib/presentation/features/projects/view/project_list_view.dart
lib/presentation/features/projects/view/project_detail_view.dart
```

---

## Dependency Graph

```
Phase 1 ─────┬──────► Phase 2 ────┬──────► Phase 4
             │                    │
             │                    ├──────► Phase 5
             │                    │
             │                    └──────► Phase 6 ────► Phase 7
             │
             ├──────► Phase 3
             │
             └──────► Phase 8
```

**Parallelization**: Phases 3, 4, 5, 6, 8 can run in parallel after their dependencies complete.

---

## Follow-Up Questions for User Review

The following decisions were made with sensible defaults. Review after implementation and adjust if needed:

### UX/Design Questions
1. **Weight recalculation on reorder (Phase 7)**: Currently using rank-based decay (1st=35%, 2nd=25%, etc.). Alternative: equal distribution or preserve relative weights?

2. **Reflector "no history" messaging (Phase 6)**: Shows info banner "Building your history..." when <7 days of data. Is this sufficient or should there be a more prominent onboarding?

3. **Gap warning threshold (Phase 7)**: Set to ±15% difference between target and actual. Should this be configurable?

4. **Sparkline time range (Phase 7)**: Fixed at 4 weeks. Should users be able to change this?

### Technical Questions
5. **Pinned tasks vs dailyLimit (Phase 5)**: Currently pinned tasks count against dailyLimit. Should they be in addition to the limit?

6. **Reflector lookback caching**: `getRecentCompletionsByValue()` queries could be expensive. Cache results for session?

7. **Project urgency inheritance**: Should project urgency affect task urgency scores, or are they independent?

### Future Enhancements (Not in Scope)
- Onboarding wizard for first-time users
- Pre-built value templates ("Life Balance", "Career Focus")
- Re-prompt after skip timeout (e.g., ask again after 7 days)
- Trend notifications ("You've been neglecting Health for 2 weeks")
