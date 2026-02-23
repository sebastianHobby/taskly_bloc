# Tasks Spec

## Scope

Defines task lifecycle behavior: creation, scheduling (start/due), completion, recurrence-aware semantics, and task feed interactions.

## Core rules

- Task writes originate from presentation BLoCs through domain contracts.
- Due/start date meaning is consistent across My Day, Scheduled, and Projects surfaces.
- Recurrence occurrence targeting is domain-owned.
- Task completion may include checklist snapshot metrics when checklist is present.
- Repeating tasks require a planned/start date anchor.
- For occurrence-aware reads, recurring task rows are normalized so occurrence
  start/deadline are exposed through task start/due fields.

## Screen contracts

- My Day: execution-focused tasks for today.
- Scheduled: date-lens of due/start and recurring occurrences.
- Projects: backlog and project-scoped task management.

## Data and sync notes

- Offline-first local source of truth.
- PowerSync-backed tables must not use local UPSERT patterns.

## Testing minimums

- Recurrence occurrence targeting correctness.
- Date-boundary behavior (local day keys).
- Completion/log correlation via `OperationContext`.
