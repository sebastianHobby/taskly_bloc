# Plan: Unified Attention Banner + Action/Review Cutover (Phase 2 — Engine + Evaluators)

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T14:00:00Z

## Goal
Refactor the attention engine to evaluate rules via explicit `evaluator` keys
and typed `evaluatorParams`, while enforcing the Action/Review bucket semantics.

This phase includes fixing the **project coaching bug** by ensuring coaching
rules are evaluated (they will be `bucket=action`, evaluated via project
predicate evaluator).

## Inputs / prerequisites
- Phase 1 complete (schema + domain model + repo mappings updated).
- UI work may exist, but should not be relied upon for correctness until
  Phase 3.

## Design constraints (confirmed)
- Do not persist computed `AttentionItem`s.
- Do not depend on `AttentionItem.metadata` for UI ordering or filtering.
- Evaluation remains reactive (no background scheduler; temporal invalidations
  are in-app only).

## Engine architecture changes
Replace the monolithic legacy evaluation switch with an evaluator registry.

Important:
- This phase assumes the Supabase migration has shipped and Drift/domain models
  no longer expose legacy rule definition fields.
- Do not add fallback reads from dropped columns (`category`, `rule_type`,
  `trigger_type`, `trigger_config`, `entity_selector`).

1) Define `AttentionRuleEvaluator` interface
- `bool supports(AttentionRule rule)`
- `Future<List<AttentionItem>> evaluate(rule, data, snapshot, now)`
- `String computeStateHash(...)` (for dismiss-until-state-changes)
- Optional: provide a stable `sortKey` output if needed by UI without metadata

2) Implement evaluators
- `TaskPredicateEvaluatorV1`
- `ProjectPredicateEvaluatorV1`
- `ReviewSessionDueEvaluatorV1`
- `AllocationSnapshotTaskEvaluatorV1`

3) Evaluator selection
- `rule.evaluator` selects the evaluator.

## Concrete file targets (Phase 2)
- Engine entrypoint:
  - `lib/domain/attention/engine/attention_engine.dart`
    - Replace legacy branching on `ruleType/triggerType/entitySelector`.
    - Remove the current behavior where review evaluation only emits items when
      `entity_type == review_session`.

- Contracts:
  - `lib/domain/attention/contracts/attention_engine_contract.dart`
  - `lib/domain/attention/contracts/attention_repository_contract.dart`

- Query model:
  - `lib/domain/attention/query/attention_query.dart`
    - Ensure it can express “buckets” (Action/Review) rather than
      domain/category.

## Implementation guidance
- Prefer a registry/map keyed by evaluator string:
  - `Map<String, AttentionRuleEvaluator>`
- Keep evaluator params parsing close to the evaluator (typed params via
  Freezed/JSON if helpful), but do not re-introduce schema coupling.

## Project coaching bug fix (required)
Coaching rules become coherent:
- `bucket=action`
- `evaluator=project_predicate_v1`
- params predicate is one of:
  - `highValueNeglected`
  - `noAllocatedRecently`
  - `noAllocatableTasks`

Implement these predicates in `ProjectPredicateEvaluatorV1` so that:
- Items are emitted (no silent empty evaluation)
- Dismiss-until-state-changes works (state hash includes relevant inputs)
- Snooze works

## Suppression semantics (post-migration)
Because data is migrated, remove any legacy fallback semantics that duplicate
runtime state.

Recommendation:
- Runtime state is authoritative for `dismissedStateHash` and `nextEvaluateAfter`.
- Resolutions remain authoritative for audit trail and review cadence.

## Review cadence semantics
`ReviewSessionDueEvaluatorV1` uses:
- rule params `frequencyDays`
- latest resolution (`reviewed`) for the rule-scoped entity id.

Rule-scoped entity id:
- Keep the existing pattern (entityId = `ruleKey`) for review-session due rules.

## Acceptance criteria
- Engine produces items for all existing system rules.
- Project coaching rules produce action items (no longer silently empty).
- All suppression actions behave consistently across evaluators.
- `flutter analyze` is clean at end of phase.

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
