# Phase 5 — Stats + Feedback Loops (Allocated vs Completed)

## Goal
Enable coaching-style insights that depend on allocation snapshots:
- Allocated vs completed counts
- Unallocated but completed (positive feedback)
- Repeated “allocated but not completed” signals

This phase is intentionally scoped to stats needed for My Day and alerts.

## Design decisions (locked)
- Allocation snapshot is the authoritative “what was planned”.
- Completion history is the authoritative “what was done”.
- Project progress proxy v1: any task completion under project today (UTC).

Additional locked decisions
- Stats that reference “values” must use **effective task values** (task overrides else inherit project values).
- “Project neglect” metrics used for coaching should prefer allocation-derived signals (days since last allocated) rather than only completion-derived signals.

## Data dependencies
- Allocation snapshots (Phase 1)
- Completion history tables already exist

## Implementation steps

### 1) Build stats queries
Create a small domain service (or analytics extension) that can compute for a UTC day:
- `allocatedTaskCount`
- `allocatedCompletedCount`
- `allocatedNotCompletedCount`
- `completedUnallocatedCount`

Add value distribution (to support value-aligned coaching):
- `allocatedByEffectivePrimaryValueId`
- `completedByEffectivePrimaryValueId`

Guideline: if Phase 1 persists `effective_primary_value_id`, prefer using it for stats to avoid recomputing effective values differently.

And per project:
- `allocatedTasksInProject`
- `completedTasksInProject`
- `projectProgressedToday` (proxy v1)

Add allocation-based “days since last allocated”:
- `daysSinceLastAllocatedForProject`
  - This should share implementation with Phase 4 review rules.

Locked interpretation: missing snapshot days
- If snapshot history coverage is insufficient, report this metric as “unknown/unavailable” rather than guessing.
- Do not treat missing snapshot days as automatically neglected unless you explicitly lock that policy and apply it everywhere.

### 2) Repeated allocated-not-completed
Define “repeat” metric:
- For a given entity, count number of days it appears in allocated set but does not complete that day.

Implementation notes:
- Needs historical allocation snapshots (version history across days).
- Start with a rolling window (e.g., last 14 days) to keep queries bounded.

### 3) Feedback surfaces
Keep UX minimal:
- My Day footer or existing stats surface can show:
  - completion ratio
  - positive: “You progressed X projects”
  - nudge: “Y allocated tasks carried over”

Value-alignment surface (minimal):
- A small summary like “Today’s work aligned most with: <top value>” derived from effective values.
- Do not add charts or new pages in this phase.

(No new pages or new UI components beyond what already exists.)

## Acceptance criteria
- Day-level counts match allocation snapshot + completion history.
- Project progress proxy v1 is computed correctly (completion within project today UTC).
- Repeat allocated-not-completed metric is stable across runs.

Additional acceptance criteria
- Value distribution metrics match effective values.
- Allocation-derived “days since last allocated” matches Phase 4 rule computations for the same period.

## Tests
- Unit tests with synthetic snapshots + completion events.
- Ensure UTC day bucketing matches snapshot bucketing.

## Notes / risks
- Ensure completion history queries don’t rely on `occurrence.completedAt`.
- Keep windows bounded for performance.

Added risk
- If tasks can move between projects over time, historical “allocated tasks in project” must use the snapshot’s captured `project_id` (Phase 1 recommended column), not today’s task.projectId.

Added risk
- If the app is not opened regularly, you can have sparse snapshot history; any coaching derived from day-count thresholds must handle this gracefully.
