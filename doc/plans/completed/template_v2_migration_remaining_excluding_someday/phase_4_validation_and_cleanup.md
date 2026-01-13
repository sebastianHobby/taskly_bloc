# Template V2 Migration (Remaining Templates) — Phase 4: Validation + Cleanup

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Finish the migration safely: validate behavior, remove dead wiring, and (optionally) remove compatibility aliases.

## In scope
- Verify all system screens still render correctly.
- Ensure template params decoding remains strict and failures are discoverable.
- Decision (validation): run recorded tests via `flutter_test_record` once at the end.
- Decision (cleanup): aggressive cleanup after migration (remove dead wiring and legacy-ish code paths), without introducing new template IDs.

## Checklist
- Update `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md` if any catalog entries change.
- Run recorded tests (`flutter_test_record`).
- Verify no orphaned template IDs exist in system screen definitions.
- Remove unused helpers, imports, and any now-dead branches related to migrated templates.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
