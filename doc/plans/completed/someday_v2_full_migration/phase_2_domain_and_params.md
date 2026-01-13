# Someday V2 Full Migration — Phase 2: Domain + Params

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Add any missing V2 params/specs needed for Someday + filters, keeping filters ephemeral.

## Work items
- Add `SectionFilterSpecV2` to V2 params surface (likely in `ListSectionParamsV2` and `InterleavedListSectionParamsV2`).
- Update codec(s) to decode/encode the new params.
- Ensure defaults preserve current behavior when the spec is absent.

## Acceptance criteria
- `flutter analyze` clean.
- JSON decode is strict (disallow unrecognized keys).

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
