# Suggested Picks Engine -- Architecture

> Audience: developers
>
> Scope: the "Suggested picks" allocation path used by the My Day ritual.

For the full My Day + Plan My Day architecture (including routines integration),
see: [MY_DAY_PLAN_MY_DAY.md](MY_DAY_PLAN_MY_DAY.md).

## 1) Purpose

Taskly's "Suggested picks" are meant to be calm, values-led recommendations.
They help users select a small set of tasks for today without turning the app
into an urgency/priority optimizer.

Key goals:

- Ratings-led distribution (based on weekly value ratings)
- Explainability ("Why suggested") with stable reason codes
- Offline-first: local DB remains the source of truth

## 2) Layering + ownership

- **Presentation** owns screens and BLoCs (e.g. My Day BLoCs). Widgets do not
  talk to repositories directly.
- **Domain** owns allocation orchestration, suggestion pooling, and scoring
  policy.
- **Data** persists tasks/values and the user's **My Day selection**.

Primary entrypoints:

- `TaskSuggestionService.getSnapshot(...)` produces the **Suggested** snapshot
  (ephemeral suggestions + ranking/pooling + snoozed filtering).
- `AllocationOrchestrator.getSuggestedSnapshot(...)` computes the raw
  allocation used by the suggestion service.
- `MyDayRepositoryContract.watchDay(dayKeyUtc)` provides the **persisted ritual
  selection** for the day (source of truth for "today").

Core engine:

- `SuggestedPicksEngine` is the only allocator used for "Suggested picks".

## 3) Data flow (runtime)

```text
My Day screen (Presentation)
  -> MyDayRepository.watchDay(todayDayKeyUtc)
    -> if ritual completed: render persisted picks
    -> else: show ritual flow and suggestions

Ritual flow (Presentation)
  -> TaskSuggestionService.getSnapshot(batchCount | targetCount)
    -> TaskRepository.getAll(incomplete)
    -> AllocationOrchestrator.getSuggestedSnapshot(...):
       -> repositories (tasks, projects, anchor state, settings)
       -> build value weights (weekly ratings only)
       -> SuggestedPicksEngine.allocate(parameters)
       -> AllocationResult (allocatedTasks + excludedTasks + reasoning)
    -> filter snoozed tasks from suggested list
    -> per-value pooling + rank reindexing
    -> TaskSuggestionSnapshot (suggested + rating summaries)
  -> user selects tasks (including non-suggested due/starts/planned)
  -> optional: pass triage + routine selection counts by value to adjust quotas
  -> MyDayRepository.setDayPicks(dayKeyUtc, picks, ritualCompletedAtUtc)
    -> Drift / PowerSync tables: my_day_days + my_day_picks
```

Notes:
- Allocation executes synchronously; any async inputs are pre-fetched in the
  orchestrator and passed into `AllocationParameters`.
- Suggested picks are **not persisted** as an allocation snapshot.
  Only the user's selection is persisted.
- My Day persistence uses deterministic UUID v5 IDs (via `IdGenerator`) for
  `my_day_days` and `my_day_picks` to support offline-first upserts and
  cross-device convergence.
- When the ritual is confirmed, the app records the most recent anchor
  projects in `project_anchor_state` for rotation pressure (user action only).

## 4) Algorithm overview

### 4.1 Project-first anchor allocation (baseline)

Given:

- categories: valueId -> weight
- anchorCount (per batch)

Compute integer quotas per value that sum to `anchorCount`, proportional to
weights. These quotas select **anchor projects**, not tasks.

Selection is then done per value using a calm tie-break sort:

- project deadline, then project priority
- days since last progress (more idle first)
- rotation pressure (prefer projects not anchored recently)
- name

### 4.1.1 Ratings-based signal (weekly values)

Suggested picks always use weekly value ratings:

- Category weights come from weekly value ratings (1-10 scale).
- Ratings are averaged over a 4-week window (simple mean).
- Ratings are required weekly; if no rated values exist, allocation returns
  `requiresRatings = true`.

### 4.2 Value balancing (removed)

Value balancing based on recent completions is no longer part of the suggested
picks model. Ratings are the only weighting signal.

### 4.3 Calm ordering (no multiplicative boosts)

Within a value, tasks are ordered using deterministic tie-breaks:

- urgency (deadline proximity) as a tie-break
- deadline, then priority
- updatedAt, createdAt, start date
- name

This avoids "spiky" ranking behavior and prevents urgency/priority from becoming
an implicit global optimizer.

### 4.4 Anchor task selection + free slots

- For each selected anchor project, up to `tasksPerAnchorMax` tasks are chosen.
- The allocator then fills **free slots** from remaining tasks across all
  anchors using the same calm ordering.
- `readinessFilter` skips projects with no actionable tasks.

### 4.5 Spotlight cue (removed)

The completion-based spotlight cue is no longer used.

### 4.6 Per-value suggestion pools (Plan My Day)

For the Plan My Day ritual, suggested picks are now **pooled per value** to
support progressive disclosure in the UI:

- Each value gets a **default visible count** based on rating average + trend.
- The suggestion service returns a **per-value pool** sized to
  `defaultVisible + 6` (showMoreIncrement = 3).
- UI reveals the pool progressively ("Show more") without re-running allocation.
  Presentation may additionally cap the visible count.

## 5) Settings model

User-facing setting:

- **Suggested batch size** -> `AllocationConfig.suggestionsPerBatch`

Implementation notes:

- Analytics lookback is a fixed window (currently 14 days) to avoid exposing
  tuning knobs.
- `AllocationConfig.focusMode` is persisted and echoed in allocation results
  but does not change `SuggestedPicksEngine` behavior today.

My Day selection behavior (global):

- Routine picks and triage (due/planned) picks are passed in as value counts and
  reduce anchor quotas for their values.

Urgency settings:

- Urgency thresholds live in `StrategySettings.taskUrgencyThresholdDays`.
  Urgency is detected via `UrgencyDetector`.

Anchor settings (strategy):

- `anchorCount`, `tasksPerAnchorMin`, `tasksPerAnchorMax`
- `rotationPressureDays`
- `readinessFilter`
- `freeSlots`
  - `tasksPerAnchorMin` is currently not enforced by the engine.

## 6) Explainability

Each allocated task includes `reasonCodes` that the UI can render as "Why
suggested" chips.

When the ritual is confirmed, Taskly persists a subset of suggestion metadata
into `my_day_picks` so the UI can continue to render "Why suggested" without
recomputing or snapshot persistence:

- `suggestion_rank` (1-based rank within the suggested list)
- `qualifying_value_id`
- `reason_codes` (stored as a JSON array)

Important reason codes:

- `valueAlignment` -- task matches a value category
- `crossValue` -- task spans multiple values
- `urgency` -- deadline is near
- `priority` -- task has explicit priority metadata

## 7) Guardrails + failure modes

- **No values defined**: allocation returns `requiresValueSetup = true`.
- **ratings missing/stale** (ratings-based mode): allocation returns
  `requiresRatings = true`.
- **maxTasks <= 0 / anchorCount == 0**: allocation returns no suggestions.
- **No eligible projects**: allocation returns no suggestions with exclusions.
- **Category has no projects**: remaining anchors are filled from best remaining
  projects across other categories.
- **Tasks without projects or projects without values** are excluded up-front.

My Day integration notes:

- The "missing due" / "missing starts" UX is computed dynamically at render
  time from current tasks; there are no "frozen candidates".
- The persisted selection is stored in buckets (see `MyDayPickBucket`), so the
  UI can show "Today / Due soon / Starts today" sections while remaining robust
  to task edits/deletes.

## 8) Code locations

- Domain orchestrator: `packages/taskly_domain/lib/src/allocation/engine/allocation_orchestrator.dart`
- Engine: `packages/taskly_domain/lib/src/allocation/engine/suggested_picks_engine.dart`
- Suggestion service: `packages/taskly_domain/lib/src/services/suggestions/task_suggestion_service.dart`
- Settings model: `packages/taskly_domain/lib/src/allocation/model/allocation_config.dart`
- My Day selection model: `packages/taskly_domain/lib/src/my_day/model/my_day_pick.dart`
- My Day persistence contract: `packages/taskly_domain/lib/src/interfaces/my_day_repository_contract.dart`
- My Day persistence impl: `packages/taskly_data/lib/src/features/my_day/repositories/my_day_repository_impl.dart`

## 9) Non-goals

- Multiple competing allocation strategies
- User-tunable scoring knobs (urgency multipliers, weighting sliders, etc.)
- Project "diversity preference" as a separate optimizer


