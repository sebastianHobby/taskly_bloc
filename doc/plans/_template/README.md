# Plan Templates

Use this folder as a starting point for new plans.

## How to use

1. Create a new folder under `doc/plans/backlog/<meaningful-plan-name>/`.
2. Copy `PHASE_01.md` into that folder and rename it per phase (e.g. `phase_01_foundation.md`).
3. For multi-phase work, add additional phase files (one file per phase).

## Plan lifecycle reminder

- Start in `doc/plans/backlog/`.
- When implementation starts, move the whole plan folder to `doc/plans/wip/`.
  - “Move” means the old path no longer exists (do not copy).
- At the end of each phase, update that phase file with `Last updated at:` (UTC) and a short completion summary.
- When all phases are complete, move the folder to `doc/plans/completed/<plan-name>/` and add a `SUMMARY.md`.

## Required in every phase file

- `Created at:` (UTC)
- `Last updated at:` (UTC)
- A completion section that is filled in when the phase ends:
  - `Completed at:` (UTC)
  - Summary of what shipped/changed in the phase
- An **AI instructions** section that includes:
  - Run `flutter analyze`.
  - Fix errors/warnings caused by the phase by the end of the phase.
  - Review `doc/architecture/` first; keep architecture docs updated if architecture changes.
