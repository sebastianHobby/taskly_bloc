# My Day + Plan My Day -- Architecture

> Audience: developers
>
> Scope: product purpose + architecture + code map for the **Plan My Day ritual**
> and **My Day execution**. This is descriptive; invariants live in
> [../INVARIANTS.md](../INVARIANTS.md).

## 1) Product purpose (summary)

See full product meaning in:
- [../../product/SCREEN_PURPOSE_CONCEPTS.md](../../product/SCREEN_PURPOSE_CONCEPTS.md)
- [../../product/SPEC_ROUTINES.md](../../product/SPEC_ROUTINES.md)

Short version:

- **My Day** is a curated, stable focus list for today. It is not exhaustive.
- **Plan My Day** is a ritual flow that helps the user select a small set of
  tasks (and routines) for today.
- **Suggested picks** provide calm, values-led recommendations to seed the
  ritual.

## 2) High-level architecture (layers + boundaries)

Layer ownership (canonical rules in [../INVARIANTS.md](../INVARIANTS.md)):

- **Presentation** owns screens/BLoCs and ritual UI state.
- **Domain** owns allocation semantics and read/write orchestration.
- **Data** persists the user's My Day selection and routine completions.

Strict boundaries to remember:

- Widgets must not call repositories/services directly.
- BLoCs own subscriptions and create `OperationContext` for user writes.
- Recurrence targeting and occurrence-aware reads live in Domain.

## 3) Runtime flows

### 3.1 My Day screen (execution)

```text
My Day screen (Presentation)
  -> MyDayRepository.watchDay(todayDayKeyUtc)
    -> if ritual completed: render persisted picks (tasks + routines)
    -> else: show Plan My Day ritual entrypoint
```

Notes:
- Pinned tasks are not part of the allocator; they are surfaced by My Day
  presentation composition.
- Focus (My Day) is an overlay state; items may appear in other screens.

### 3.2 Plan My Day ritual (selection)

```text
Plan My Day wizard (Presentation)
  -> AllocationOrchestrator.getAllocationSnapshot()
    -> SuggestedPicksEngine.allocate(...)
  -> user selects tasks + routines for today
  -> MyDayRepository.setDayPicks(dayKeyUtc, picks, ritualCompletedAtUtc)
```

Routines are **not** suggested by the allocator, but can optionally count
against value quotas (see [../../product/SPEC_ROUTINES.md](../../product/SPEC_ROUTINES.md)).

### 3.3 Suggested picks explainability

Suggested picks return reason codes. When the ritual is confirmed, a subset of
this metadata is persisted in `my_day_picks` so My Day can render "Why
suggested" without re-running allocation.

## 4) Where things live (code map)

### 4.1 Presentation

- My Day screen + widgets: `lib/presentation/` (feature folder varies)
- My Day BLoCs: `lib/presentation/` (feature BLoCs + section BLoCs)
- Plan My Day wizard: `lib/presentation/` (feature flow + BLoC)

### 4.2 Domain

- Allocation orchestrator:
  `packages/taskly_domain/lib/src/allocation/engine/allocation_orchestrator.dart`
- Suggested picks engine:
  `packages/taskly_domain/lib/src/allocation/engine/suggested_picks_engine.dart`
- Allocation config:
  `packages/taskly_domain/lib/src/allocation/model/allocation_config.dart`
- My Day selection model:
  `packages/taskly_domain/lib/src/my_day/model/my_day_pick.dart`
- Repository contract:
  `packages/taskly_domain/lib/src/interfaces/my_day_repository_contract.dart`

### 4.3 Data

- My Day repository impl:
  `packages/taskly_data/lib/src/features/my_day/repositories/my_day_repository_impl.dart`
- Persistence tables (Drift/PowerSync):
  `packages/taskly_data/lib/src/persistence/`
- Routine completions persistence:
  `packages/taskly_data/lib/src/features/routines/` (feature folder varies)

## 5) Suggested picks + routines integration

Key integration facts:

- Suggested picks are **ephemeral**; only the user selection is persisted.
- Routine picks are stored in `my_day_picks` using `routine_id` (see
  [../../product/SPEC_ROUTINES.md](../../product/SPEC_ROUTINES.md)).
- If enabled, routine selections decrement value quotas used by the allocator.
- My Day renders routine picks inline with tasks (distinct visual treatment).

## 6) Guardrails to keep in mind

- BLoC-only boundary: widgets do not call repositories or subscribe to streams.
- OperationContext propagation for all user-initiated writes.
- Time access via injected clock service only.
- Recurrence occurrence selection and occurrence-aware reads are domain-owned.

See: [../INVARIANTS.md](../INVARIANTS.md)

