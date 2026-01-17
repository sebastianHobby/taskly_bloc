# Phase 02 — Migrate All Specs to `entity_list_v3`

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T00:00:00Z

## Purpose
Move all catalog specs and entity detail specs from legacy list modules to the new unified flat list module.

## Work
1) Migrate system screens:
   - Replace any `valueListV2(...)` usages with `entityListV3(...)`.
   - Replace any `taskListV2(...)` usages with `entityListV3(...)` where appropriate.

2) Migrate entity detail specs:
   - Project detail RD: `taskListV2` → `entityListV3` (still `DataConfig.task`).
   - Any other entity detail spec that uses legacy list modules.

3) Ensure template/section style parity:
   - Verify styling and tile variant defaults remain consistent after the new ID is used.

4) Grep gate:
   - After migration, confirm `lib/domain/screens/catalog/**` contains no legacy module usages.

## Deliverables
- All user-facing screen specs use the new module for flat lists.

## Acceptance Criteria
- No usages remain in `lib/domain/screens/catalog/**`:
  - `taskListV2`, `valueListV2`
  - `task_list_v2`, `value_list_v2`
- `flutter analyze` is clean.

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for the phase.
- Fix any analyzer errors/warnings caused by this phase’s changes.
- When complete, update this file with summary + `Completed at:` (UTC).
