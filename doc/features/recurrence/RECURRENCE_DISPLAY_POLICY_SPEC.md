# Recurrence Display Policy Spec

## Scope

Defines how recurring tasks/projects are displayed across app surfaces.

This is a read/display contract only. It does not change recurrence write
targeting rules.

## Core rules

- Occurrence-aware display policy is domain-owned and shared across surfaces.
- Occurrence dates are normalized so virtual occurrence start/deadline are
  exposed through entity `startDate` / `deadlineDate` fields before
  presentation bucketing/sorting.
- `Plan My Day`: always show a single next active occurrence for recurring
  entities, regardless of `repeatFromCompletion`.
- `My Day`: use single-next occurrence preview for recurring entities.
- `Projects` overview/read surfaces: use single-next occurrence preview.
- `Scheduled`: hybrid policy:
  - `repeatFromCompletion = true`: show next active occurrence only.
  - `repeatFromCompletion = false`: show all occurrences in the active
    scheduled window.
- Task reminders with `Before due` resolve recurring due date against the next
  active occurrence only.

## Ownership and boundaries

- Domain services own recurrence read/display semantics.
- Presentation consumes surface-appropriate domain APIs and must not implement
  independent recurrence selection logic.

## References

- `doc/features/my_day_plan_my_day/SPEC.md`
- `doc/features/scheduled/SPEC.md`
- `doc/features/notifications/SPEC.md`
- `doc/architecture/INVARIANTS.md` (recurrence read boundary, section 4.4)
