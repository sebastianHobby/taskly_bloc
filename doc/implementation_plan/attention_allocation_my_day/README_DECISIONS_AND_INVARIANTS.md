# Attention + Allocation + My Day — Decisions and Invariants

This folder implements the end-to-end plan for:
- persisting daily allocation snapshots
- deriving attention items from allocation facts
- rendering My Day from persisted allocation
- adding project health review rules
- enabling stats/feedback loops

## Locked product decisions (must hold across all phases)

### 1) Values → Projects → Tasks (effective values)
- Projects must have:
  - primary value (required)
  - secondary values (optional)
- Tasks inherit project values by default.
- Tasks can override by setting their own explicit values.

Definition: **effective task values**
- If task has explicit values: use those.
- Else if task has project values: inherit project values.
- Else: empty.

Guideline: implement effective values in one shared domain helper/service and reuse it for:
- task scoring
- allocation category selection
- attention predicates
- UI display

### 2) Allocation style
- Allocation is task-first.
- Project-aware guard rails are applied (soft diversity penalty; optional hard cap).
- “Deadline safety” is not a scoring concept in this plan; deadline coaching belongs in attention rules.

### 3) Project health reviews are REVIEW items
Project health items are coaching prompts, not urgent failures.

Initial rule types:
1) High-value project neglected
2) No allocated tasks for project recently
3) No allocatable tasks for project for >1 day (time gated)

### 4) FocusMode provides defaults
- FocusMode defines default thresholds for project health review rules.
- If the user edits any review setting, the preset becomes Custom/Personalized.

### 5) Allocation snapshots are membership-only
- Persist allocated membership only.
- Bucket by UTC day.
- Bump snapshot version only when membership changes.

Clarification: “allocation changes” means **membership changes**
- Dismissals/reset behavior is keyed to `allocation_day_utc` + `allocation_version`.
- Since versioning is membership-only, score-only changes do **not** reset dismissals.

Recommended snapshot fields for tasks:
- project_id
- effective_primary_value_id

Logic-driving vs debug fields (locked)
- Logic-driving fields: `entity_type`, `entity_id`, `project_id` (if present), `effective_primary_value_id`.
- Debug/analytics fields: `qualifying_value_id`, `allocation_score`.
  - These must not be required for correctness (they may change without a version bump).

## Locked interpretation: what is “today UTC”?
“Today UTC” is the calendar day computed from `DateTime.now().toUtc()`.

This affects:
- snapshot bucketing
- dismissal state hashes
- gating thresholds
- stats day boundaries

## Locked interpretation: missing snapshot days
Snapshots are created when allocation is computed (typically when the app is opened).
This can lead to missing days.

For any metric that uses “days since …” across calendar days (neglect, gating):
- Treat missing days as **unknown** (not automatically neglected).
- Require minimum recorded history before emitting review rules that depend on day counts.

Recommended minimums (plan-level defaults):
- Only compute “daysSinceLastAllocatedForProject” if there exists at least one snapshot in the last N days.
- Only emit Phase 4 review rules if snapshot coverage in the last N days meets a threshold (e.g., >= 50%).

If you choose a different policy (e.g., count missing days as neglected), lock that decision and apply consistently across Phase 4 + Phase 5.

## Implementation sequencing guidance
- Implement the “effective values” helper early.
- Enforce project primary value in edit UX before shipping project-health rules.
- Use snapshot-captured project_id for history-based metrics to avoid project-move ambiguity.
