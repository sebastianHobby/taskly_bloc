# Proposal: Enable Project-Health Review Rules (entity_type = project)

**Status:** Proposal (backlog)

## Summary

The attention system already ships 3 project-health review rule templates:

- `review_project_high_value_neglected`
- `review_project_no_allocated_recently`
- `review_project_no_allocatable_tasks`

However, these templates currently never produce `AttentionItem`s because the
engine’s review evaluator only supports `entity_type = review_session`.

This document proposes the minimal, coherent changes required to “turn on”
project-health reviews by evaluating `AttentionRuleType.review` rules that target
`entity_type = project`, generating `AttentionItem(entityType: project)`, and
surfacing them in the existing “reviews” UI surfaces.

It also enumerates open questions (especially around the definition of
“allocatable task” and gating persistence) that must be decided before coding.

## Background: review vs review_session

The attention system uses two independent concepts:

- **Rule type:** `AttentionRuleType.review` selects the evaluation pathway.
- **Entity type:** `AttentionEntityType.reviewSession` is a *synthetic* entity
  representing recurring checklist-style reviews (Weekly Review, Monthly Review,
  etc.). There is no underlying domain object.

The current engine logic treats `review_session` rules as “scheduled” by:

- Using `rule.ruleKey` as the effective entity id
- Looking up the latest resolution for `(ruleId, entityId = rule.ruleKey)`
- Computing “due/overdue” using `frequency_days`

Project-health reviews are different:

- They should attach to a real domain entity: `AttentionEntityType.project`
- They should suppress/snooze/dismiss per project
- Their triggers are effectively realtime (reactive to project/task/allocation
  changes) and do not use `frequency_days`

## Current Behavior / Gap

- The engine’s `_evaluateReviewRule()` returns early unless
  `entity_type == review_session`.
- The 3 project-health review templates therefore produce zero items.
- The existing check-in “reviews” surface filters to `entityTypes = {reviewSession}`,
  so even if the engine generated project review items, they would remain hidden
  until the query is updated.

## Goals

1. Evaluate review rules with `entity_type = project`.
2. Generate `AttentionItem`s using the existing project item infrastructure.
3. Apply standard attention suppression semantics (dismiss/snooze) per project.
4. Respect the user’s project-health review settings stored within allocation
   settings.
5. Surface project review items in the existing “reviews” UI surfaces.

## Non-Goals (for this proposal)

- Add new UI pages, new settings screens, or new rule templates.
- Implement background scheduling for “scheduled” rules.
- Add server migrations, PowerSync schema changes, or new persistence tables
  unless required by gating semantics.

## Proposed Design

### 1) Extend review evaluation in AttentionEngine

Change the review evaluator from “review_session only” to a small dispatcher:

- If `entity_type == review_session`: keep current scheduled logic.
- If `entity_type == project`: evaluate predicate-driven rules.
- Otherwise: return empty list.

**Inputs required for project review evaluation**

To evaluate project predicates consistently, the engine will need:

- `projects` and `tasks` (already available in the engine’s combined inputs)
- Allocation settings (`SettingsKey.allocation`) for
  `projectHealthReviewSettings`
- Allocation history metrics for project allocation recency / coverage
  (via `AllocationSnapshotRepositoryContract.getProjectHistoryWindow(...)`)
- “Today UTC day” (available via `HomeDayKeyService`)

### 2) Predicate semantics

Project-health templates are predicate-driven:

- `highValueNeglected`
- `noAllocatedRecently`
- `noAllocatableTasks`

These predicates should be implemented inside the attention domain (engine), but
they should reuse existing metrics helpers when available.

#### 2.1 `highValueNeglected`

Intended meaning: “A high-importance project has not been allocated for N days.”

Suggested approach:

- Compute a project “importance score” from value priorities:
  - Primary value priority has weight
  - Secondary value priorities contribute with a factor
- Compare against `highValueImportanceThreshold`
- Require allocation history coverage to be sufficient
- Use `daysSinceLastAllocatedForProject[projectId]` derived from the allocation
  history window
- Flag when `daysSinceLastAllocated >= highValueNeglectedDaysThreshold`

Return up to `highValueNeglectedTopK` projects, sorted by:

1) descending importance
2) descending days since last allocated

#### 2.2 `noAllocatedRecently`

Intended meaning: “Portfolio hygiene: project hasn’t been allocated in a while.”

Suggested approach:

- Require allocation history coverage to be sufficient
- Compute `daysSinceLastAllocated`
- Flag when `daysSinceLastAllocated >= noAllocatedRecentlyDaysThreshold`

Return up to `noAllocatedRecentlyTopK` projects, sorted by descending days.

#### 2.3 `noAllocatableTasks` (time-gated)

Intended meaning: “Project has no next action, but don’t nag immediately.”

Suggested approach:

- Determine whether a project has any “allocatable” tasks
- If none, start a gate timer on the first day observed
- Only emit after the condition has persisted for
  `noAllocatableGatingDays` UTC days

Return up to `noAllocatableTopK` projects.

### 3) Gating persistence (noAllocatableTasks)

There is an existing persisted gate map:

- `ProjectHealthReviewSettings.noAllocatableFirstDayUtc: Map<projectId, dayIso>`

But the attention engine currently does not write settings.

**Option A (recommended): store gating state in Attention runtime state**

- Use `attention_rule_runtime_state.metadata` keyed by `(ruleId, projectId)` to
  store `first_seen_day_utc`.
- Benefits:
  - Keeps gating owned by attention subsystem
  - No coupling to allocation settings write-path
  - Naturally scoped per rule + entity

**Option B: persist gating state back into allocation settings**

- Update the allocation settings JSON when gate starts/stops.
- Downsides:
  - Requires write access in attention engine (cross-bounded-context coupling)
  - Adds more churn to settings storage

**Decision required** (see Open Questions).

### 4) Suppression semantics

Project review items should use standard per-project suppression:

- Runtime state scoped by `(entityType = project, entityId = project.id)`
- Back-compat resolutions scoped by `(ruleId, entityId = project.id)`

This mirrors how problem rules suppress per task/project today.

### 5) Item creation

Use the existing `_createProjectItem(rule, project)` path.

Optionally enrich `metadata` to support richer UI copy in the future:

- `days_since_last_allocated`
- `importance_score`
- `coverage_sufficient`

This proposal does not require UI changes to consume extra metadata.

### 6) UI surfacing

Existing review surfaces should be updated to include project entity type.

At minimum:

- Update the check-in “reviews” query filter to include
  `entityTypes = {reviewSession, project}` (or remove the entity filter and rely
  on domain/category for scoping).

No new UI screens are required.

## Implementation Plan (incremental)

1. **Engine refactor:** change review evaluation to dispatch by entity type.
2. **Project-health settings read:** load allocation settings and resolve
   `ProjectHealthReviewSettings` (presets + personalized) similarly to how stats
   resolves it.
3. **Allocation history window read:** compute `daysSinceLastAllocated` per
   active project when coverage is sufficient.
4. **Implement predicates:**
   - `noAllocatedRecently`
   - `highValueNeglected`
   - `noAllocatableTasks` (after allocatable definition is decided)
5. **Apply suppression:** per project.
6. **UI query update:** include project entity type in the “reviews” surface.
7. **Tests:** add unit tests for each predicate and for gating persistence.

## Testing Strategy

- Unit tests for predicate selection and ranking (top-K behavior).
- Unit tests for “coverage insufficient” behavior: must not emit recency-based
  items.
- Unit tests for `noAllocatableTasks` gating:
  - Gate starts on first day condition holds
  - Emits only after N UTC days
  - Clears gate when condition is resolved
- One integration-ish test (optional) validating that the check-in query returns
  both `reviewSession` and `project` review items.

## Risks / Edge Cases

- Allocation history coverage may frequently be insufficient early in adoption.
  The engine should be explicit: do not emit recency-based rules without
  sufficient coverage.
- Importance calculation must be stable and explainable (avoid “mystery math”).
- Gating persistence must survive restarts and day-boundary transitions.
- Project/task repositories may not always include populated relationship
  fields (e.g. tasks might not have `project` hydrated).

## Open Questions (must decide)

1. **Definition of “allocatable task”** for `noAllocatableTasks`:
   - (A) “project has zero incomplete tasks”
   - (B) “project has zero tasks eligible for allocation (exclude rules, values,
     urgency, etc.)”

2. **Where to persist gating state** for `noAllocatableTasks`:
   - (A) Store in `attention_rule_runtime_state.metadata` (recommended)
   - (B) Store in allocation settings (`noAllocatableFirstDayUtc`) by writing
     updated settings from the engine

3. **Importance formula** for `highValueNeglected`:
   - Use value priorities directly (low/med/high weights), or incorporate
     project priority / pinned state as well?

4. **Sorting / selection** for each rule:
   - Confirm desired top-K sorting (importance-first vs recency-first).

5. **UI surface expectations**:
   - Should project review items appear in the same check-in section as
     scheduled review sessions, or do we want them in a separate section?
   - If combined, should the UI group by entity type?

6. **Action semantics** for project review items:
   - Is `reviewed` equivalent to “acknowledged / I considered this prompt”? (No
     side effects.)
   - Should `dismissed` be long-lived (state-hash based) or permanent until the
     project changes significantly?

