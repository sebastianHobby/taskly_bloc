# Plan — Screen Templates with Slots + StylePackV2

Created at: 2026-01-13T00:00:00Z  
Last updated at: 2026-01-13T00:35:00Z

## AI instructions
- Before implementing this phase, review `doc/architecture/`.
- Run `flutter analyze` during this phase.
- Ensure any errors or warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes architecture (module boundaries, responsibilities, data flow), update the relevant files under `doc/architecture/`.

## Summary
This plan delivers a simplified, hard-cutover redesign of the unified screen
system.

It is intentionally **not** an incremental/backwards-compatible migration.

Core idea: move from **string template IDs + JSON params + registries** to a
fully **typed screen spec** model, and remove legacy/custom screen code paths.

1) **Screen-level templates with slots**: introduce first-class *screen
templates* (shell/orchestration) that lay out named **slots** (initially
`header` and `primary`) populated by typed modules.

2) **`StylePackV2` hard cutover**: replace the configurable per-entity tile policy (`TilePolicyV2` and related tile-variant knobs in V2 section params) with a unified, curated pack system (`standard` and `compact`) that is selected per module. Packs are resolved internally by layout/renderers.

3) **Legacy deletion + data reset**:
   - Delete legacy screen/template systems that become unused.
   - Delete custom screens and any persisted screen configuration.
   - Enforce a hard cutover by **wiping local persisted user data** that would
     otherwise reference removed models.

Constraints/decisions already agreed:
- Unified pack system across V2 list-like templates.
- Only `standard` and `compact` packs.
- **Hard cutover** (no backward compatibility): old DB/user data will be deleted; custom screens are removed; update system templates only.
- Hierarchy affordance: expand/collapse control is **always visible**.
- No requirement to keep pack consistent across modules.
- Testing: **unit tests** (no goldens required by this plan).

## Goals
- Make the unified screen model more semantically correct: “pages” are modeled as screen templates; “modules” are section templates.
- Keep the system maintainable with small, enforceable configuration surfaces.
- Reduce invalid configuration combinations by construction (packs + layout contracts).
- Reduce runtime/registry/stringly-typed complexity by moving to typed specs.

## Non-goals
- Re-introducing custom screens.
- Backward compatibility with legacy persisted screen definitions.
- Keeping old screen/template registries around “just in case”.

## Key deliverables
- A typed **screen spec** model (no string template IDs) for system screens.
- A screen-template switchboard that renders a screen shell from typed IDs.
- A slot model (`header`/`primary`) and a default screen template.
- `StylePackV2` and pack-only styling across list-like modules.
- Hard cutover assumes **no legacy persisted user config** exists (see
  Preconditions).
- Deletion of superseded legacy screen/template systems.
- Unit tests covering pack mapping, hierarchy affordances, and spec routing.

## Acceptance criteria
- System screens render correctly using the new screen-template shell:
  - My Day gate behavior unchanged.
  - Scheduled and Someday render via the default screen template.
- `flutter analyze` clean.
- Unit tests added and passing.
- No remaining references from system screens to the removed tile-policy knobs.
- No remaining runtime dependency on templateId/params codec/registries for
  system screens.
- Legacy screen/template systems are removed from the codebase.

## Preconditions (done by user before plan starts)
These are assumed true when implementation begins:

1) **Full user data wipe**
  - You will delete all user data before starting this plan (hard cutover).
  - This removes any need for backcompat/migrations.

2) **Custom screens**
  - Custom screens are not supported. Any remaining creation/editing UI or
    persistence is considered legacy and should be deleted during Phase 5.

3) **Canonical stack choice**
  - Keep `lib/domain/screens/...` as canonical.
  - Ensure any other/older screen stacks are either unused or replaced by the
    canonical version *before* deleting them.

4) **DB reset**
  - You will handle DB reset separately before this plan starts.

## Proposed phases
- Phase 1: Typed screen spec + slot model (remove templateId/params JSON for system screens)
- Phase 2: Screen templates (shells) + migration of “full-screen” behavior
- Phase 3: `StylePackV2` pack-only cutover and removal of tile-policy knobs
- Phase 4: Update system screens + add unit tests (assumes clean DB)
- Phase 5: Delete legacy code paths + docs + unit tests

## Future enhancements (tracking)
Phase 5 includes a “Future enhancements” section with a proposed future-state
table for **all current screens**. That table is a starting point for future
analysis and sequencing after the hard cutover.
