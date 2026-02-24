# Scheduled Spec

## Scope

Defines timeline/date-lens behavior for scheduled entities, grouping, sorting, recurrence expansion boundaries, and timeline actions.

## Core rules

- Scheduled screen is date-first, not priority-first.
- Recurrence expansion uses domain services and local date semantics.
- Expanded recurring rows are normalized to occurrence start/due dates for
  downstream sorting/grouping parity with non-recurring rows.
- Recurring display policy is hybrid:
  - `repeatFromCompletion = true`: show only the next occurrence per entity in
    the active date window.
  - schedule-anchored recurrence (`repeatFromCompletion = false`): show all
    occurrences in the active date window.
- Grouping and sorting remain deterministic and stable.
- Performance and stream lifecycle follow architecture invariants.

Shared recurrence display contract:

- `doc/features/recurrence/RECURRENCE_DISPLAY_POLICY_SPEC.md`

## Testing minimums

- Correct grouping by local day.
- Stable ordering within group.
- Expansion limits and no duplicated occurrences.
- Hybrid recurrence policy correctness (after-completion next-only vs
  schedule-anchored in-window).
