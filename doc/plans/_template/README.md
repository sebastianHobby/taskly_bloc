# Plan Templates

Use this folder as a starting point for new plans.

## How to use

1. Create a new folder under `doc/plans/<meaningful-plan-name>/`.
2. Copy `PHASE_01.md` into that folder and rename it per phase (e.g. `phase_01_foundation.md`).
3. For multi-phase work, add additional phase files (one file per phase).

## Required in every phase file

- `Created at:` (UTC)
- `Last updated at:` (UTC)
- An **AI instructions** section that includes:
  - Run `flutter analyze`.
  - Fix all errors/warnings before tests.
  - Review `doc/architecture/` first; keep architecture docs updated if architecture changes.
