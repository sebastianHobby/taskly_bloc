# Allocation System - Architecture Overview

> Audience: developers + architects
>
> Scope: allocation in the current architecture (inputs -> focus-mode config -> allocation computation -> My Day integration), with emphasis on **My Day**, **focus modes**, and **when/how allocation is invoked**.

## 1) Executive Summary

Taskly's **allocation system** produces a daily "Focus list" of tasks by combining:

- **User configuration** (`AllocationConfig`, especially the selected `FocusMode`)
- **Pinned tasks/projects** (always included)
- **Value priorities** (weights derived from user values)
- Optional strategy signals such as **urgency** and **neglect**

This output is exposed to the app primarily through the **My Day screen**:

- The screen’s BLoC subscribes to allocation suggestions and exposes widget-ready state.
- Allocation snapshot persistence and snapshot-based alerts have been removed.

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

### Screen integration (My Day)

My Day is an explicit screen (route + page) that renders allocation outputs.
Any gating (e.g. “focus mode required”) is implemented in the presentation
layer via the My Day ritual flow (inline gate card) and BLoC state.

### Presentation (My Day ritual + gate card + allocation rendering + focus setup)
- Ritual flow ("Choose what matters today") with inline gate card when
  prerequisites are missing:
  - [lib/presentation/screens/view/my_day_ritual_wizard_page.dart](../../lib/presentation/screens/view/my_day_ritual_wizard_page.dart)
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
|  - My Day screen + BLoC                                        |
|  - AllocationSectionRenderer                                   |
|  - FocusSetupWizard (config writes)                            |
+---------------------------------------------------------------+
                                |
                                v
+---------------------------------------------------------------+
|                          Domain Layer                          |
|  TemporalTriggerService                                        |
|   - emits HomeDayBoundaryCrossed events                         |
|   - re-checks on app resume (timers don't run while suspended)  |
|                                                               |
|  AllocationOrchestrator                                        |
|   - combines tasks/projects/settings                            |
|   - computes allocation result (strategies)                     |
|                                                               |
|  My Day ritual selection                                        |
|   - source of truth for “today” task set                         |
+---------------------------------------------------------------+
                                |
                                v
+---------------------------------------------------------------+
|                       Drift / PowerSync DB                     |
|  - user settings (SettingsKey.allocation)                       |
+---------------------------------------------------------------+
```

---

## 4) End-to-End Flows

### 4.1 My Day: Ritual gate card -> Focus setup -> Allocation sections

My Day is an **explicit screen** with a **presentation-owned ritual flow**.

Gate criteria:

- `AllocationConfig.hasSelectedFocusMode == true`
- at least one Value exists

Gating is implemented in the presentation layer using the ritual screen and
an inline gate card (not a domain-level screen interpreter).

**What the user experiences**:

```text
1) Navigate to My Day
2) My Day opens the daily ritual screen ("Choose what matters today")
3) If prerequisites are missing, the ritual shows a gate card:
   - CTA navigates to Focus Setup wizard (dynamic steps)
4) In Focus Setup wizard:
   - user selects focus mode (preset or personalized)
   - user adds at least one value if missing
   - FocusSetupBloc saves AllocationConfig with:
     - hasSelectedFocusMode = true
     - focusMode = selected
     - strategySettings = preset or user-tuned
5) After save, FocusSetupWizardPage requests an immediate snapshot refresh via
  allocation suggestions recompute immediately.
6) Return to My Day; ritual gate is now inactive; the screen renders allocation
  output and any allocation-related attention items.
```

Key save behavior:
- [lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart](../../lib/presentation/features/focus_setup/bloc/focus_setup_bloc.dart)

---
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

5) **Return suggestions**

- Return an `AllocationResult` that My Day can use to suggest focus items.

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

## 7) When / How Allocation Is Called (Trigger points)

### 8.1 My Day screen (primary)

Allocation is read whenever the My Day BLoC is active:

- If the ritual is not completed for the day, show allocation suggestions.
- If the ritual is completed, render the ritual-selected tasks as “today”.

### 8.4 What changes can trigger recomputation (when orchestrator is used)

When the orchestrator is used (snapshot missing / first-run), it recomputes when any of these streams emit:

- incomplete tasks stream
- projects stream (affects pinned-project behavior)
- allocation settings stream (daily limit, focus mode, strategy flags)

See stream combination:
- [lib/domain/allocation/engine/allocation_orchestrator.dart](../../lib/domain/allocation/engine/allocation_orchestrator.dart)

---

## 9) Notes / Invariants

- Day logic is keyed by **home-day (UTC-derived)** to keep “today” consistent.
- Allocation returns **suggestions**; ritual selection is the source of truth.
