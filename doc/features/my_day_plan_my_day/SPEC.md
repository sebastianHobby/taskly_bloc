# My Day And Plan My Day Spec

## Scope

Defines plan building and execution surfaces, inclusion rules, ordering, over-capacity handling, and deselection/reschedule behavior.

## Core rules

- Plan My Day builds today plan; My Day executes it.
- Auto-included items are explicit and visible.
- Scheduled routines are shown before flexible routines.
- Flexible routines sort by urgency in window and completion recency.
- Deselecting due/planned/scheduled items requires explicit alternate action (reschedule/skip/pause flow).

## Ordering baseline

1. Due/overdue tasks
2. Planned tasks (start <= today)
3. Scheduled routines
4. Flexible routines
5. Suggestions (if under limit)

## Testing minimums

- Auto-include invariants.
- Over-capacity suppression of suggestions.
- Routine ordering and deselection action flows.
