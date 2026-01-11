# Phase 04 — Engine runtime + triggers/scheduling wiring

## Outcome

- The new `AttentionEngine` exists and can produce attention items via a single query API.
- Trigger model is unified:
  - DB change reactivity comes “for free” from Drift/PowerSync.
  - Temporal triggers (app resume / home day boundary) produce invalidation pulses.
- Runtime state is used for:
  - dismiss-until-hash-changes
  - snooze-until-time
  - next evaluation time (future: background scheduling)

## Scope

- Implement `AttentionEngineContract.watch(AttentionQuery)`.
- Integrate a trigger source (temporal invalidations) in the engine (not in each section interpreter).
- Ensure the engine is the only place that decides when to recompute.

## Constraints

- Do not update or run tests.
- Keep compilation and run `flutter analyze` at the end.

## Steps

1) Implement engine execution model

- Inputs:
  - `AttentionQuery`
  - streams of:
    - active rules
    - relevant domain data (tasks/projects/allocations/…)
    - temporal invalidation pulses

- Output:
  - `Stream<List<AttentionItem>>` that updates when:
    - data changes, or
    - a temporal invalidation pulse occurs.

2) Consolidate temporal invalidation

- Decide whether `AttentionTemporalInvalidationService` remains as-is or is replaced.
- Requirement for this phase:
  - there is one place the engine listens for invalidation.
  - section interpreters do not implement invalidation logic.

3) Implement runtime-state semantics

- Dismiss-until-hash-changes:
  - Store dismissed hash per (rule, entity).
  - When recomputed hash differs, resurface.

- Snooze:
  - Store `next_evaluate_after` (or similar) in runtime state.
  - Engine excludes items whose snooze hasn’t elapsed.

4) Wire DI

- Register the new engine in GetIt.
- Do not switch section interpreters yet (that is Phase 05) to avoid partial dual-path.

5) Compile + analyze checkpoint

- Run: `flutter analyze`

## Delete list (big-bang rule)

- No legacy deletion yet unless the engine directly replaces a legacy trigger service.
- If the engine replaces `AttentionTemporalInvalidationService`, delete the old service in this phase and update all call sites immediately.

## Exit criteria

- Engine compiles and is injectable.
- Trigger integration compiles.
- `flutter analyze` passes.
