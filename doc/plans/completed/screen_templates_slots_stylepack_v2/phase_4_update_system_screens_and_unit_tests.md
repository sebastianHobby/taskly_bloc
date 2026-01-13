# Phase 4 — System Screens + Unit Tests (Assumes Clean DB)

Created at: 2026-01-13T00:00:00Z  
Last updated at: 2026-01-13T00:30:00Z

## AI instructions
- Before implementing this phase, review `doc/architecture/`.
- Run `flutter analyze` during this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes architecture (module boundaries, responsibilities, data flow), update the relevant files under `doc/architecture/`.

## Objective
Apply typed specs + pack-only styling to all system screens and add unit tests
that lock in the new behavior.

Hard cutover assumption:
- the database has already been reset/wiped by the user prior to starting this
  plan (no migration/backcompat work required).

## Implementation outline
1) **Update system screen definitions**
   - Update `SystemScreenDefinitions` to specify `pack` for:
     - Scheduled (`agenda_v2`)
     - Someday (`hierarchy_value_project_task_v2`)
     - Any other V2 list templates used by system screens
   - Ensure My Day allocation remains unaffected by pack (unless allocation is also migrated to pack in the same change).

   Simplified approach requirement:
   - system screens should be defined using the typed `ScreenSpec` model (Phase
     1), not via `templateId + params JSON`.

2) **Unit tests (minimum set)**
   - Tests for pack mapping:
     - `StylePackV2.standard` resolves to expected tile styles and spacing.
     - `StylePackV2.compact` resolves to expected tile styles and spacing.
   - Tests for hierarchy affordance:
     - project group rows always include visible expand/collapse UI.
   - Tests for params strictness:
     - decoding without `pack` fails for pack-only templates.

   Add cutover safety tests:
   - “system screen renders with empty screen tables” (clean DB / no legacy
     rows)

3) **Analysis**
   - Run `flutter analyze` and fix any issues.

## Acceptance criteria
- System screens compile and render with pack-only params.
- Unit tests pass.
- `flutter analyze` clean.

## Notes
- If the repo contains multiple screen repositories / definitions stacks, the
  non-canonical one should already be unused by the end of this phase (deleted
  in Phase 5).

## Notes
- Prefer unit tests that operate at the params/renderer contract level (no goldens required).
