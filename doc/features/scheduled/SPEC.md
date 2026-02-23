# Scheduled Spec

## Scope

Defines timeline/date-lens behavior for scheduled entities, grouping, sorting, recurrence expansion boundaries, and timeline actions.

## Core rules

- Scheduled screen is date-first, not priority-first.
- Recurrence expansion uses domain services and local date semantics.
- Expanded recurring rows are normalized to occurrence start/due dates for
  downstream sorting/grouping parity with non-recurring rows.
- Grouping and sorting remain deterministic and stable.
- Performance and stream lifecycle follow architecture invariants.

## Testing minimums

- Correct grouping by local day.
- Stable ordering within group.
- Expansion limits and no duplicated occurrences.
