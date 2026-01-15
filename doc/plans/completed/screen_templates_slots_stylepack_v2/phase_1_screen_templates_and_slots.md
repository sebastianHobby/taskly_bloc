# Phase 1 — Screen Templates + Slots (Additive)

Created at: 2026-01-13T00:00:00Z  
Last updated at: 2026-01-14T00:00:00Z

## AI instructions
- Before implementing this phase, review `doc/architecture/`.
- Run `flutter analyze` during this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes architecture (module boundaries, responsibilities, data flow), update the relevant files under `doc/architecture/`.

## Objective
Introduce a first-class **screen template** layer and a minimal **slot model**
in a way that supports the simplified approach:

- system screens are defined using **typed specs** (not string template IDs)
- the runtime can render those specs without going through
  `templateId -> params codec -> interpreter registry` for system screens

This phase establishes the core types and the rendering entry points.

## Design constraints
- Slots start minimal: `header` + `primary` only.
- Section data fetching remains module-level.
- No remote experiments and no custom screens.
- Prefer compile-time safety: avoid string IDs/JSON params in the system-screen
  path.

## Implementation outline
1) **Define typed screen specs + slots**
   - Introduce a sealed `ScreenTemplateSpec` (or similarly named) with at least:
     - `standardScaffoldV1`
   - Introduce a sealed `ScreenModuleSpec` (module = what used to be a section
     template + params) with variants for the current system needs:
     - list-like modules (task/project/value list)
     - agenda
     - hierarchy value→project→task
     - allocation
     - support blocks (issues summary, check-in summary, allocation alerts)
   - Add `SlotId` enum with values: `header`, `primary`.
   - Define a `SlottedModules` container to group modules by slot.

   Notes:
   - Specs should be pure config objects; no services injected.
   - Avoid JSON serialization requirements for system screens.

2) **Screen template identifiers and rendering registry**
   - Add a presentation-side switchboard analogous to `SectionWidget`:
     - `ScreenTemplateWidget` routes `ScreenTemplateSpec` to a shell widget.
   - `standardScaffoldV1` should:
     - render `header` modules above/pinned
     - render `primary` modules in the main scroll

3) **Unified screen rendering flow changes**
   - Introduce a rendering entry point that renders **from typed specs**:
     - either a new `UnifiedScreenPageFromSpec`, or
     - extend an existing unified-screen entry point to accept `ScreenSpec`.

  Note (2026-01-14): the older unified-screen entry point has been deleted.
  The supported path is `UnifiedScreenPageFromSpec`.
   - Rendering path:
     - `ScreenSpec` -> partition into slots -> `ScreenTemplateWidget`

4) **Slot semantics (minimal contract)**
   - `header`: rendered above the scrollable content (or as the first pinned sliver), designed for banners/summaries.
   - `primary`: main scrollable content.

## Acceptance criteria
- System screens can be defined as typed specs and rendered.
- `flutter analyze` clean.
- A single screen can be opted into `standardScaffoldV1` without behavior
  differences.

## Notes
- Keep `SlotId` small to avoid premature taxonomy.
- Do not add screen-level data orchestration; only layout/orchestration in presentation.
- If there are multiple parallel screen systems in the repo, do not “bridge”
  them long-term; the goal is to pick one and delete the other in later phases.
