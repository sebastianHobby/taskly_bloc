# Plan Phase 1: Summary strip placement rules (Anytime yes, Scheduled no)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Goal

Implement summary strip placement changes:

- Anytime (`someday`): keep summary strip and render it **below filters** and **above the task list**.
- Scheduled (`scheduled`): remove the summary strip entirely.

## Scope

- Update system screen specs/module placement as needed.
- Update presentation rendering/layout to position the summary correctly on Anytime.
- Ensure the summary remains clearly **global** (not scoped to current filters).

## Non-goals

- Do not implement My Day critical banner in this phase.
- Do not change bell behavior (UX101B assumed already in place).

## Acceptance criteria

- Anytime shows the summary strip only when counts > 0 and collapses when zero.
- Summary strip sits below the filter row and above the list.
- Scheduled never renders the summary strip.
- No new analyzer issues introduced.

## AI instructions

- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes.
- Do not run tests unless explicitly requested.
- When complete, update:
  - `Last updated at:` (UTC)
  - Summary of changes
  - Phase completion timestamp (UTC)

## Phase completion

Completed at: TBD

Summary:
- TBD
