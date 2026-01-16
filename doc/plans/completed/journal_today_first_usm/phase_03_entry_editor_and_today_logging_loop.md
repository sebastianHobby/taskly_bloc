# Phase 03 — Full-screen entry editor + Today logging loop

Created at: 2026-01-15T12:30:44.4044895Z
Last updated at: 2026-01-15T23:28:39.6432613Z

## Goal

Implement the core habit loop for UX-001C with the locked decisions:
- Today-first surface
- Full-screen add/edit route
- Mood required (UX-025A)
- Mood stored as the system mood tracker (UX-019C)

## Scope

- Full-screen editor route (add + edit).
- Mood-first input, then trackers, then note.
- Clear separation of “Today” (day-scoped) vs “This entry” (entry-scoped) when both appear.

## Implementation tasks

1) Entry editor route
- Implement a full-screen page/route for add/edit that reuses the same screen/widget.
- Ensure tapping an entry opens the editor directly (no read-only preview).

2) Required mood
- Enforce mood required before save.
- Use the system mood tracker id as the persisted mood representation.

3) Trackers input UX
- Support quick add behavior for boolean yes/no trackers.
- Ensure the design is extensible to non-boolean tracker types (rating/quantity/choice) without redesign.

4) Post-save behavior
- Implement UX-020A precisely once Phase 01 has normalized it.

5) Data flow (architecture)
- Editor UI must dispatch to a presentation BLoC/Cubit.
- Persistence must go through repository contracts.

## Acceptance criteria

- User can add a log with mood + trackers + note.
- Mood is required to save.
- Saved entry appears in Today entries list.
- Entry tap opens editor with prefilled content.

## AI instructions

- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.
- When the phase is complete, update:
  - `Last updated at:` (UTC)
  - `Completed at:` (UTC)
  - A short summary of what changed

## Completion

Completed at: 2026-01-15T23:28:39.6432613Z
Summary:
- Added a route-backed full-screen Journal entry editor (create + edit) with mood-required enforcement.
- Wired Today composer and entry taps (Today + History) to open the editor route via `Routing`.
- Added `JournalEntryEditorCubit` for presentation-layer save orchestration.
