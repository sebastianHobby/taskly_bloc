# Phase 3 — StylePackV2 (Hard Cutover, Pack-Only)

Created at: 2026-01-13T00:00:00Z  
Last updated at: 2026-01-13T00:30:00Z

## AI instructions
- Before implementing this phase, review `doc/architecture/`.
- Run `flutter analyze` during this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes architecture (module boundaries, responsibilities, data flow), update the relevant files under `doc/architecture/`.

## Objective
Introduce a unified `StylePackV2` system and **remove** per-entity tile policy knobs from V2 section params.

This is a **hard cutover** with no backward compatibility:
- old persisted data is deleted
- custom screens are removed
- only system templates need updating

## Design
1) **`StylePackV2` enum**
   - Values: `standard`, `compact`.
   - Semantics:
     - `standard`: comfortable spacing and default tile sizing.
     - `compact`: denser spacing; still must maintain usability.

2) **Pack-owned tile mapping**
   - Packs map internally to concrete tile styles/variants used by each module.
   - Tile variants become implementation detail, not configuration surface.

3) **Hierarchy interaction contract**
   - Expand/collapse control must be **always visible** for hierarchy project groups.
   - Pack may change density and typography, but not remove required affordances.

## Implementation outline
1) **Update params models to pack-only**
    - Replace `tiles` / `TilePolicyV2` usage in list-like module specs with
       `pack: StylePackV2`.
    - If any JSON/codec path still exists after Phase 1, remove the old fields
       and enforce strictness (missing `pack` fails fast).

2) **Update interpreters/renderers to use `pack`**
   - Interpreters generally should not care about pack (presentation concern) unless pack influences enrichment requests.
   - Renderers/layouts resolve pack → tile styles + spacing.

   Enforcement goal:
   - packs are the *only* styling knob exposed to system screen composition.

3) **Remove superseded knobs**
   - Remove or deprecate `TilePolicyV2` usage from the V2 section params surface.
    - Remove any now-unused variant wiring as appropriate (avoid unrelated
       deletions; focus on what becomes unreachable after cutover).

    Explicit deletion targets (subject to repo inventory during implementation):
    - any public “tile variant” enums that were only used as configuration
       surface (keep internal widget variants if still useful)
    - any params-codec decoding branches that exist only to support removed
       fields

## Acceptance criteria
- V2 templates that previously accepted `tiles` now accept only `pack`.
- Any attempt to decode V2 params without `pack` fails fast (expected; no backcompat).
- Hierarchy always renders visible expand/collapse affordance.
- `flutter analyze` clean.

## Notes
- Keep packs unified across templates; avoid per-template pack enums.
- Resist adding extra packs in this change; keep to `standard`/`compact` only.
