# Phase 04 — Cleanup + Regression Hardening (Final Phase)

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Purpose
Ensure parity and prevent reintroduction of legacy patterns.

## Work
1) Docs update:
   - Update USM catalog tables in `doc/architecture/` to reflect the new module and removed legacy modules.

2) Test/fixture cleanup:
   - Remove or update any tests and fixtures that referenced legacy IDs or VMs.
   - Add minimal targeted tests if an obvious seam exists:
     - `entity_list_v3` validation for allowed `DataConfig` types
     - Renderer dispatch behavior (task vs value)

3) UX parity pass:
   - Confirm list header/title behavior matches prior screens.
   - Confirm empty-state behavior matches prior screens.

4) Final grep gate:
   - Confirm no legacy identifiers remain anywhere in the repository (excluding build output).

## Deliverables
- Clean architecture and clean codebase: only new module remains for flat lists.

## Acceptance Criteria
- `flutter analyze` is clean.
- Documentation reflects reality.
- No legacy identifiers remain.

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- Since this is the last phase: fix any `flutter analyze` error or warning (even if not directly caused by the phase).
- When complete, update this file with summary + `Completed at:` (UTC).
