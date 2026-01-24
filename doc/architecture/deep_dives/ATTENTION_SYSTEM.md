# Attention System — Architecture Overview

> Audience: developers + architects
>
> Scope: the attention system in the **future-state** architecture (rules → evaluation → persistence → rendering in screens/settings).

## 1) Executive Summary

Taskly’s **attention system** is a rule-based mechanism that detects items that
need user attention (e.g., stale tasks, idle projects, deadline risk) and
surfaces them as **`AttentionItem`** view-models inside the **Weekly Review**
maintenance flow.

The core idea:

- **`AttentionRule`** is the persisted configuration (what to detect + how to
  display it).
- **`AttentionEngine`** is the reactive evaluation engine. BLoCs construct an
  **`AttentionQuery`** and subscribe to `AttentionEngine.watch(query)`.
- User actions are stored as **`AttentionResolution`** rows. “Dismiss until
  state changes” is implemented using engine-owned runtime state
  (state-hash + dismissal/snooze semantics).

Prewarm policy: any **attention prewarm** (e.g. seeding caches or priming common
`AttentionQuery` results) is triggered from **core bootstrap/post-auth
maintenance**, not from widgets/pages, to keep side effects out of widgets.

See: [../INVARIANTS.md](../INVARIANTS.md#2-presentation-boundary-bloc-only)

---

## 2) Where Things Live (Folder Map)

### Attention bounded context (single entrypoint)
- Bounded-context entrypoint (barrel exports):
  - [lib/domain/attention/attention.dart](../../lib/domain/attention/attention.dart)

Key subfolders:
- Contracts: [lib/domain/attention/contracts/](../../lib/domain/attention/contracts/)
- Engine: [lib/domain/attention/engine/](../../lib/domain/attention/engine/)
- Models: [lib/domain/attention/model/](../../lib/domain/attention/model/)
- Query: [lib/domain/attention/query/](../../lib/domain/attention/query/)

Key files:
- [lib/domain/attention/model/attention_rule.dart](../../lib/domain/attention/model/attention_rule.dart)
- [lib/domain/attention/model/attention_item.dart](../../lib/domain/attention/model/attention_item.dart)
- [lib/domain/attention/model/attention_resolution.dart](../../lib/domain/attention/model/attention_resolution.dart)
- [lib/domain/attention/model/attention_rule_runtime_state.dart](../../lib/domain/attention/model/attention_rule_runtime_state.dart)
- [lib/domain/attention/system_attention_rules.dart](../../lib/domain/attention/system_attention_rules.dart)
- [lib/domain/attention/engine/attention_engine.dart](../../lib/domain/attention/engine/attention_engine.dart)

### Domain services (time-based invalidations)
- [lib/domain/services/attention/attention_temporal_invalidation_service.dart](../../lib/domain/services/attention/attention_temporal_invalidation_service.dart)

### Data layer (persistence + seeding)
- Repository impl:
  - [lib/data/attention/repositories/attention_repository_v2.dart](../../lib/data/attention/repositories/attention_repository_v2.dart)
- Drift tables (generated):
  - [lib/data/infrastructure/drift/features/attention_tables.drift.dart](../../lib/data/infrastructure/drift/features/attention_tables.drift.dart)
- Seeder:
  - [lib/data/attention/maintenance/attention_seeder.dart](../../lib/data/attention/maintenance/attention_seeder.dart)

### Screen integration

Attention is consumed by presentation-layer BLoCs, which subscribe to
`AttentionEngine.watch(query)` and expose widget-ready state.

### Presentation (review flow)
- Weekly review modal + BLoC:
  - [lib/presentation/features/review/view/weekly_review_modal.dart](../../lib/presentation/features/review/view/weekly_review_modal.dart)
  - [lib/presentation/features/review/bloc/weekly_review_cubit.dart](../../lib/presentation/features/review/bloc/weekly_review_cubit.dart)

---

## 3) High-Level Architecture

### 3.1 Component Diagram

```text
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              PRESENTATION LAYER                                  │
│  ┌─────────────────────┐  ┌─────────────────────┐  ┌─────────────────────────┐  │
│  │AttentionRulesSettings│  │ AttentionItemTile  │  │ SeverityIcon / Widgets │  │
│  │        Page         │  │                     │  │                         │  │
│  └──────────┬──────────┘  └──────────┬──────────┘  └───────────┬─────────────┘  │
└─────────────│───────────────────────│──────────────────────────│────────────────┘
              │                        │                          │
              │ toggle active          │ render items             │
              v                        v                          v
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   BLOCS                                          │
│  - build AttentionQuery                                                          │
│  - subscribe to engine and expose widget-ready state                             │
└─────────────────────────────────────────────────────────────────────────────────┘
              |
              v
┌─────────────────────────────────────────────────────────────────────────────────┐
│                            ATTENTION ENGINE                                      │
│                                                                                  │
│  ┌────────────────────────────────────────────────────────────────────────────┐ │
│  │                      watch(AttentionQuery query)                           │ │
│  │                                                                            │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │ │
│  │  │               CombineLatest4 (RxDart)                               │  │ │
│  │  │  ┌─────────────┐ ┌─────────┐ ┌──────────┐ ┌──────────────────────┐ │  │ │
│  │  │  │ rules$     │ │ tasks$ │ │ projects$│ │ snapshotOrPulse$     │ │  │ │
│  │  │  │ (filtered) │ │        │ │          │ │ (allocation+temporal)│ │  │ │
│  │  │  └─────────────┘ └─────────┘ └──────────┘ └──────────────────────┘ │  │ │
│  │  └─────────────────────────────────────────────────────────────────────┘  │ │
│  │                                    │                                       │ │
│  │                                    v                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │ │
│  │  │                     _evaluate(query, inputs)                        │  │ │
│  │  │                                                                     │  │ │
│  │  │  switch (rule.ruleType) {                                          │  │ │
│  │  │    problem           → _evaluateProblemRule()                      │  │ │
│  │  │    review            → _evaluateReviewRule()                       │  │ │
│  │  │    workflowStep      → [] (not implemented)                        │  │ │
│  │  │    workflowStep      → [] (not implemented)                        │  │ │
│  │  │  }                                                                  │  │ │
│  │  └─────────────────────────────────────────────────────────────────────┘  │ │
│  │                                    │                                       │ │
│  │                                    v                                       │ │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │ │
│  │  │                   SUPPRESSION LOGIC (_isSuppressed)                 │  │ │
│  │  │                                                                     │  │ │
│  │  │  • Check runtime state (nextEvaluateAfter, dismissedStateHash)     │  │ │
│  │  │  • Fallback to resolution records (dismissed/snoozed)              │  │ │
│  │  └─────────────────────────────────────────────────────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                  │
└────────────────────────────────────────────────────────────────────────────────┬─┘
                                                                                 │
         ┌───────────────────────────────────────┬────────────────────────────────┘
         │                                       │
         v                                       v
┌─────────────────────────────────┐    ┌─────────────────────────────────────────┐
│   AttentionRepository           │    │   AttentionTemporalInvalidationService  │
│                                 │    │                                         │
│  • watchActiveRules()           │    │   invalidations$ ◄─── TemporalTrigger   │
│  • getLatestResolution()        │    │                       Service           │
│  • watchRuntimeStateForRule()   │    │                          │              │
│  • upsertRuntimeState()         │    │   Emits pulses on:       │              │
│                                 │    │   • HomeDayBoundaryCrossed              │
└────────────┬────────────────────┘    │   • AppResumed                          │
             │                         └─────────────────────────────────────────┘
             v
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         DRIFT / POWERSYNC DATABASE                               │
│  ┌─────────────────────────┐  ┌────────────────────────┐  ┌──────────────────┐  │
│  │    attention_rules      │  │ attention_resolutions │  │attention_rule_   │  │
│  │                         │  │                        │  │runtime_state     │  │
│  │ • id                    │  │ • id                   │  │                  │  │
│  │ • rule_key              │  │ • rule_id              │  │ • rule_id        │  │
│  │ • domain                │  │ • entity_id            │  │ • entity_type    │  │
│  │ • category              │  │ • entity_type          │  │ • entity_id      │  │
│  │ • rule_type             │  │ • resolved_at          │  │ • state_hash     │  │
│  │ • trigger_type          │  │ • resolution_action    │  │ • dismissed_hash │  │
│  │ • trigger_config        │  │ • action_details       │  │ • next_evaluate_ │  │
│  │ • entity_selector       │  │                        │  │   after          │  │
│  │ • severity              │  └────────────────────────┘  └──────────────────┘  │
│  │ • active                │                                                    │
│  └─────────────────────────┘                                                    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 End-to-End Flow (Issues Summary)

This is the most canonical attention flow because it uses persisted rules and
dismissal tracking.

```text
1) Issues/Problems screen BLoC builds an AttentionQuery
   (domains={'issues'}, optional entityTypes/minSeverity)
2) It subscribes to AttentionEngine.watch(query)
4) Engine combines:
  - attentionRepository.watchActiveRules() filtered by query
  - taskRepository.watchAll() + projectRepository.watchAll()
  - temporal invalidation pulses (via AttentionTemporalInvalidationService)
5) Engine evaluates matching rules into AttentionItems, applying suppression
  semantics using runtime state (state hash + dismissal/snooze) and the latest
  resolution.
6) BLoC emits widget-ready state (items + counts)
7) Screen widgets render tiles (AttentionItemTile) and counts
```

### 3.3 Persistence Model (Rules + Resolutions)

The DB schema is intentionally small and generic.

```text
attention_rules
  - id (uuid)
  - rule_key
  - domain
  - category
  - rule_type (problem/review/workflowStep)
  - trigger_type (realtime/scheduled)
  - trigger_config (json)
  - entity_selector (json)
  - severity (info/warning/critical)
  - display_config (json)
  - resolution_actions (json)
  - active (bool)
  - source (systemTemplate/userCreated/imported)
  - created_at
  - updated_at

attention_resolutions
  - id (uuid)
  - rule_id (FK to attention_rules.id)
  - entity_id
  - entity_type
  - resolved_at
  - resolution_action (reviewed/skipped/snoozed/dismissed)
  - action_details (json)   // e.g. snooze_until, state_hash

attention_rule_runtime_state
  - id (uuid)
  - rule_id (FK to attention_rules.id)
  - entity_type (nullable)
  - entity_id (nullable)
  - state_hash (nullable)
  - dismissed_state_hash (nullable)
  - last_evaluated_at (nullable)
  - next_evaluate_after (nullable)
  - metadata (json)
  - created_at
  - updated_at
```

---

## 4) Core Concepts (Responsibilities)

### 4.1 `AttentionRule` (persisted configuration)

`AttentionRule` describes **what** to detect and **how** to present it.

- `ruleType` is the high-level category (problem/review/...)
- `entitySelector` identifies the target domain entities and predicate (e.g.
  `{"entity_type": "task", "predicate": "isOverdue"}`)
- `triggerType`/`triggerConfig` describes cadence/thresholds
- `dismissed`: hide until the entity's state hash changes
Important nuance in the current implementation:

- `triggerType`/`triggerConfig` are currently **metadata**. Evaluation runs while
  the app is active (reactive streams + in-app invalidation pulses); there is no
  background scheduler firing while the app is closed.

### 4.2 `AttentionItem` (evaluated output)

`AttentionItem` is the **result of evaluation**, designed for rendering.

- The UI consumes this (title, description, severity, available actions)
- It can carry additional `metadata` for navigation/action decisions

### 4.3 `AttentionResolution` (user response)

A resolution records user intent:

- `dismissed`: hide until the entity's state hash changes
- `snoozed`: hide until a future time (stored in `actionDetails`)
- `reviewed`/`skipped`: marks a review session as handled

In the current code, the engine uses:

- `AttentionRepositoryContract.getLatestResolution(ruleId, entityId)`
- `AttentionRepositoryContract.getRuntimeState(...)`

to decide whether an item should be suppressed (dismissed/snoozed) until either
time has passed or the entity's computed state hash changes.

### 4.4 `AttentionEngine` (reactive evaluation engine)

Primary responsibilities:

- Watch the **active** rules and relevant domain data streams
- Evaluate rule predicates against the **current** domain data
- Apply suppression semantics (dismiss/snooze/state-hash) via runtime state
- Apply "product policy" rules, for example:
  - Reviews: show a bounded set of due reviews (intentionally conservative)

### 4.5 `AttentionRepositoryContract` + Drift implementation

Responsibilities:

- Expose reactive views of rules (`watchAllRules`, `watchRulesByType`, ...)
- Persist user changes:
  - toggle active status
  - update configs
  - record resolutions
- Provide helper reads/writes needed by the engine:
  - `getLatestResolution` + resolution streams
  - runtime state access (`getRuntimeState`, `upsertRuntimeState`)

The Drift implementation is:

- [lib/data/attention/repositories/attention_repository_v2.dart](../../lib/data/attention/repositories/attention_repository_v2.dart)

### 4.6 System Defaults (Templates + Seeding)

The system defaults live in code as templates:

- [lib/domain/attention/system_attention_rules.dart](../../lib/domain/attention/system_attention_rules.dart)

and can be seeded into the database using:

- [lib/data/attention/maintenance/attention_seeder.dart](../../lib/data/attention/maintenance/attention_seeder.dart)

Important nuance in the current repo state:

- `AttentionSeeder.ensureSeeded()` is invoked from post-auth maintenance:
  [lib/data/infrastructure/powersync/api_connector.dart](../../lib/data/infrastructure/powersync/api_connector.dart)
  (`runPostAuthMaintenance`).

---

## 5) Integration Points (How Attention Surfaces in UI)

### 5.1 Weekly review maintenance

The weekly review flow subscribes to the attention engine and maps matching
items into maintenance sections (deadline risk, stale items, etc.) inside the
modal review experience.

### 5.2 Settings

Weekly review settings live under the general Settings screen. Users can toggle
maintenance checks on/off without managing individual attention rules directly.

### 5.4 Temporal Triggers Integration (In-App Only)

Current product scope: **time-based rules are only required to update when the app is running** (e.g. user opens the app and a journal review is now due).

To support this without introducing OS notifications or server scheduling, the runtime uses a lightweight invalidation stream:

- **Single time source**: `TemporalTriggerService`
  - emits `AppResumed` and `HomeDayBoundaryCrossed`
- **Attention invalidation**: `AttentionTemporalInvalidationService`
  - converts temporal events into `Stream<void>` invalidation pulses
- **Engine refresh**: the attention engine subscribes to invalidations and
  re-evaluates even when domain data streams haven't changed

This keeps attention evaluation reactive (screens still subscribe to attention
items via `AttentionEngine.watch(query)` from BLoCs) and ensures the UI
re-checks on:

- app resume (covers "user opens app")
- home-day boundary (covers "new day")

Important: `AttentionRule.triggerType`/`triggerConfig` remain **metadata** in this phase; the app does not run a background scheduler.

Future releases that require actual time-based reminders (firing while the app is closed) should add a separate **delivery layer** (local notifications and/or server push), without coupling it tightly to the attention engine.

---

## 6) Example Implementation: Add a New "Blocked Tasks" Problem Rule

This example shows how to add a new rule that flags tasks as "blocked", and how
it gets surfaced automatically in the Issues Summary section.

### 6.1 Add a new system rule template

In
[lib/domain/attention/system_attention_rules.dart](../../lib/domain/attention/system_attention_rules.dart)
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

### 6.2 Implement the predicate in `AttentionEngine`

In
[lib/domain/attention/engine/attention_engine.dart](../../lib/domain/attention/engine/attention_engine.dart)
extend `_evaluateTaskPredicate(...)`:

```dart
final matches = switch (predicate) {
  'isOverdue' => _isTaskOverdue(task, rule.triggerConfig),
  'isStale' => _isTaskStale(task, rule.triggerConfig),
  'isBlocked' => _isTaskBlocked(task, rule.triggerConfig),
  _ => false,
};
```

Then add `_isTaskBlocked(...)` using whatever "blocked" signal exists in your
`Task` model (examples: a `blocked` boolean, a status enum, or a non-empty
`blockedReason`).

To support "dismiss until state changes", ensure your task state hash includes
the fields that should cause resurfacing (e.g., `blockedReason`, `updatedAt`).

### 6.3 Ensure the rule exists in the database

System templates are already seeded from post-auth maintenance via
`AttentionSeeder.ensureSeeded()` (see
[lib/data/infrastructure/powersync/api_connector.dart](../../lib/data/infrastructure/powersync/api_connector.dart)
`runPostAuthMaintenance`). After adding a new template, it will be inserted on
the next post-auth maintenance run.

### 6.4 Result: Issues Summary picks it up automatically

Because the Issues/Problems screen BLoC builds an `AttentionQuery` and then
subscribes to `AttentionEngine.watch(query)`, the new rule will be included as
soon as:

- it is present in `attention_rules`
- it is `active=true`
- at least one task matches the predicate and is not dismissed

---

## 7) Known Gaps (Current State)

These are observed from the current code structure:

- **Resolution recording is not yet surfaced in the UI** for attention tiles
  (the repo supports `recordResolution`, but current tiles do not expose actions).
- **`workflowStep` rules are not implemented yet** in the engine (they currently
  yield no items).
- **No background scheduler**: `triggerType`/`triggerConfig` remain in-app
  metadata; evaluation updates while the app is running.

---

## 8) Scheduled vs Realtime Rules — Implementation Details

### 8.1 Current Behavior

The `AttentionTriggerType` enum defines two values:

| Trigger Type | Used By | Semantic Intent |
|--------------|---------|-----------------|
| `realtime` | `problemTaskOverdue`, `problemJournalOverdue`, allocation warnings | Detect immediately when condition is true |
| `scheduled` | `problemTaskStale`, `problemProjectIdle`, all `review*` rules | Detect based on time thresholds or periodic cadence |

**Important**: In the current implementation, `triggerType` is **metadata only**.
Both realtime and scheduled rules evaluate with the same cadence:

1. When **domain data streams emit** (tasks/projects/allocations change)
2. When **temporal invalidation pulses** fire (app resume, day boundary)

### 8.2 How Each Rule Type Evaluates

```text
AttentionEngine._evaluateRule(rule, ...)
    │
    └── switch (rule.ruleType) {
            problem           → _evaluateProblemRule()
            review            → _evaluateReviewRule()
            workflowStep      → [] (not implemented)
        }
```

The engine dispatches by `ruleType`, not `triggerType`. The `triggerConfig` is
used within specific evaluators:

- **Problem rules**: Use `triggerConfig.threshold_days` or `threshold_hours` to
  determine staleness/overdue thresholds
- **Review rules**: Use `triggerConfig.frequency_days` to compute due date based
  on last resolution

### 8.3 Future: True Scheduled Behavior

A true scheduled implementation would require:

1. **Background scheduling** (local notifications, WorkManager, or server push)
2. **Per-rule next-evaluation-time tracking** in `attention_rule_runtime_state`
3. **Engine awareness of `triggerType`** to skip expensive predicates until due

Current state: all rules are effectively **realtime-reactive** while the app is
open, with temporal invalidation pulses providing day-boundary and app-resume
refresh.

---

See also: [SUGGESTED_PICKS.md](SUGGESTED_PICKS.md) for how suggested picks integrate with My Day.
