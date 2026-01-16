# Phase 04 — Manage Trackers: archive/delete + outcome classification

Created at: 2026-01-15T12:30:44.4044895Z
Last updated at: 2026-01-15T23:28:39.6432613Z

## Goal

Ship a Manage Trackers experience aligned to the locked decisions:
- Archived trackers are only visible in Manage Trackers.
- Deleting a tracker deletes associated data (with explicit warning).
- Tracker type/scope/valueType cannot be changed after creation.
- Outcome vs factor classification uses `TrackerDefinition.isOutcome` (UX-026A) and is managed here, not in Today.

## Scope

- Manage Trackers screen reachable from Journal app bar action.
- Sections for Active vs Archived.
- Controls for:
  - rename
  - pinned / quick-add toggles
  - ordering
  - archive / unarchive
  - delete (destructive)
  - outcome/factor toggle (stored as `isOutcome`)

## Implementation tasks

1) Manage screen UI + state
- Implement the Manage Trackers screen as a standard settings-style surface.
- Ensure archived trackers are hidden from Today and History lists.

2) Outcome/factor toggle
- Add a simple UI control (switch/segmented control) to set `isOutcome`.
- Default:
  - system mood tracker should be `isOutcome=true` (confirm in seeding)
  - newly created user trackers default `isOutcome=false` (already true)

3) Archive/delete semantics
- Implement archive as reversible hide (no data deletion).
- Implement delete with strong confirmation and data deletion.

4) Ordering
- Ensure ordering is user-controlled and stable.

## Acceptance criteria

- Archived trackers are only visible in Manage Trackers.
- Outcome/factor can be edited and persists.
- Delete warns and removes associated tracker data.
- No ability to change tracker type/scope after creation.

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
- Implemented Manage Trackers UI for USM (active/archived sections, pinned/quick-add toggles, outcome toggle, archive/unarchive).
- Added delete-with-purge flow backed by `JournalRepositoryContract.deleteTrackerAndData`.
