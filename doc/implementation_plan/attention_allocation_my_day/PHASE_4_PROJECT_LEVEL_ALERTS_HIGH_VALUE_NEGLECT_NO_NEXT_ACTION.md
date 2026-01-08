# Phase 4 — Project-Level Alerts (High Value/Neglect + No Next Action)

## Goal
Add project-level attention items that support coaching beyond task urgency:

1) **High value + high neglect projects** that are not represented by today’s allocation.
2) **Projects with no actionable item** (time-gated) to avoid repeated noise.

This phase assumes:
- allocation snapshot persistence exists (Phase 1)
- allocation warnings evaluation exists (Phase 2)

Additionally assumes (from agreed direction):
- Projects have required primary value + optional secondary values.
- “Project health” items are presented as REVIEW (coaching) rather than PROBLEM (urgent).

## Design decisions (locked)
- “High value” and “neglect” are algorithm outputs.
- Value and neglect are separate signals; alerts may combine them.
- “No actionable item” is a distinct use case and must be time-gated.

New locked decisions (agreed)
- Project health is implemented as **configurable REVIEW rules** with defaults.
- The initial release supports exactly three rule types:
   1) High-value project neglected
   2) No allocated tasks for project recently
   3) No allocatable tasks for project for >1 day (time gated)
- FocusMode provides default thresholds for these rules.
   - If the user edits any review-rule setting, switch preset state to “Custom/Personalized”.

## Implementation approach
Implement a small “project health rules” layer used by attention evaluation.

### 0) Add settings model for project health reviews
Add a new settings model (or extend existing allocation/focus settings) that can store:
- enabled toggles per rule type
- thresholds per rule type
- top-K limits
- time-gating durations
- preset source (derived from FocusMode vs Custom)

Guideline: settings must be versioned/hashed into `state_hash` so dismissals reset when settings change.

### A) Shared definitions (single source of truth)
Define the inputs to “project health” in a deterministic, testable way:

- **Project value importance**
   - Derived directly from the project’s primary/secondary values.
   - If you need a scalar score: use the priority weights of those values (e.g., primary weight + sum(secondary weights) * factor).

- **Project representation in today’s allocation**
   - Represented if there exists any allocation snapshot entry with matching `project_id`.

- **Project neglect (allocation-based)**
   - Prefer allocation-derived neglect over “user didn’t complete tasks”.
   - Example: days since last allocated task belonging to this project.

Locked interpretation: missing snapshot days
- “Days since last allocated” is only meaningful if you have sufficient snapshot coverage.
- Missing days (app not opened) are treated as **unknown**, not automatically neglected.

Implementation guidance (to keep reviews from becoming noisy/incorrect):
- Define a coverage window `historyWindowDays` (e.g., 14).
- Compute `snapshotCoverageDays` = number of distinct UTC days with a snapshot in that window.
- Only compute/emit rules that depend on day counts if `snapshotCoverageDays >= minCoverageDays`.
   - Example defaults: `minCoverageDays = 7` out of 14.

Guideline: Keep “neglect” definition aligned with your rules. If your rule is “no allocated tasks recently”, your neglect signal should be based on allocation history, not completion.

### B) Rule type 1 — High-value project neglected (REVIEW)
Intent: “This matters to you and it’s been neglected; consider a small next step.”

Rule logic (suggested minimal, deterministic):
1) Candidate projects = active projects.
2) Compute `projectValueImportance` from project values.
3) Compute `daysSinceLastAllocatedForProject` using allocation snapshot history.
4) Filter:
   - projectValueImportance >= threshold
   - daysSinceLastAllocatedForProject >= daysThreshold
5) Emit top-K attention items.

Important:
- This is a REVIEW item, not a warning.
- Do not force allocation changes here; it’s a coaching nudge.

### C) Rule type 2 — No allocated tasks recently (REVIEW)
Intent: “This project has had zero allocation attention; do you still intend to move it forward?”

Rule logic:
1) Candidate projects = active projects.
2) Compute `daysSinceLastAllocatedForProject`.
3) Filter:
    - daysSinceLastAllocatedForProject >= daysThreshold
4) Emit top-K.

Guideline: This rule is intentionally simpler than rule #1 (does not require value weighting). It’s about portfolio hygiene.

### D) Rule type 3 — No allocatable tasks for > 1 day (REVIEW, time gated)
Intent: “This project cannot make progress because there is no next action.”

Definition of allocatable (choose the simplest that matches your current task model):
- An allocatable task is incomplete and not blocked.
- If scheduling exists: exclude tasks scheduled too far in the future.

Semantics note
- This plan intentionally uses “allocatable tasks” as the measurable proxy for “next action”.
- If you later introduce an explicit `isNextAction` flag, update this rule type explicitly and keep v1 behavior stable.

Time gating:
- Only surface the review after the condition persists for `gatingDays`.

Implementation options (choose one):
1) Persist `firstDetectedAtUtc` per `(projectId, ruleType)`.
2) Derive from history tables if they can represent the start time.

Recommendation: a small persistence table is simplest and keeps alerts stable.

Note: This replaces the earlier “no next action” phrasing, but captures the same intent while being measurable.

## Acceptance criteria
- Review rule settings exist with sensible FocusMode defaults.
- Rule type 1 surfaces a review when a high-importance project has been unallocated for the configured threshold.
- Rule type 2 surfaces a review when a project has had no allocated tasks for the configured threshold.
- Rule type 3 surfaces a review when a project has no allocatable tasks and the condition persists past the gate.
- Allocating a task within a project updates rule outcomes immediately when applicable.
- Editing review settings invalidates dismissals via `state_hash` changes.

## Tests
- Unit tests for rule evaluations and top-K.
- Unit tests for allocation-history based thresholds.
- Unit tests for time gating state transitions.
- Unit tests for settings->state_hash invalidation.

## Notes / risks
- Be explicit about UTC day boundaries for gating.
- Avoid per-project per-task scanning in the UI; compute in evaluator/service.

Added risks
- If allocation history is not retained across days, rule types 1 and 2 cannot be computed. Ensure allocation snapshots are persisted daily and queryable by day.
- If project value requirements aren’t enforced, high-value computations can be wrong or inconsistent.
