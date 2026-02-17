# Routines Spec

## Scope

Defines routine cadence, scheduled/flexible behavior, logging, skip/snooze/pause semantics, and routine detail support behavior.

## Core rules

- Cadence: day, week, month.
- Schedule mode: flexible or scheduled (daily remains flexible).
- Plan surfaces can select routines; completion/logging remains explicit action.
- Deselecting scheduled routine follows explicit action flow (instance skip, period skip, pause).

## Interaction semantics

- `Skip this instance`: excludes only the current scheduled occurrence.
- `Skip this week/month`: excludes remaining scheduled occurrences in active window.
- `Pause routine`: disables routine until user resumes.
- `Snooze`: defer to a specific later time/day without pausing the routine.

## Testing minimums

- Window key derivation (week Monday anchor, month first day).
- Flexible vs scheduled eligibility and ordering.
- Skip/snooze/pause effects on selection and logging.
