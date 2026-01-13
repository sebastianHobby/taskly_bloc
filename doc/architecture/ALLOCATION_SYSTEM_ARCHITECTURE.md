# Allocation System - Architecture Overview

> Audience: developers + architects
>
> Scope: the *current* allocation system in this repo (inputs -> focus-mode config -> allocation computation -> daily snapshots -> unified screen integration), with emphasis on **My Day**, **focus modes**, and **when/how allocation is invoked**.

## 1) Executive Summary

Taskly's **allocation system** produces a daily "Focus list" of tasks by combining:

- **User configuration** (`AllocationConfig`, especially the selected `FocusMode`)
- **Pinned tasks/projects** (always included)
- **Value priorities** (weights derived from user values)
- Optional strategy signals such as **urgency** and **neglect**

This output is exposed to the app primarily through the **unified screen system**:

- `allocation` section template renders the Focus list.
- `allocation_alerts` section template renders **allocation warnings** (implemented via the attention system).
- The system prefers a persisted **daily allocation snapshot** so that My Day remains stable throughout the day.

A key UX invariant:

- **My Day is gated** until the user has selected a focus mode.

---

## 2) Where Things Live (Folder Map)

### Domain model (settings + outputs)
- Settings:
  - [lib/domain/allocation/model/allocation_config.dart](../../lib/domain/allocation/model/allocation_config.dart)
  - [lib/domain/allocation/model/focus_mode.dart](../../lib/domain/allocation/model/focus_mode.dart)
  - [lib/domain/preferences/model/settings_key.dart](../../lib/domain/preferences/model/settings_key.dart)
- Allocation output model:
  - [lib/domain/allocation/model/allocation_result.dart](../../lib/domain/allocation/model/allocation_result.dart)

### Domain services (allocation engine)
- Orchestrator:
  - [lib/domain/allocation/engine/allocation_orchestrator.dart](../../lib/domain/allocation/engine/allocation_orchestrator.dart)
- Snapshot refresh coordinator (unified triggers):
  - [lib/domain/allocation/engine/allocation_snapshot_coordinator.dart](../../lib/domain/allocation/engine/allocation_snapshot_coordinator.dart)
- Strategy implementations (selection is config-driven):
  - [lib/domain/allocation/engine/proportional_allocator.dart](../../lib/domain/allocation/engine/proportional_allocator.dart)
  - [lib/domain/allocation/engine/urgency_weighted_allocator.dart](../../lib/domain/allocation/engine/urgency_weighted_allocator.dart)
  - [lib/domain/allocation/engine/neglect_based_allocator.dart](../../lib/domain/allocation/engine/neglect_based_allocator.dart)
  - [lib/domain/allocation/engine/urgency_detector.dart](../../lib/domain/allocation/engine/urgency_detector.dart)

### Time + lifecycle (day boundary triggers)
- Home day-key computation:
  - [lib/domain/services/time/home_day_key_service.dart](../../lib/domain/services/time/home_day_key_service.dart)
- Lifecycle events (resume/pause):
  - [lib/domain/services/time/app_lifecycle_service.dart](../../lib/domain/services/time/app_lifecycle_service.dart)
- Central time-based triggers (timers, day rollover):
  - [lib/domain/services/time/temporal_trigger_service.dart](../../lib/domain/services/time/temporal_trigger_service.dart)

### Persistence (daily snapshots)
- Contract + domain models:
  - [lib/domain/allocation/contracts/allocation_snapshot_repository_contract.dart](../../lib/domain/allocation/contracts/allocation_snapshot_repository_contract.dart)
  - [lib/domain/allocation/model/allocation_snapshot.dart](../../lib/domain/allocation/model/allocation_snapshot.dart)
- Drift repository implementation:
  - [lib/data/allocation/repositories/allocation_snapshot_repository.dart](../../lib/data/allocation/repositories/allocation_snapshot_repository.dart)

### Unified screen integration (templates + gating)
- Section template IDs:
  - [lib/domain/screens/language/models/section_template_id.dart](../../lib/domain/screens/language/models/section_template_id.dart)
- Section params:
  - [lib/domain/screens/templates/params/allocation_section_params.dart](../../lib/domain/screens/templates/params/allocation_section_params.dart)
  - [lib/domain/screens/templates/params/allocation_alerts_section_params.dart](../../lib/domain/screens/templates/params/allocation_alerts_section_params.dart)
- Section interpreters:
  - [lib/domain/screens/templates/interpreters/allocation_section_interpreter.dart](../../lib/domain/screens/templates/interpreters/allocation_section_interpreter.dart)
  - [lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart](../../lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart)
- "Data plumbing" for templates:
  - [lib/domain/screens/runtime/section_data_service.dart](../../lib/domain/screens/runtime/section_data_service.dart)
  - [lib/domain/screens/runtime/section_data_result.dart](../../lib/domain/screens/runtime/section_data_result.dart)
- Screen gating:
  - [lib/domain/screens/language/models/screen_gate_config.dart](../../lib/domain/screens/language/models/screen_gate_config.dart)
  - [lib/domain/screens/runtime/screen_data_interpreter.dart](../../lib/domain/screens/runtime/screen_data_interpreter.dart)

### System screen definition (My Day)
- [lib/domain/screens/catalog/system_screens/system_screen_definitions.dart](../../lib/domain/screens/catalog/system_screens/system_screen_definitions.dart)

### Presentation (My Day gate + allocation rendering + focus setup)
- Gate page shown when focus mode is not selected:
  - [lib/presentation/screens/view/my_day_focus_mode_required_page.dart](../../lib/presentation/screens/view/my_day_focus_mode_required_page.dart)
- Allocation section renderer:
  - [lib/presentation/screens/templates/renderers/allocation_section_renderer.dart](../../lib/presentation/screens/templates/renderers/allocation_section_renderer.dart)
- Focus Setup wizard (select focus mode + save allocation config):
  - [lib/presentation/features/focus_setup/view/focus_setup_wizard_page.dart](../../lib/presentation/features/focus_setup/view/focus_setup_wizard_page.dart)
  - [lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart](../../lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart)

---

## 3) High-Level Architecture

### 3.1 Component Diagram

```text
+---------------------------------------------------------------+
|                        Presentation                            |
|  - My Day (unified screen)                                     |
|  - AllocationSectionRenderer                                   |
|  - FocusSetupWizard (config writes)                            |
+---------------------------------------------------------------+
                                |
                                v
+---------------------------------------------------------------+
|                    Unified Screen Pipeline                     |
|  ScreenDataInterpreter                                         |
|   - applies ScreenGateConfig (e.g., focus mode required)        |
|   - runs section template interpreters                          |
|     - allocation -> SectionDataService.watchAllocation()        |
|     - allocation_alerts -> AttentionEngine                      |
+---------------------------------------------------------------+
                                |
                                v
+---------------------------------------------------------------+
|                          Domain Layer                          |
|  TemporalTriggerService                                        |
|   - emits HomeDayBoundaryCrossed events                         |
|   - re-checks on app resume (timers don't run while suspended)  |
|                                                               |
|  AllocationSnapshotCoordinator                                  |
|   - owns WHEN to refresh today's snapshot                       |
|   - debounces input changes                                     |
|   - refreshes immediately on day boundary                       |
|  AllocationOrchestrator                                        |
|   - combines tasks/projects/settings                            |
|   - computes allocation result (strategies)                     |
|   - persists allocation snapshots (optional injection)          |
|                                                               |
|  AllocationSnapshotRepository                                  |
|   - stores daily allocation membership                          |
+---------------------------------------------------------------+
                                |
                                v
+---------------------------------------------------------------+
|                       Drift / PowerSync DB                     |
|  - allocation_snapshots + allocation_snapshot_entries           |
|  - user settings (SettingsKey.allocation)                       |
+---------------------------------------------------------------+
```

---

## 4) End-to-End Flows

### 4.1 My Day: Focus-mode gate -> Focus setup -> Allocation sections

My Day is a **system screen** with a **screen-level gate**.

- Definition: `SystemScreenDefinitions.myDay`
  - [lib/domain/screens/catalog/system_screens/system_screen_definitions.dart](../../lib/domain/screens/catalog/system_screens/system_screen_definitions.dart)
- Gate criteria: `allocationFocusModeNotSelected`
  - [lib/domain/screens/language/models/screen_gate_config.dart](../../lib/domain/screens/language/models/screen_gate_config.dart)

**Reactive gating logic** (domain-side):

- `ScreenDataInterpreter.watchScreen()` checks gate criteria.
- For `allocationFocusModeNotSelected`, it watches settings:
  - `SettingsKey.allocation` and `AllocationConfig.hasSelectedFocusMode`.
- While active, the screen's normal sections are replaced by the gate section:
  - `SectionTemplateId.myDayFocusModeRequired`.

See gate evaluation:
- [lib/domain/screens/runtime/screen_data_interpreter.dart](../../lib/domain/screens/runtime/screen_data_interpreter.dart)

**What the user experiences**:

```text
1) Navigate to My Day
2) If AllocationConfig.hasSelectedFocusMode == false:
   - Show MyDayFocusModeRequiredPage (full-screen)
   - CTA navigates to Focus Setup wizard
3) In Focus Setup wizard:
   - user selects focus mode (preset or personalized)
   - FocusSetupBloc saves AllocationConfig with:
     - hasSelectedFocusMode = true
     - focusMode = selected
     - strategySettings = preset or user-tuned
4) After save, FocusSetupWizardPage requests an immediate snapshot refresh via
  `AllocationSnapshotCoordinator` so snapshot-based screens refresh immediately.
5) Return to My Day; gate is now inactive; normal sections render:
   - check_in_summary
   - allocation_alerts
   - allocation
```

Key save behavior:
- [lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart](../../lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart)

Key post-save "refresh" call (requests an immediate snapshot refresh):
- [lib/presentation/features/focus_setup/view/focus_setup_wizard_page.dart](../../lib/presentation/features/focus_setup/view/focus_setup_wizard_page.dart)

---

### 4.2 Allocation section: Snapshot-first, with live fallback

The `allocation` template is interpreted by `AllocationSectionInterpreter`, which delegates to `SectionDataService`.

- Interpreter:
  - [lib/domain/screens/templates/interpreters/allocation_section_interpreter.dart](../../lib/domain/screens/templates/interpreters/allocation_section_interpreter.dart)
- Data service:
  - [lib/domain/screens/runtime/section_data_service.dart](../../lib/domain/screens/runtime/section_data_service.dart)

**Runtime sequence (watch path):**

```text
1) Unified screen pipeline executes AllocationSectionInterpreter.watch(params)
2) SectionDataService._watchAllocationSection():
   - determine current UTC day
   - subscribe to AllocationSnapshotRepository.watchLatestForUtcDay(day)
3) If snapshot exists:
   - fetch Task entities referenced by snapshot entries
   - build groups (pinned + tasksByValue)
   - emit SectionDataResult.allocation(...)
4) If snapshot does not exist yet:
   - fall back to AllocationOrchestrator.watchAllocation()
   - build groups from the computed allocation result
   - emit SectionDataResult.allocation(...)
```

**Snapshot-first behavior exists for stability**:

- The user's Focus list should not churn due to incidental mid-day changes.
- The allocator can still recompute, but the snapshot layer can "lock" membership.

**Keeping snapshots fresh (top-up-only)**:

- Once running, `AllocationSnapshotCoordinator` keeps today's snapshot generated
  and refreshed in the background.
- It triggers refreshes based on:
  - debounced allocation input changes (tasks/projects/settings)
  - home-day boundary rollover (`TemporalTriggerService`)
  - explicit requests (e.g., focus setup save)
- Snapshot stabilization rules ensure **no reshuffle**:
  - If the day was generated without a shortage, allocation membership freezes
    (it may shrink as tasks become ineligible/completed, but it will not refill).
  - If the day was generated with a shortage, remaining slots may be **topped up**.

---

### 4.3 Allocation snapshots: generation, versioning, and stability rules

Allocation snapshots are **daily**, keyed by **UTC day**, and are **allocated-membership only**.

- Domain contract:
  - [lib/domain/allocation/contracts/allocation_snapshot_repository_contract.dart](../../lib/domain/allocation/contracts/allocation_snapshot_repository_contract.dart)

**Who writes snapshots?**

- `AllocationOrchestrator.watchAllocation()` persists a snapshot (if the snapshot repository is provided via DI).

**When does a new version get written?**

- Only when the **membership changes** or relevant generation metadata changes.
- The Drift implementation checks set equality before inserting a new version.

Repository implementation:
- [lib/data/allocation/repositories/allocation_snapshot_repository.dart](../../lib/data/allocation/repositories/allocation_snapshot_repository.dart)

**Mid-day stability rules (membership locking):**

The orchestrator includes a stabilization step:

- When a snapshot already exists for today, regular (non-pinned) membership is treated as "locked".
- A "top-up" is only allowed if the day was generated with an initial shortage (candidate pool < cap).

Implementation details:
- [lib/domain/allocation/engine/allocation_orchestrator.dart](../../lib/domain/allocation/engine/allocation_orchestrator.dart)

---

## 5) Allocation Algorithm (What it does)

This section describes the current algorithm at the *architecture* level (not a mathematical specification).

### 5.1 Inputs

- Incomplete tasks: `TaskRepositoryContract.watchAll(TaskQuery.incomplete())`
- Projects (used for pinned-project behavior)
- User values (used to build value-category weights)
- Allocation settings:
  - `AllocationConfig.dailyLimit`
  - `AllocationConfig.focusMode`
  - `AllocationConfig.strategySettings` (urgency, neglect, weights)

### 5.2 Key steps

1) **Soft-gate on values**
   - If there are no values, allocation returns `requiresValueSetup = true`.

2) **Pinned membership**
  - A task is "pinned" if:
     - `task.isPinned == true`, or
     - its project is pinned.
   - Pinned tasks are always included.

3) **Strategy selection**

Strategy is chosen from config (feature flags), currently:

- Neglect-based when `enableNeglectWeighting == true`
- Otherwise urgency-weighted when `urgencyBoostMultiplier > 1.0`
- Otherwise proportional allocation

See:
- [lib/domain/allocation/engine/allocation_orchestrator.dart](../../lib/domain/allocation/engine/allocation_orchestrator.dart)

4) **Regular allocation**

Regular tasks are allocated using `AllocationParameters` built from settings, including:

- urgent-task handling policy (`UrgentTaskBehavior`)
- urgency thresholds and multipliers
- neglect window and influence
- value/task priority weights

5) **Persist + stabilize**

- Persist allocation membership as a snapshot for today (if configured).
- Stabilize regular membership against the latest snapshot.

---

## 6) Focus Modes (How they affect allocation)

Focus mode is stored in `AllocationConfig`:

- `hasSelectedFocusMode`: drives My Day gating
- `focusMode`: which preset is active

Definition:
- [lib/domain/allocation/model/focus_mode.dart](../../lib/domain/allocation/model/focus_mode.dart)

### 6.1 Presets vs personalized

In the Focus Setup wizard:

- Non-personalized modes (`intentional`, `sustainable`, `responsive`) use presets:
  - `StrategySettings.forFocusMode(mode)`
- `personalized` keeps existing persisted strategy settings and lets the user adjust.

Save behavior:
- [lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart](../../lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart)

### 6.2 Propagation to UI

- `AllocationOrchestrator` includes the active focus mode in `AllocationResult.activeFocusMode`.
- `SectionDataService` passes that through to `SectionDataResult.allocation.activeFocusMode`.
- The renderer can use it for labels/section titles (e.g., "Outside Focus" copy).

---

## 7) Integration with Allocation Alerts (Attention system)

My Day includes an `allocation_alerts` section. This is *not* computed by the allocator directly.

Instead:

- `AllocationAlertsSectionInterpreter.fetch()` calls:
  - `AttentionEngine.watch(AttentionQuery(domains: {'allocation'}))`
- Allocation alert rules are evaluated **against the current day's snapshot**:
  - "Show candidates that match predicate X but are not allocated today."

Key implementation:
- [lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart](../../lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart)
- [lib/domain/attention/engine/attention_engine.dart](../../lib/domain/attention/engine/attention_engine.dart)

Important design note (current state):

- The allocation section result carries `excludedTasks` mainly for the optional "outside focus" section.
- The "warning banners / alerts" UX is driven by the attention system so it can:
  - apply rule configuration,
  - support dismissals via state-hashes,
  - remain consistent with other attention surfaces.

---

## 8) When / How Allocation Is Called (Trigger points)

### 8.1 Unified screens (primary)

Allocation runs when a screen contains the `allocation` template.

- `AllocationSectionInterpreter.watch()`
  - calls `SectionDataService.watchAllocation()`
  - prefers snapshot stream; falls back to orchestrator only when necessary.

### 8.2 Focus setup save (explicit refresh)

After saving focus-mode settings, the wizard triggers:

- `AllocationSnapshotCoordinator.requestRefreshNow(AllocationSnapshotRefreshReason.focusSetupSaved)`

This forces generation/persistence of a fresh snapshot so My Day updates immediately.

See:
- [lib/presentation/features/focus_setup/view/focus_setup_wizard_page.dart](../../lib/presentation/features/focus_setup/view/focus_setup_wizard_page.dart)

### 8.3 Centralized snapshot refresh triggers (coordinator)

The coordinator is started at bootstrap and unifies "when" decisions.

It will attempt a refresh when:

- Allocation inputs change (debounced): tasks/projects/settings streams emit.
- Home day boundary crosses (immediate): `TemporalTriggerService` emits `HomeDayBoundaryCrossed`.

Refreshes are gated to avoid unnecessary churn:

- Requires `AllocationConfig.hasSelectedFocusMode == true`
- Requires `AllocationConfig.dailyLimit > 0`
- Requires at least one incomplete task

See:
- [lib/domain/allocation/engine/allocation_snapshot_coordinator.dart](../../lib/domain/allocation/engine/allocation_snapshot_coordinator.dart)

### 8.4 What changes can trigger recomputation (when orchestrator is used)

When the orchestrator is used (snapshot missing / first-run), it recomputes when any of these streams emit:

- incomplete tasks stream
- projects stream (affects pinned-project behavior)
- allocation settings stream (daily limit, focus mode, strategy flags)

See stream combination:
- [lib/domain/allocation/engine/allocation_orchestrator.dart](../../lib/domain/allocation/engine/allocation_orchestrator.dart)

---

## 9) Notes / Invariants

- Snapshots are keyed by **UTC day**.
- Snapshots store **allocated membership** (not "excluded").
- App code intentionally does not filter snapshot rows by `user_id`; scoping is handled by Supabase RLS + PowerSync bucket rules.
- "First run" (no snapshot yet) uses live allocation fallback.
