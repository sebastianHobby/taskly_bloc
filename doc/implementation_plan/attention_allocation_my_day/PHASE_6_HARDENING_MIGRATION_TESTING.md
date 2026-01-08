# Phase 6 — Hardening, Migration, and Testing

## Goal
Make the new allocation snapshot + attention integration robust:
- stable across app restarts
- safe across schema migrations
- covered by tests

This phase also hardens the agreed “values/projects/tasks” contract:
- projects require primary value
- tasks have effective values (inherit/override)
- project health rules are configurable and have FocusMode defaults

## Implementation steps

### 1) Schema migration strategy
- Add new tables with forward-only migrations.
- Default behavior when no snapshot exists:
  - treat allocated set as empty
  - My Day can fall back to live allocation stream until first snapshot is persisted

Migration requirements from agreed decisions:
- Handle legacy projects without a primary value:
  - Locked plan policy:
    - Enforce primary value on **create/edit** flows.
    - Do not hard-block the whole app at startup.
    - Surface attention warnings/reviews that guide the user to fix legacy projects.
  - Recommendation: do not invent new values; instead require fixing via Project edit.
- If Phase 1 adds `project_id` and `effective_primary_value_id` columns, ensure migration and back-compat reads are safe.

### 2) Backfill (optional)
- Do not backfill historical allocation snapshots unless required.
- Start recording from the day the feature ships.

Note: you may still need a one-time sweep to surface legacy data issues (projects with missing primary value).

### 2b) Missing snapshot days
Snapshots are written when allocation is computed.
If the app is not opened, there can be missing days.

Locked plan policy:
- Treat missing days as unknown.
- Phase 4 + Phase 5 metrics that rely on “days since …” must require minimum snapshot coverage.

### 3) Performance
- Ensure batch queries for tasks by ID.
- Ensure evaluator/scoring operates on bounded sets:
  - top-K for alerts
  - rolling windows for repeat metrics

Additional performance guidance
- Centralize effective value resolution so it does not require extra DB calls per task.
- Prefer using snapshot-captured `project_id` for grouping and project-history metrics.

### 4) Testing matrix
- Unit tests:
  - allocation snapshot write/versioning
  - attention allocation rule evaluation
  - My Day grouping view-model
  - project-level alert filters + time gating
- Widget tests:
  - Allocation Alerts section renders evaluator output
  - My Day grouped list renders correctly

Add tests for agreed decisions:
- Effective values helper:
  - task explicit values override project
  - empty task values inherits project
  - empty everywhere yields empty
- Guard rails allocation (if implemented as part of this plan):
  - diversity penalty reduces repeated project domination
  - hard cap enforced when enabled
- Project health review presets:
  - FocusMode yields correct defaults
  - editing any review setting switches preset to Custom/Personalized
  - state_hash invalidation works when settings change

### 5) Debuggability
- Log snapshot writes with day/version and count.
- Provide minimal “why” strings in attention items for allocation warnings.

Add debug hooks for project health:
- When a project review item is emitted, include the threshold inputs (days since last allocated, computed value importance).

## Acceptance criteria
- No crashes when allocation snapshot tables are empty.
- App restart does not lose My Day state for the day.
- Alerts are stable and not noisy (time gating verified).

Additional acceptance criteria
- Legacy projects without primary value are handled predictably (warnings + edit path) and do not crash allocation or My Day.
- Effective values are consistent across scoring, allocation, attention rules, and UI.

First-run acceptance criteria (snapshot missing)
- My Day may fall back to live allocation for display.
- Allocation warnings are suppressed until the first snapshot exists (Phase 2 default).

## Release checklist
- Verify UTC bucketing correctness.
- Verify dismissals reset on allocation version bump.
- Verify no dependencies on excluded task persistence.
