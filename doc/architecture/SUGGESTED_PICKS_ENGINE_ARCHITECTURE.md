# Suggested Picks Engine — Architecture

> Audience: developers
>
> Scope: the “Suggested picks” allocation path used by the My Day ritual.

## 1) Purpose

Taskly’s “Suggested picks” are meant to be calm, values-led recommendations.
They help users select a small set of tasks for today without turning the app
into an urgency/priority optimizer.

Key goals:

- Values-led distribution (proportional to value weights)
- Optional, bounded value balancing (a gentle nudge)
- Explainability (“Why suggested”) with stable reason codes
- Offline-first: local DB remains the source of truth

## 2) Layering + ownership

- **Presentation** owns screens and BLoCs (e.g. My Day BLoCs). Widgets do not
  talk to repositories directly.
- **Domain** owns the allocation orchestration and scoring policy.
- **Data** persists tasks/values and supplies analytics aggregates.

Primary entrypoint:

- `AllocationOrchestrator.watchAllocation()` computes the Focus/Suggested list.

Core engine:

- `SuggestedPicksEngine` is the only allocator used for “Suggested picks”.

## 3) Data flow (runtime)

```text
My Day BLoC
  -> AllocationOrchestrator.watchAllocation()
     -> repositories/watchers (tasks, projects, settings)
     -> build value category weights (from Value.priority)
     -> (optional) AnalyticsService.getRecentCompletionsByValue()
     -> SuggestedPicksEngine.allocate(parameters)
     -> AllocationResult (allocatedTasks + excludedTasks + reasoning)
```

Notes:

- Pinned tasks/projects are handled in the orchestrator (not the engine).
- Allocation executes synchronously; any async inputs are pre-fetched in the
  orchestrator and passed into `AllocationParameters`.

## 4) Algorithm overview

### 4.1 Proportional quotas (baseline)

Given:

- categories: valueId → weight
- suggestedCount (daily limit)

Compute integer quotas per value that sum to `suggestedCount`, proportional to
weights.

Selection is then done per value using a calm tie-break sort.

### 4.2 Bounded value balancing (“Keep my values in balance”)

When enabled, the engine may perform a **bounded quota repair** pass:

- Uses recent completion counts per value (via analytics) to identify values the
  user has focused on less recently.
- Performs a small, capped reallocation of quota toward the most-neglected
  values.
- The cap is intentionally tight so this never “overrides the plan”.

This produces explainability via the reason code `neglectBalance` for any tasks
that enter the selection due to the quota repair step.

### 4.3 Calm ordering (no multiplicative boosts)

Within a value, tasks are ordered using deterministic tie-breaks:

- urgency (deadline proximity) as a tie-break
- then timestamps / name

This avoids “spiky” ranking behavior and prevents urgency/priority from becoming
an implicit global optimizer.

## 5) Settings model

User-facing setting:

- **Keep my values in balance** → `AllocationConfig.strategySettings.enableNeglectWeighting`

Implementation notes:

- The orchestrator treats this as a boolean on/off toggle.
- Analytics lookback is a fixed window (currently 14 days) to avoid exposing
  tuning knobs.

Urgency settings:

- Urgency thresholds and `urgentTaskBehavior` remain in `StrategySettings`.
  Urgency is detected via `UrgencyDetector`.

## 6) Explainability

Each allocated task includes `reasonCodes` that the UI can render as “Why
suggested” chips.

Important reason codes:

- `valueAlignment` — task matches a value category
- `crossValue` — task spans multiple values
- `urgency` — deadline is near
- `priority` — task has explicit priority metadata
- `neglectBalance` — selected due to bounded value balancing

## 7) Guardrails + failure modes

- **No values defined**: allocation returns `requiresValueSetup = true`.
- **dailyLimit == 0**: allocation returns no suggestions.
- **No completion history**: balancing is disabled automatically.
- **Category has no tasks**: remaining slots are filled from best remaining tasks
  across other categories.

## 8) Code locations

- Domain orchestrator: `packages/taskly_domain/lib/src/allocation/engine/allocation_orchestrator.dart`
- Engine: `packages/taskly_domain/lib/src/allocation/engine/suggested_picks_engine.dart`
- Settings model: `packages/taskly_domain/lib/src/allocation/model/allocation_config.dart`

## 9) Non-goals

- Multiple competing allocation strategies
- User-tunable scoring knobs (urgency multipliers, weighting sliders, etc.)
- Project “diversity preference” as a separate optimizer
