# Phase 2 — Allocation Warnings via Attention System

## Goal
Make allocation warnings a first-class part of the attention system, using the
persisted allocation snapshot as the source of truth.

Warnings are computed as:
- **Warning candidates** = entities matched by warning rule/scoring query
- **Actual warnings** = candidates \ allocated-set

## Non-goals
- New My Day UI.
- Project-level “high value/neglect” alerts (Phase 4).

Clarification:
- Project-health *review* items are handled in Phase 4 and are intentionally framed as REVIEW (coaching), not PROBLEM (urgent/failing).

## Current code touchpoints
Current implementation already exists (verify in code before changing):
- `AttentionEvaluator.evaluateAllocationAlerts()` routes allocation-warning rules through `_evaluateAllocationRule(...)`.
- `AllocationAlertsSectionInterpreter` already renders items returned from `AttentionEvaluator`.

Remaining drift to remove (still present elsewhere in the codebase):
- Allocation pipelines and screen data may still compute/transport `excludedTasks` and treat it as “warnings”.

## Design decisions (locked)
- Allocation warnings disappear immediately when an entity becomes allocated.
- Dismissals are forgotten when allocation membership changes.
- Dismissal forgetting is implemented by including `allocation_day_utc` + `allocation_version` in `state_hash`.

Clarification (membership-only versioning)
- “Allocation changes” means **allocated membership changes** (snapshot version bump).
- Score-only changes do not reset dismissals.

Additional locked decisions
- Warning predicates that depend on “value alignment” must use **effective task values** (task overrides; otherwise inherit from project).
- Do not add “deadline safety” as a scoring/allocator concept; deadline-related nudges (if any) should be implemented as attention rules.

## Rule shape (allocation warnings)
Treat allocation warnings as rules that can be extended to other entity types later.

Minimal fields needed per rule:
- `entity_type` (task, project)
- `predicate` (e.g., urgent-without-values, project-has-no-next-action, etc.)
- optional `limit/topK` (if rule produces many candidates)

## Implementation steps

### 1) Implement `_evaluateAllocationRule`
In `AttentionEvaluator`:
- Confirm the current implementation uses:
  - allocation snapshot membership for filtering
  - `allocation_day_utc` + `allocation_version` in `state_hash`
- Extend the implementation to support additional predicates (see below).

Guideline: include the *rule configuration* (thresholds, toggles, topK) in the hash so dismissals reset when the user changes the rule.

First-run / post-migration behavior (snapshot missing)
- To avoid incorrect “not allocated” warnings, this plan suppresses allocation warnings until a snapshot exists for today UTC.
- My Day may still fall back to live allocation for display (Phase 6), but allocation warnings remain snapshot-driven.

### 2) Candidate predicates (start minimal)
Replace the current “urgent excluded tasks” behavior with a stable candidate query.

Suggested first predicate parity:
- `urgent_task_warn_only_not_allocated`
  - candidates = urgent tasks that are excluded from allocation due to configuration,
    but defined without persisting excluded lists.

If current allocation does not include “reason why excluded”, derive candidates by:
- scanning all incomplete tasks
- selecting tasks meeting urgency threshold
- selecting tasks that are *not allocated*

This aligns with the new model: warnings are derived from current facts and rules.

Add the following predicates early (they support the agreed values/projects/tasks model):
- `task_missing_effective_values_not_allocated`
  - candidates = incomplete tasks with empty effective values
  - filter out allocated
  - CTA: “Assign values” / “Assign project” (depending on what’s missing)
- `task_in_project_missing_project_values`
  - candidates = tasks in a project where project has no primary value
  - This should become rare once “project values required” is enforced, but it protects against legacy data.

### 3) Update UI section interpreter
Update `AllocationAlertsSectionInterpreter`:
- Stop creating ad-hoc `AttentionItem`s from `excludedTasks`.
- Instead, request evaluated allocation warning items from `AttentionEvaluator`.

Note: if this has already been done (as it appears in current code), keep it and focus on removing remaining excludedTasks-based warning construction in other services.

### 4) Ensure dismissals work as intended
- When allocation snapshot version changes, recomputed `state_hash` changes.
- Old dismissals naturally stop applying.

## Acceptance criteria
- Allocation alerts section renders items produced by attention evaluation.
- Allocating an item removes its warning immediately.
- Recomputing allocation and bumping snapshot version invalidates dismissals.
- No usage of `excludedTasks` for warnings.

Repository-wide acceptance
- No UI path constructs allocation-warning attention items directly from `excludedTasks`.

First-run acceptance criteria
- If today’s snapshot does not exist yet, allocation warnings are not emitted.

Additional acceptance criteria
- Predicates that depend on values use effective values (inherit/override) consistently.
- Warning items clearly distinguish “missing values” vs “not allocated” in their reason text.

## Tests
- Unit tests for `_evaluateAllocationRule`:
  - With allocated set containing entity -> warning filtered out.
  - With version bump -> state hash changes.
- Golden-ish test or widget test for Allocation Alerts section:
  - uses evaluator output, not excluded list.

## Notes / risks
- Candidate computation must not be O(N^2) for large task lists.
- Ensure UTC day calculation matches allocation snapshot logic.

Added risk
- If Phase 1 does not persist `effective_primary_value_id`, ensure the evaluator computes effective values in a shared domain helper/service (single source of truth).
