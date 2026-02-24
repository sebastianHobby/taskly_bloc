# Notifications Spec

## Scope

Defines local reminder and notification planning behavior, including Plan My Day reminder policies.

## Core rules

- Notification planning logic lives in domain services.
- Notification delivery setup remains infrastructure concern.
- Notification behavior must be safe under offline and delayed sync conditions.

## Current implemented area

- Plan My Day reminder planning service contracts and time calculations.
- Task reminder delivery for task-level reminder metadata:
  - `At date/time`
  - `Before due`

## Task reminder UX contract (current)

- Reminder mode `Before due` is unavailable when a task has no due date.
- If a task has a `Before due` reminder and the due date is cleared, the user
  must explicitly choose one of:
  - convert to `At date/time` (pick absolute date/time), or
  - remove reminder.
- Task reminder delivery resolves recurrence `Before due` reminders against the
  next active occurrence only.
- `At date/time` reminders are fixed absolute timestamps and do not shift with
  recurrence occurrences.

Shared recurrence display contract:

- `doc/features/recurrence/RECURRENCE_DISPLAY_POLICY_SPEC.md`

## Testing minimums

- Reminder scheduling windows.
- Time-zone/local-day boundary behavior.
- Idempotent planning behavior.
- Due-date removal conversion/removal flow for `Before due` reminders.
