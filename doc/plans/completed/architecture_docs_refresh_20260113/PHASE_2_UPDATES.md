# Architecture Docs Refresh — Phase 2: Updates

Created at: 2026-01-13T12:19:33Z (UTC)
Last updated at: 2026-01-13T12:25:24Z (UTC)

## Goal
Apply focused edits so `doc/architecture/` accurately reflects the current implementation (terminology, component names, links, and key flows).

## Planned changes
- Fix incorrect/outdated references (for example, legacy class names and moved docs).
- Align terminology with the current unified screen system (typed `ScreenSpec` pipeline).
- Ensure diagrams and “where things live” sections point to real files.

## Done criteria
- All Markdown links under `doc/architecture/` resolve to existing files.
- No architecture doc references removed symbols as if they were current.
- `flutter analyze` is clean (no errors or warnings introduced).

## AI instructions
- Review `doc/architecture/` before implementing edits.
- Run `flutter analyze` for this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- If updates change architecture boundaries, data flow, or patterns, update the relevant architecture docs in the same change.
