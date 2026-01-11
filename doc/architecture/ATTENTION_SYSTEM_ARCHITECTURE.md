# Attention System â€” Architecture Overview

> Audience: developers + architects
>
> Scope: the *current* attention system in this repo (rules â†’ evaluation â†’ persistence â†’ section rendering), including where it plugs into the unified screen pipeline.

## 1) Executive Summary

Tasklyâ€™s **attention system** is a rule-based mechanism that detects items that
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
- **`AttentionEngine`** is the reactive evaluation engine. Sections construct an
  **`AttentionQuery`** and subscribe to `AttentionEngine.watch(query)`.
- User actions are stored as **`AttentionResolution`** rows. â€œDismiss until
  state changesâ€ is implemented using engine-owned runtime state
  (state-hash + dismissal/snooze semantics).

---

## 2) Where Things Live (Folder Map)

### Attention bounded context (single entrypoint)
- Bounded-context entrypoint (barrel exports):
  - [lib/domain/attention/attention.dart](../lib/domain/attention/attention.dart)

Key subfolders:
- Contracts: [lib/domain/attention/contracts/](../lib/domain/attention/contracts/)
- Engine: [lib/domain/attention/engine/](../lib/domain/attention/engine/)
- Models: [lib/domain/attention/model/](../lib/domain/attention/model/)
- Query: [lib/domain/attention/query/](../lib/domain/attention/query/)

Key files:
- [lib/domain/attention/model/attention_rule.dart](../lib/domain/attention/model/attention_rule.dart)
- [lib/domain/attention/model/attention_item.dart](../lib/domain/attention/model/attention_item.dart)
- [lib/domain/attention/model/attention_resolution.dart](../lib/domain/attention/model/attention_resolution.dart)
- [lib/domain/attention/model/attention_rule_runtime_state.dart](../lib/domain/attention/model/attention_rule_runtime_state.dart)
- [lib/domain/attention/system_attention_rules.dart](../lib/domain/attention/system_attention_rules.dart)
- [lib/domain/attention/engine/attention_engine.dart](../lib/domain/attention/engine/attention_engine.dart)

### Domain services (time-based invalidations)
- [lib/domain/services/attention/attention_temporal_invalidation_service.dart](../lib/domain/services/attention/attention_temporal_invalidation_service.dart)

### Data layer (persistence + seeding)
- Repository impl:
  - [lib/data/repositories/attention_repository_v2.dart](../lib/data/repositories/attention_repository_v2.dart)
- Drift tables (generated):
  - [lib/data/infrastructure/drift/features/attention_tables.drift.dart](../lib/data/infrastructure/drift/features/attention_tables.drift.dart)
- Seeder:
  - [lib/data/services/attention_seeder.dart](../lib/data/services/attention_seeder.dart)

### Screen integration (templates)
- Issues summary:
  - [lib/domain/screens/templates/interpreters/issues_summary_section_interpreter.dart](../lib/domain/screens/templates/interpreters/issues_summary_section_interpreter.dart)
- Allocation alerts:
  - [lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart](../lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart)
- Check-in summary:
  - [lib/domain/screens/templates/interpreters/check_in_summary_section_interpreter.dart](../lib/domain/screens/templates/interpreters/check_in_summary_section_interpreter.dart)

### Presentation (widgets + settings)
- Settings page:
  - [lib/presentation/features/attention/view/attention_rules_settings_page.dart](../lib/presentation/features/attention/view/attention_rules_settings_page.dart)
- Shared widgets used by the support sections:
  - [lib/presentation/features/screens/renderers/attention_support_section_widgets.dart](../lib/presentation/features/screens/renderers/attention_support_section_widgets.dart)

---

## 3) High-Level Architecture

### 3.1 Component Diagram

```text
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                       Presentation                          â”‚
â”‚  - AttentionRulesSettingsPage (toggle rules)                â”‚
â”‚  - Support section renderers + AttentionItemTile            â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚                               â”‚
                â”‚                               â”‚
                v                               v
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚  Screen Template Interpreters  â”‚   â”‚     Other domain pipelines     â”‚
â”‚  - IssuesSummarySection...     â”‚   â”‚  (e.g. AllocationOrchestrator) â”‚
â”‚  - CheckInSummarySection...    â”‚   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
â”‚  - AllocationAlertsSection...  â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚
                v
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                       Domain Service                        â”‚
â”‚                     AttentionEngine                          â”‚
â”‚  - watches active rules + domain data                         â”‚
â”‚  - evaluates rules into AttentionItems                        â”‚
â”‚  - applies suppression via runtime state + resolutions         â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚                               â”‚
                v                               v
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”   â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚      AttentionRepository        â”‚   â”‚  Task/Project repositories     â”‚
â”‚  - rules + resolutions          â”‚   â”‚  (data to evaluate rules on)   â”‚
â”‚  - runtime state                â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜   â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¬â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                â”‚                                   â”‚
                v                                   v
â”Œâ”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
â”‚                     Drift / PowerSync DB                    â”‚
â”‚  attention_rules, attention_resolutions, attention_rule_runtime_state â”‚
â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
```

### 3.2 End-to-End Flow (Issues Summary)

This is the most â€œcanonicalâ€ attention flow because it uses persisted rules and
dismissal tracking.

```text
1) Section interpreter runs: IssuesSummarySectionInterpreter.fetch(params)
2) It builds an AttentionQuery (domains={'issues'}, optional entityTypes/minSeverity)
3) It subscribes to AttentionEngine.watch(query)
4) Engine combines:
  - attentionRepository.watchActiveRules() filtered by query
  - taskRepository.watchAll() + projectRepository.watchAll()
  - temporal invalidation pulses (via AttentionTemporalInvalidationService)
5) Engine evaluates matching rules into AttentionItems, applying suppression
  semantics using runtime state (state hash + dismissal/snooze) and the latest
  resolution.
6) Interpreter packages items into SectionDataResult.issuesSummary(...)
7) Renderer displays tiles (AttentionItemTile) and counts
```

### 3.3 Persistence Model (Rules + Resolutions)

The DB schema is intentionally small and generic.

```text
attention_rules
  - id (uuid)
  - rule_key
  - domain
  - category
  - rule_type (problem/review/workflowStep/allocationWarning)
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

- `ruleType` is the high-level category (problem/review/allocationWarning/â€¦)
- `entitySelector` identifies the target domain entities and predicate (e.g.
  `{"entity_type": "task", "predicate": "isOverdue"}`)
- `triggerType`/`triggerConfig` describes cadence/thresholds

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

- `dismissed`: hide until the entityâ€™s â€œstate hashâ€ changes
- `snoozed`: hide until a future time (stored in `actionDetails`)
- `reviewed`/`skipped`: marks a review session as handled

In the current code, the engine uses:

- `AttentionRepositoryContract.getLatestResolution(ruleId, entityId)`
- `AttentionRepositoryContract.getRuntimeState(...)`

to decide whether an item should be suppressed (dismissed/snoozed) until either
time has passed or the entityâ€™s computed state hash changes.

### 4.4 `AttentionEngine` (reactive evaluation engine)

Primary responsibilities:

- Watch the **active** rules and relevant domain data streams
- Evaluate rule predicates against the **current** domain data
- Apply suppression semantics (dismiss/snooze/state-hash) via runtime state
- Apply â€œproduct policyâ€ rules, for example:
  - Reviews: show a bounded set of due reviews (intentionally conservative)

### 4.5 `AttentionRepositoryContract` + Drift implementation

Responsibilities:

- Expose reactive views of rules (`watchAllRules`, `watchRulesByType`, â€¦)
- Persist user changes:
  - toggle active status
  - update configs
  - record resolutions
- Provide helper reads/writes needed by the engine:
  - `getLatestResolution` + resolution streams
  - runtime state access (`getRuntimeState`, `upsertRuntimeState`)

The Drift implementation is:

- [lib/data/repositories/attention_repository_v2.dart](../lib/data/repositories/attention_repository_v2.dart)

### 4.6 System Defaults (Templates + Seeding)

The system defaults live in code as templates:

- [lib/domain/attention/system_attention_rules.dart](../lib/domain/attention/system_attention_rules.dart)

and can be seeded into the database using:

- [lib/data/services/attention_seeder.dart](../lib/data/services/attention_seeder.dart)

Important nuance in the current repo state:

- `AttentionSeeder.ensureSeeded()` is invoked from post-auth maintenance:
  [lib/data/infrastructure/powersync/api_connector.dart](../lib/data/infrastructure/powersync/api_connector.dart)
  (`runPostAuthMaintenance`).

---

## 5) Integration Points (How Attention Surfaces in UI)

### 5.1 Support sections (unified screens)

- `issuesSummary` â†’ subscribes to `AttentionEngine.watch(AttentionQuery(domains: {'issues'}))`
  - [lib/domain/screens/templates/interpreters/issues_summary_section_interpreter.dart](../lib/domain/screens/templates/interpreters/issues_summary_section_interpreter.dart)

- `checkInSummary` â†’ subscribes to `AttentionEngine.watch(AttentionQuery(domains: {'reviews'}))`
  - [lib/domain/screens/templates/interpreters/check_in_summary_section_interpreter.dart](../lib/domain/screens/templates/interpreters/check_in_summary_section_interpreter.dart)

- `allocationAlerts` â†’ subscribes to `AttentionEngine.watch(AttentionQuery(domains: {'allocation'}))`
  - [lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart](../lib/domain/screens/templates/interpreters/allocation_alerts_section_interpreter.dart)

### 5.2 Settings: toggling attention rules

- The settings UI reads all rules once and lets users toggle `active`.
  - [lib/presentation/features/attention/view/attention_rules_settings_page.dart](../lib/presentation/features/attention/view/attention_rules_settings_page.dart)

### 5.3 Attention widgets

- Rendering is currently â€œdisplay-onlyâ€ tiles:
  - `AttentionItemTile` + `SeverityIcon`
  - [lib/presentation/features/screens/renderers/attention_support_section_widgets.dart](../lib/presentation/features/screens/renderers/attention_support_section_widgets.dart)

### 5.4 Temporal Triggers Integration (In-App Only)

Current product scope: **time-based rules are only required to update when the app is running** (e.g. user opens the app and a wellbeing review is now due).

To support this without introducing OS notifications or server scheduling, the runtime uses a lightweight invalidation stream:

- **Single time source**: `TemporalTriggerService`
  - emits `AppResumed` and `HomeDayBoundaryCrossed`
- **Attention invalidation**: `AttentionTemporalInvalidationService`
  - converts temporal events into `Stream<void>` invalidation pulses
- **Engine refresh**: the attention engine subscribes to invalidations and
  re-evaluates even when domain data streams havenâ€™t changed

This keeps attention evaluation driven by the unified screen pipeline (sections
still subscribe to attention items via `AttentionEngine.watch(query)`), but
ensures the UI re-checks on:

- app resume (covers â€œuser opens appâ€)
- home-day boundary (covers â€œnew dayâ€)

Important: `AttentionRule.triggerType`/`triggerConfig` remain **metadata** in this phase; the app does not run a background scheduler.

Future releases that require actual time-based reminders (firing while the app is closed) should add a separate **delivery layer** (local notifications and/or server push), without coupling it tightly to the attention engine.

---

## 6) Example Implementation: Add a New â€œBlocked Tasksâ€ Problem Rule

This example shows how to add a new rule that flags tasks as â€œblockedâ€, and how
it gets surfaced automatically in the Issues Summary section.

### 6.1 Add a new system rule template

In
[lib/domain/attention/system_attention_rules.dart](../lib/domain/attention/system_attention_rules.dart)
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
[lib/domain/attention/engine/attention_engine.dart](../lib/domain/attention/engine/attention_engine.dart)
extend `_evaluateTaskPredicate(...)`:

```dart
final matches = switch (predicate) {
  'isOverdue' => _isTaskOverdue(task, rule.triggerConfig),
  'isStale' => _isTaskStale(task, rule.triggerConfig),
  'isBlocked' => _isTaskBlocked(task, rule.triggerConfig),
  _ => false,
};
```

Then add `_isTaskBlocked(...)` using whatever â€œblockedâ€ signal exists in your
`Task` model (examples: a `blocked` boolean, a status enum, or a non-empty
`blockedReason`).

To support â€œdismiss until state changesâ€, ensure your task state hash includes
the fields that should cause resurfacing (e.g., `blockedReason`, `updatedAt`).

### 6.3 Ensure the rule exists in the database

System templates are already seeded from post-auth maintenance via
`AttentionSeeder.ensureSeeded()` (see
[lib/data/infrastructure/powersync/api_connector.dart](../lib/data/infrastructure/powersync/api_connector.dart)
`runPostAuthMaintenance`). After adding a new template, it will be inserted on
the next post-auth maintenance run.

### 6.4 Result: Issues Summary picks it up automatically

Because `IssuesSummarySectionInterpreter` builds an `AttentionQuery` and then
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

See also: [doc/architecture/ALLOCATION_SYSTEM_ARCHITECTURE.md](ALLOCATION_SYSTEM_ARCHITECTURE.md) for allocation snapshot behavior and how allocation feeds the `allocationAlerts` section.
