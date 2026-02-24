# My Day And Plan My Day Spec

## Scope

Defines plan building and execution surfaces, inclusion rules, ordering, over-capacity handling, and deselection/reschedule behavior.

## Core rules

- Plan My Day builds today plan; My Day executes it.
- Auto-included items are explicit and visible.
- Scheduled routines are shown before flexible routines.
- Flexible routines sort by urgency in window and completion recency.
- Deselecting due/planned/scheduled items requires explicit alternate action (reschedule/skip/pause flow).
- Recurring tasks are occurrence-aware in planning reads. Occurrence start is
  treated as planned/start date for bucketing.
- Plan My Day recurring display policy is always single-next preview for
  recurring entities, regardless of `repeatFromCompletion`.
- Plan My Day does not render multi-occurrence expansion.

## PMD committed-items UX

- Plan My Day shows a top info card:
  - Title: `Already on today’s list`
  - Body: `We’ve included due, planned, and scheduled items so nothing gets missed. To remove one, reschedule, skip, or pause.`
- Due and planned task rows use explicit action labels (not add/remove picker):
  - Row action: `Reschedule`
  - Bulk shelf action: `Reschedule all`
- Scheduled routine rows use explicit action labels (not add/remove picker):
  - Row action: `Change`
  - Bottom-sheet actions: skip / period skip / pause / keep.
- Flexible routines and suggestion tasks keep picker behavior:
  - Add/remove affordance remains `Add` / `Added`.

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

## PMD behavior telemetry contract

- PMD planning behavior telemetry is append-only and complementary to existing
  plan/outcome tables.
- Canonical behavior facts are recorded in `my_day_decision_events` with
  shelf/action/entity/day semantics.
- `my_day_picks` remains the confirmed plan snapshot source of truth.
- Instrumentation must happen at write boundaries (domain/data), not widget
  layer event handlers.

Detailed implementation spec:

- `doc/features/my_day_plan_my_day/PMD_DECISION_EVENTS_DEBUG_STATS_SPEC.md`
- `doc/features/recurrence/RECURRENCE_DISPLAY_POLICY_SPEC.md`
