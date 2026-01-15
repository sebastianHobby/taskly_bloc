# Architecture Docs Refresh — Completion Summary

Implementation date: 2026-01-13T12:25:24Z (UTC)

## What shipped
- Updated `doc/architecture/README.md` to use current unified screen terminology (`ScreenSpec` / `ScreenSpecData`) instead of legacy screen-model wording.
- Updated `doc/architecture/ALLOCATION_SYSTEM_ARCHITECTURE.md` to reference the current interpreter (`ScreenSpecDataInterpreter`) and correct system screen catalog (`SystemScreenSpecs`).
- Fixed broken links in `doc/architecture/POWERSYNC_SUPABASE_DATA_SYNC_ARCHITECTURE.md` to the local E2E stack guide under `doc/backlog/`.

## Known issues / gaps
- None in the architecture docs after this change.

## Follow-ups
- If the local E2E stack guide is promoted from `doc/backlog/` to a stable non-backlog location, update architecture links accordingly.
