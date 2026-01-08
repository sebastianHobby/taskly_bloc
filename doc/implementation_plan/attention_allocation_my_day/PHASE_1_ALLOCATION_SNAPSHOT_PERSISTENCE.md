# Phase 1 — Allocation Snapshot Persistence

## Prerequisites (must be decided + implemented first)
This implementation plan assumes the following product decisions are now *part of the system contract*.

### A) Project values are required
- Each Project must have:
  - a **primary value**
  - optional **secondary values**
- This requirement must be enforced in the Project create/edit UX and validated in domain/persistence.
  - Minimum implementation: disallow saving a project with no `primaryValueId`.

### B) Task value inheritance + override semantics (locked)
Tasks inherit values from their project by default.

Define **effective task values** used everywhere scoring/allocation/attention needs “what values does this task represent?”

- If a Task has explicit values set: effective values = task values.
- Else if the Task has a project and the Project has values: effective values = project values.
- Else: effective values = empty.

Guideline: do not introduce a new “inherit flag” unless you need an explicit third mode.
Keep it simple: “values set on task means override; empty means inherit”.

### C) Allocation strategy decision (task-first + project guard rails)
Allocation remains task-first, but with project-aware guard rails:

- Base task score continues to come from existing scoring (importance/urgency/etc).
- Apply a *soft diversity penalty* that increases as a single project dominates today’s allocation.
- Optional: add a *hard cap* (max tasks per project per day) as a configuration toggle.

Important: “deadline safety” is not a separate allocation concept in this plan; deadline-related coaching belongs in attention rules, not scoring.

Recommended minimal contract for the guard rails:
- Diversity penalty is a function of `allocatedCountForProject` during selection.
- Project priority can influence:
  - (a) a small multiplier on tasks in that project, and/or
  - (b) slower diversity-penalty growth for that project.

This plan does not require the allocator rewrite to land in Phase 1, but snapshot persistence must record enough information to support the downstream review rules.

## Goal
Persist the daily allocation *allocated membership only* as a stable fact source for:
- My Day rendering (consistent throughout the day)
- allocation warnings (alerts derived from “should be allocated” minus “is allocated”)
- future stats such as “allocated vs completed” and “allocated-not-completed repeats”

This phase does **not** change My Day UI or attention evaluation. It creates the
persistence layer and write path.

## Non-goals
- Persisting excluded/not-selected items.
- Implementing new alert logic.
- Implementing scoring beyond current allocation.

## Design decisions (locked)
- Persist only allocated items.
- Bucket by UTC day.
- Latest snapshot wins; create a new snapshot version when allocated membership changes.
- Increment allocation version only when membership changes.

## Data model
Create three tables (PowerSync/Drift):

1) `allocation_snapshots`
- `id` (string, pk)
- `day_utc` (date or ISO yyyy-mm-dd string)
- `version` (int)
- `created_at` (timestamp)
- `updated_at` (timestamp)

2) `allocation_snapshot_entries`
- `snapshot_id` (fk)
- `entity_type` (string enum, start with `task`, add `project` later)
- `entity_id` (string)
- `qualifying_value_id` (nullable string; useful for debugging/analytics)
- `allocation_score` (nullable double; optional, but recommended)

Recommended additions (to support agreed UX + review rules):
- `project_id` (nullable string)
  - For `entity_type=task`: store the task’s `projectId` at allocation time.
  - Enables grouping, project representation checks, and stable analytics without extra joins.
- `effective_primary_value_id` (nullable string)
  - The primary value actually used for scoring the task *after inheritance/override resolution*.
  - This avoids confusion when tasks inherit values.

Field semantics (locked)
- Logic-driving fields: `entity_type`, `entity_id`, `project_id` (if present), `effective_primary_value_id`.
- Debug/analytics fields: `qualifying_value_id`, `allocation_score`.
  - These may change without a version bump and must not be required for correctness.

Uniqueness:
- Unique `(snapshot_id, entity_type, entity_id)`

3) `allocation_snapshot_current`
- singleton pointer to current snapshot for `day_utc`
- either:
  - `(day_utc, snapshot_id)` unique by `day_utc`, or
  - store current snapshot row directly in `allocation_snapshots` and query max(version)

Recommendation: keep it simple — query `allocation_snapshots` by `day_utc` ordered
by `version desc limit 1`.

## Write path

### Trigger
Allocation is recomputed reactively via `AllocationOrchestrator.watchAllocation()`.

- On each emitted `AllocationResult`, persist snapshot for `today_utc`.
- If allocated membership differs from last persisted snapshot:
  - persist a new snapshot version
  - increment version

### Equality
Define “membership equality” as:
- same set of `(entity_type, entity_id)` for allocated items

Ignore score changes for versioning unless you explicitly want “score-only” changes to
invalidate dismissals. Default: membership-only triggers version change.

Clarification
- In this plan, “allocation changes” means **allocated membership changes** (version bump).
- Score-only changes do not count as a change for dismissal resets.

## Read path (minimal)
Expose a repository API:
- `Future<AllocationSnapshot?> getLatestForUtcDay(DateTime dayUtc)`
- `Stream<AllocationSnapshot?> watchLatestForTodayUtc()`
- `Future<Set<EntityRef>> getAllocatedSetForTodayUtc()`

Where `EntityRef = (entityType, entityId)`.

## Implementation steps
0) Implement prerequisites A–C above (project values required, task effective values, allocation guard rails decision).

1) Add DB schema tables and drift models.
  - Include the recommended additions (`project_id`, `effective_primary_value_id`) unless you have a strong reason not to.
2) Add repository/service layer:
  - `AllocationSnapshotRepository`
3) Wire into allocation pipeline:
  - In orchestrator or higher-level application service, persist on allocation emission.
  - Ensure debounce/throttle if needed (avoid rapid writes during stream churn).
  - When persisting task entries, store:
    - `project_id`
    - `effective_primary_value_id` (resolved with inheritance/override rules)
4) Add a UTC-day helper:
  - `DateTime toUtcDay(DateTime now) { final utc = now.toUtc(); return DateTime.utc(utc.year, utc.month, utc.day); }`

## Acceptance criteria
- Running the app and triggering allocation writes a single snapshot for today UTC.
- Recomputing allocation without membership change does not bump version.
- Recomputing allocation with membership change bumps version and replaces entries.
- Snapshot entries include all allocated tasks.

Additional acceptance criteria (from agreed decisions):
- Snapshot entries for allocated tasks include `project_id` (nullable) and the resolved effective primary value id.
- No downstream feature needs `excludedTasks` persistence.

## Tests
- Unit test repository:
  - create snapshot, overwrite snapshot, verify version increments.
  - equality check correctness.
- Integration-ish test (if available):
  - simulate two `AllocationResult`s and verify persistence.

## Notes / risks
- Avoid using existing `excludedTasks` for persistence.
- Keep writes resilient if allocation stream emits frequently.

Added risks:
- If effective values are not resolved centrally, you will create subtle mismatches between scoring, allocation, attention rules, and UI.
