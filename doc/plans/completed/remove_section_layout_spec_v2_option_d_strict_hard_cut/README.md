# Plan — Remove `SectionLayoutSpecV2` (Option D, strict hard cut)

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Goal
Eliminate the remaining “layout union” (`SectionLayoutSpecV2`) from the Unified Screen Model and express structural UI differences via **specialized modules** (Option D). This is a **strict hard cut**: assume **no persisted ScreenSpec JSON** exists and no migration tooling is required.

In practice, this means:
- Stop using `InterleavedListSectionParamsV2(layout: SectionLayoutSpecV2.hierarchyValueProjectTask(...))` for hierarchy-based screens.
- Use `hierarchyValueProjectTaskV2` module directly for hierarchy-based screens (e.g. Anytime/Someday).
- After no runtime usage remains, delete `SectionLayoutSpecV2` and remove any `layout` fields and related branching.

## Non-goals
- No UI/UX redesign; keep visual output and interaction behavior stable.
- No new templates or new screen modules beyond the existing specialized hierarchy module.
- Do not introduce persisted screen spec storage.

## Architectural context
- Presentation boundary: widgets/pages interact only with BLoCs, not repositories or domain streams directly (see `doc/architecture/README.md`).
- USM intent: prefer config/params that express *intent* (template + module choice + typed params), not pixel/layout branching in shared renderers.

## Working assumptions
- There are no persisted ScreenSpec JSON documents in DB (user-confirmed). Runtime screens come from `SystemScreenSpecs` and in-code domain factories.
- “Hierarchy” behavior is currently implemented via a combination of:
  - `hierarchyValueProjectTaskV2` module (specialized)
  - `InterleavedListSectionParamsV2` + `SectionLayoutSpecV2.hierarchyValueProjectTask(...)` (legacy adapter path)

## Safety rails
- Make the migration in this order:
  1) Migrate screens away from `InterleavedListSectionParamsV2(layout: ...)` so nothing depends on `SectionLayoutSpecV2`.
  2) Delete `SectionLayoutSpecV2` and remove layout plumbing.
  3) Refactor interpreter/renderer branching and simplify.
- Keep changes mechanical and reversible. Avoid opportunistic refactors.

## Success criteria (end state)
- No references to `SectionLayoutSpecV2` remain anywhere under `lib/` or `test/`.
- `InterleavedListSectionParamsV2` no longer has a `layout` field.
- Renderers no longer have “layout switch” branches for hierarchy vs flat.
- Anytime/Someday (and any other hierarchy-like screens) use `hierarchyValueProjectTaskV2` module.
- `flutter analyze` is clean.

## Phases
See:
- `phase_01_usage_cutover.md`
- `phase_02_delete_layout_union.md`
- `phase_03_simplify_renderers_and_interpreters.md`
- `phase_04_cleanup_tests_and_regressions.md`
