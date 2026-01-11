# Attention System — Architecture Overview

> Audience: developers + architects
>
> Scope: the *current* attention system in this repo (rules → evaluation → persistence → section rendering), including where it plugs into the unified screen pipeline.

## 1) Executive Summary

Taskly’s **attention system** is a rule-based mechanism that detects items that
need user attention (e.g., overdue tasks, idle projects, periodic reviews) and
surfaces them as **`AttentionItem`** view-models in multiple places:

- **Support sections** on unified screens:
  - Issues summary (`issuesSummary`)
  - Allocation alerts (`allocationAlerts`)
  - Check-in summary (`checkInSummary`)
- **Settings** page for enabling/disabling rules (`Attention Rules`)

The core idea:

- **`AttentionRule`** is the persisted configuration (what to detect + how to
  display it).
- **`AttentionEvaluator`** reads active rules and evaluates them against current
  domain data to produce **`AttentionItem`**s.
- User actions are stored as **`AttentionResolution`** rows, enabling
  “dismiss until state changes” via a **state-hash**.

---

## 2) Where Things Live (Folder Map)

### Domain model (attention language)
- Rules, items, resolutions, templates
  - [lib/domain/models/attention/](../lib/domain/models/attention/)

Key files:
- [lib/domain/models/attention/attention_rule.dart](../lib/domain/models/attention/attention_rule.dart)
- [lib/domain/models/attention/attention_item.dart](../lib/domain/models/attention/attention_item.dart)
- [lib/domain/models/attention/attention_resolution.dart](../lib/domain/models/attention/attention_resolution.dart)
- [lib/domain/models/attention/system_attention_rules.dart](../lib/domain/models/attention/system_attention_rules.dart)

### Domain services (evaluation)
- [lib/domain/services/attention/attention_evaluator.dart](../lib/domain/services/attention/attention_evaluator.dart)
- [lib/domain/services/attention/attention_context.dart](../lib/domain/services/attention/attention_context.dart)

### Data layer (persistence + seeding)
- Repository impl:
  - [lib/data/repositories/attention_repository.dart](../lib/data/repositories/attention_repository.dart)
- Drift tables (generated):
  - [lib/data/drift/features/attention_tables.drift.dart](../lib/data/drift/features/attention_tables.drift.dart)
- Mappers:
  - [lib/data/mappers/attention_converter.dart](../lib/data/mappers/attention_converter.dart)
- Seeder:
  - [lib/data/services/attention_seeder.dart](../lib/data/services/attention_seeder.dart)

### Screen integration (templates)
- Issues summary:
  - [lib/domain/services/screens/templates/issues_summary_section_interpreter.dart](../lib/domain/services/screens/templates/issues_summary_section_interpreter.dart)
- Allocation alerts:
  - [lib/domain/services/screens/templates/allocation_alerts_section_interpreter.dart](../lib/domain/services/screens/templates/allocation_alerts_section_interpreter.dart)
- Check-in summary:
  - [lib/domain/services/screens/templates/check_in_summary_section_interpreter.dart](../lib/domain/services/screens/templates/check_in_summary_section_interpreter.dart)

### Presentation (widgets + settings)
- Settings page:
  - [lib/presentation/features/attention/view/attention_rules_settings_page.dart](../lib/presentation/features/attention/view/attention_rules_settings_page.dart)
- Shared widgets used by the support sections:
  - [lib/presentation/features/screens/renderers/attention_support_section_widgets.dart](../lib/presentation/features/screens/renderers/attention_support_section_widgets.dart)

---

## 3) High-Level Architecture

### 3.1 Component Diagram

```text
┌───────────────────────────────────────────────────────────┐
│                       Presentation                          │
│  - AttentionRulesSettingsPage (toggle rules)                │
│  - Support section renderers + AttentionItemTile            │
└───────────────┬───────────────────────────────┬────────────┘
                │                               │
                │                               │
                v                               v
┌───────────────────────────────┐   ┌───────────────────────────────┐
│  Screen Template Interpreters  │   │     Other domain pipelines     │
│  - IssuesSummarySection...     │   │  (e.g. AllocationOrchestrator) │
│  - CheckInSummarySection...    │   └───────────────────────────────┘
│  - AllocationAlertsSection...  │
└───────────────┬───────────────┘
                │
                v
┌───────────────────────────────────────────────────────────┐
│                       Domain Service                        │
│                    AttentionEvaluator                        │
│  - loads active rules by type                                │
│  - evaluates against tasks/projects                          │
│  - checks dismissals via state hash                           │
└───────────────┬───────────────────────────────┬────────────┘
                │                               │
                v                               v
┌───────────────────────────────┐   ┌───────────────────────────────┐
│      AttentionRepository        │   │  Task/Project repositories     │
│  - rules + resolutions          │   │  (data to evaluate rules on)   │
└───────────────┬───────────────┘   └───────────────┬───────────────┘
                │                                   │
                v                                   v
┌───────────────────────────────────────────────────────────┐
│                     Drift / PowerSync DB                    │
│  attention_rules, attention_resolutions                      │
└───────────────────────────────────────────────────────────┘
```

### 3.2 End-to-End Flow (Issues Summary)

This is the most “canonical” attention flow because it uses persisted rules and
dismissal tracking.

```text
1) Section interpreter runs: IssuesSummarySectionInterpreter.fetch(params)
2) It calls AttentionEvaluator.evaluateIssues(entityTypes, minSeverity)
3) Evaluator loads rules:
   - attentionRepository.watchRulesByType(AttentionRuleType.problem).first
   - filters to active rules
4) For each rule:
   - selects entity type + predicate from rule.entitySelector
   - queries domain data (tasks/projects)
   - computes a stateHash for each candidate entity
   - attentionRepository.wasDismissed(ruleId, entityId, stateHash)
     - if dismissed and hash unchanged -> keep hidden
     - if hash changed -> resurface
5) Evaluator returns List<AttentionItem>
6) Interpreter packages items into SectionDataResult.issuesSummary(...)
7) Renderer displays tiles (AttentionItemTile) and counts
```

### 3.3 Persistence Model (Rules + Resolutions)

The DB schema is intentionally small and generic.

```text
attention_rules
  - id (uuid)
  - rule_key
  - rule_type (problem/review/workflowStep/allocationWarning)
  - trigger_type (realtime/scheduled)
  - trigger_config (json)
  - entity_selector (json)
  - severity (info/warning/critical)
  - display_config (json)
  - resolution_actions (json)
  - active (bool)
  - source (systemTemplate/userCreated/imported)

attention_resolutions
  - id (uuid)
  - rule_id (FK to attention_rules.id)
  - entity_id
  - entity_type
  - resolved_at
  - resolution_action (reviewed/skipped/snoozed/dismissed)
  - action_details (json)   // e.g. snooze_until, state_hash
```

---

## 4) Core Concepts (Responsibilities)

### 4.1 `AttentionRule` (persisted configuration)

`AttentionRule` describes **what** to detect and **how** to present it.

- `ruleType` is the high-level category (problem/review/allocationWarning/…)
- `entitySelector` identifies the target domain entities and predicate (e.g.
  `{"entity_type": "task", "predicate": "isOverdue"}`)
- `triggerType`/`triggerConfig` describes cadence/thresholds

Important nuance in the current implementation:

- `triggerType` is currently **metadata**. Evaluation occurs **on-demand** when
  a section interpreter calls the evaluator. Background scheduling is not part of
  the current runtime.

### 4.2 `AttentionItem` (evaluated output)

`AttentionItem` is the **result of evaluation**, designed for rendering.

- The UI consumes this (title, description, severity, available actions)
- It can carry additional `metadata` for navigation/action decisions

### 4.3 `AttentionResolution` (user response)

A resolution records user intent:

- `dismissed`: hide until the entity’s “state hash” changes
- `snoozed`: hide until a future time (stored in `actionDetails`)
- `reviewed`/`skipped`: marks a review session as handled

In the current code, the evaluation layer uses:

- `AttentionRepositoryContract.wasDismissed(ruleId, entityId, stateHash)`

to decide if an item should remain hidden.

### 4.4 `AttentionEvaluator` (rule evaluation engine)

Primary responsibilities:

- Load the **active** rules per category (problem/review/allocationWarning)
- Evaluate rule predicates against the **current** domain data
- Exclude dismissed entities if the state hash is unchanged
- Apply “product policy” rules, for example:
  - Reviews: only show **one** due review at a time (the most overdue)

### 4.5 `AttentionRepositoryContract` + Drift implementation

Responsibilities:

- Expose reactive views of rules (`watchAllRules`, `watchRulesByType`, …)
- Persist user changes:
  - toggle active status
  - update configs
  - record resolutions
- Provide helper queries needed by the evaluator:
  - `wasDismissed` (state-hash based)
  - `wasRecentlyResolved` (cooldown windows)

The Drift implementation is:

- [lib/data/repositories/attention_repository.dart](../lib/data/repositories/attention_repository.dart)

### 4.6 System Defaults (Templates + Seeding)

The system defaults live in code as templates:

- [lib/domain/models/attention/system_attention_rules.dart](../lib/domain/models/attention/system_attention_rules.dart)

and can be seeded into the database using:

- [lib/data/services/attention_seeder.dart](../lib/data/services/attention_seeder.dart)

Important nuance in the current repo state:

- There is a seeder (`AttentionSeeder.ensureSeeded()`), but
  `runPostAuthMaintenance` currently seeds screens + runs attention cleanup.
  It does **not** currently invoke the attention seeder.

If you want deterministic local “first-run” attention defaults, you can wire
`AttentionSeeder.ensureSeeded()` into the same post-auth maintenance flow.

---

## 5) Integration Points (How Attention Surfaces in UI)

---

## 5.4 Temporal Triggers Integration (In-App Only)

Current product scope: **time-based rules are only required to update when the app is running** (e.g. user opens the app and a wellbeing review is now due).

To support this without introducing OS notifications or server scheduling, the runtime uses a lightweight invalidation stream:

- **Single time source**: `TemporalTriggerService`
  - emits `AppResumed` and `HomeDayBoundaryCrossed`
- **Attention invalidation**: `AttentionTemporalInvalidationService`
  - converts temporal events into `Stream<void>` invalidation pulses
- **Section refresh**: time-based attention sections (e.g. `checkInSummary`) subscribe to invalidations and re-run `fetch()` when a pulse arrives

This keeps attention evaluation **pull-based** (section interpreters still call `AttentionEvaluator`), but ensures the UI re-checks on:

- app resume (covers “user opens app”)
- home-day boundary (covers “new day”)

Important: `AttentionRule.triggerType`/`triggerConfig` remain **metadata** in this phase; the app does not run a background scheduler.

Future releases that require actual time-based reminders (firing while the app is closed) should add a separate **delivery layer** (local notifications and/or server push), without coupling it tightly to evaluator logic.

### 5.1 Support sections (unified screens)

- `issuesSummary` → calls evaluator `evaluateIssues(...)`
  - [lib/domain/services/screens/templates/issues_summary_section_interpreter.dart](../lib/domain/services/screens/templates/issues_summary_section_interpreter.dart)

- `checkInSummary` → calls evaluator `evaluateReviews()`
  - [lib/domain/services/screens/templates/check_in_summary_section_interpreter.dart](../lib/domain/services/screens/templates/check_in_summary_section_interpreter.dart)

- `allocationAlerts` → currently derives attention-like items from allocation
  results (not from persisted rules)
  - [lib/domain/services/screens/templates/allocation_alerts_section_interpreter.dart](../lib/domain/services/screens/templates/allocation_alerts_section_interpreter.dart)

### 5.2 Settings: toggling attention rules

- The settings UI reads all rules once and lets users toggle `active`.
  - [lib/presentation/features/attention/view/attention_rules_settings_page.dart](../lib/presentation/features/attention/view/attention_rules_settings_page.dart)

### 5.3 Attention widgets

- Rendering is currently “display-only” tiles:
  - `AttentionItemTile` + `SeverityIcon`
  - [lib/presentation/features/screens/renderers/attention_support_section_widgets.dart](../lib/presentation/features/screens/renderers/attention_support_section_widgets.dart)

---

## 6) Example Implementation: Add a New “Blocked Tasks” Problem Rule

This example shows how to add a new rule that flags tasks as “blocked”, and how
it gets surfaced automatically in the Issues Summary section.

### 6.1 Add a new system rule template

In
[lib/domain/models/attention/system_attention_rules.dart](../lib/domain/models/attention/system_attention_rules.dart)
add a template:

```dart
static const problemTaskBlocked = AttentionRuleTemplate(
  ruleKey: 'problem_task_blocked',
  ruleType: AttentionRuleType.problem,
  triggerType: AttentionTriggerType.realtime,
  triggerConfig: {
    // You can add thresholds here if needed
  },
  entitySelector: {
    'entity_type': 'task',
    'predicate': 'isBlocked',
  },
  severity: AttentionSeverity.warning,
  displayConfig: {
    'title': 'Blocked Tasks',
    'description': 'Tasks that are blocked and need an unblock plan',
    'icon': 'block',
  },
  resolutionActions: ['reviewed', 'snoozed', 'dismissed'],
  sortOrder: 25,
);
```

and include it in `SystemAttentionRules.all`.

### 6.2 Implement the predicate in `AttentionEvaluator`

In
[lib/domain/services/attention/attention_evaluator.dart](../lib/domain/services/attention/attention_evaluator.dart)
extend the task predicate switch:

```dart
final matches = switch (predicate) {
  'isOverdue' => _isTaskOverdue(task, rule.triggerConfig),
  'isStale' => _isTaskStale(task, rule.triggerConfig),
  'isBlocked' => _isTaskBlocked(task, rule.triggerConfig),
  _ => false,
};
```

Then add `_isTaskBlocked(...)` using whatever “blocked” signal exists in your
`Task` model (examples: a `blocked` boolean, a status enum, or a non-empty
`blockedReason`).

To support “dismiss until state changes”, ensure your task state hash includes
the fields that should cause resurfacing (e.g., `blockedReason`, `updatedAt`).

### 6.3 Ensure the rule exists in the database

If you want templates to seed on first run, wire the seeder into the post-auth
maintenance. A minimal approach is adding something like:

```dart
final attentionSeeder = AttentionSeeder(db: driftDb, idGenerator: idGenerator);
await attentionSeeder.ensureSeeded();
```

into the post-auth maintenance flow.

### 6.4 Result: Issues Summary picks it up automatically

Because `IssuesSummarySectionInterpreter` reads active rules by type and then
delegates to `AttentionEvaluator`, the new rule will be included as soon as:

- it is present in `attention_rules`
- it is `active=true`
- at least one task matches the predicate and is not dismissed

---

## 7) Known Gaps (Current State)

These are observed from the current code structure:

- **`AttentionContext` is not yet used** by the screen pipeline (it exists as a
  helper for cross-section coordination, but is not wired in).
- **Resolution recording is not yet surfaced in the UI** for attention tiles
  (the repo supports `recordResolution`, but current tiles do not expose actions).
- **Allocation alerts currently bypass persisted rules** and build
  `AttentionItem`s directly from allocation results.

---

## 8) Allocation: Current Implementation vs. Proposed Snapshot Model

This section documents how allocation works *today* in the repo and what it
implies for the proposed “daily current-state snapshot” model.

### 8.1 Current Allocation Pipeline (Today)

**Where it lives**

- Allocation engine orchestration:
  - [lib/domain/services/allocation/allocation_orchestrator.dart](../lib/domain/services/allocation/allocation_orchestrator.dart)
- Allocation strategies (compute allocated + excluded):
  - [lib/domain/services/allocation/proportional_allocator.dart](../lib/domain/services/allocation/proportional_allocator.dart)
  - [lib/domain/services/allocation/urgency_weighted_allocator.dart](../lib/domain/services/allocation/urgency_weighted_allocator.dart)
  - [lib/domain/services/allocation/neglect_based_allocator.dart](../lib/domain/services/allocation/neglect_based_allocator.dart)
- Unified screen data for the allocation section:
  - [lib/domain/services/screens/section_data_service.dart](../lib/domain/services/screens/section_data_service.dart)
- Allocation alerts support section (unified screen template):
  - [lib/domain/services/screens/templates/allocation_alerts_section_interpreter.dart](../lib/domain/services/screens/templates/allocation_alerts_section_interpreter.dart)

**Key behavior**

- `AllocationOrchestrator.watchAllocation()` recomputes reactively when:
  - incomplete tasks change (`TaskQuery.incomplete()`)
  - projects change (pinning)
  - allocation settings change (`SettingsKey.allocation`)
- The orchestrator selects a strategy (proportional / urgency-weighted /
  neglect-based) and returns an `AllocationResult` containing:
  - `allocatedTasks`: selected tasks (plus pinned tasks added on top)
  - `excludedTasks`: *everything the strategy did not allocate* (details below)
- There is **no persisted allocation snapshot** today (everything is computed
  in-memory from current DB state).

**Important: what “excluded” means today**

The current allocators treat “excluded” as “not allocated”, not “explicitly
disqualified”. Examples:

- `ProportionalAllocator`:
  - marks tasks beyond a category’s allocated slots as
    `ExclusionType.categoryLimitReached`
  - marks tasks with no matching value category as `ExclusionType.noCategory`
- `UrgencyWeightedAllocator` / `NeglectBasedAllocator`:
  - score all eligible tasks, allocate top `maxTasks`, and mark the rest as
    `ExclusionType.lowPriority`

This means `excludedTasks` can be extremely large when the daily limit is small
relative to the number of candidate tasks.

**Allocation alerts in the unified screen model**

- The `allocation_alerts` support section currently filters
  `AllocationResult.excludedTasks` to tasks with `isUrgent == true` and maps
  them to ad-hoc `AttentionItem`s with a hard-coded rule id/key
  (`allocation_warning_excluded`).
- These “attention” items do **not** come from `attention_rules` and do **not**
  participate in the attention resolution persistence model.

**Legacy alert configuration is currently inert**

- There is a pure `AllocationAlertEvaluator`, but it is invoked with
  `const AllocationAlertConfig()` (which defaults to `rules: []`), so it produces
  no alerts. Comments indicate alert settings were migrated to the attention
  system.

**“Load more”**

- There is a `loadMore(...)` concept in the agenda pipeline, but allocation does
  not currently have a horizon/pagination concept. Allocation always uses the
  full stream of incomplete tasks.

### 8.2 Proposed Daily Snapshot Model (Recap)

The proposed plan discussed in chat is:

- Persist one “day snapshot” per scope/date (overwritable/updated during the
  day).
- Persist the final selected set (`allocated` items).
- Persist a bounded set of “excluded” items, where “excluded” is intended to
  mean **candidate exclusions** (explicitly filtered out by a constraint/rule),
  not “everything that wasn’t selected because of the daily limit”.

### 8.3 Mismatch to Resolve (What Needs to Change)

Because the current allocator’s `excludedTasks` effectively equals
`candidates - allocated`, the proposed “candidate exclusions” table cannot be
fed directly from today’s `excludedTasks` without risking massive row counts.

To align current behavior with the proposed persistence model, you will need at
least one of:

- **A semantic split in the allocation output**:
  - “not selected due to ranking/limit” (outside focus) vs
  - “excluded by rule/constraint” (true candidate exclusions)
- **Or a persistence rule** that stores only a bounded subset of excluded tasks,
  such as:
  - only urgent excluded tasks
  - only tasks excluded for specific reason codes (e.g., `noCategory`)
  - only tasks that match DB-configured attention rules (warning-producing)

### 8.4 Implications for Attention Integration

To make allocation warnings data-driven via the attention system:

- The current ad-hoc mapping in the allocation alerts interpreter should be
  replaced by either:
  - evaluating allocation-warning rules against the persisted allocation snapshot
    (recommended if you adopt the snapshot model), or
  - implementing `_evaluateAllocationRule(...)` in
    [lib/domain/services/attention/attention_evaluator.dart](../lib/domain/services/attention/attention_evaluator.dart)
    and having the interpreter delegate to `AttentionEvaluator`.

If you want dismissals/snoozes to work for allocation warnings, you’ll need a
stable `rule_id` + `entity_id` + `state_hash` for the warning items you produce
(today’s ad-hoc `AttentionItem`s are not wired into resolution persistence).
