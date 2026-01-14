# Phase 06 — Hard cutover: remove allocation primary section

Created at: 2026-01-14T00:00:00Z
Last updated at: 2026-01-14T00:00:00Z

## Goal
Remove the legacy allocation primary section implementation after My Day has fully migrated to the shared hierarchy/list primary section.

## Preconditions (must be met)
1. Migration complete
   - My Day primary section uses the shared hierarchy/list section.
   - My Day membership + stable ordering are allocation-driven (snapshot-backed).
2. UX parity confirmed
   - Value → Project → Task grouping matches allocation semantics.
   - Stable ordering matches snapshot expectations.
   - Pinned behavior matches expectations (pinned is global; any pinned-first ordering is preserved where desired).
   - Value-setup gateway behavior is handled by the Focus Wizard gating flow (see Phase 03).
3. No remaining references
   - `ScreenModuleSpec.allocation(...)` is not referenced by any `ScreenSpec`.
   - No remaining references to allocation section template id / interpreter / renderer.
4. Quality gates
   - `flutter analyze` clean.
   - Test run output captured via `flutter_test_report`.

## Work items
1. Identify all legacy allocation section entrypoints
   - Domain params + interpreter
   - Presentation renderer
   - Any tile variants/policies used only for allocation UI
2. Remove the legacy allocation primary section implementation
   - Delete the interpreter/renderer and any unused params/types.
   - Remove `ScreenModuleSpec.allocation` wiring.
3. Sweep for dead code
   - Delete unused helpers or assets only needed by allocation primary section.
4. Verify
   - `flutter analyze` clean.
   - Run tests once using `flutter_test_report`.

## Acceptance criteria
- No allocation primary section code remains.
- My Day still functions with allocation semantics via the shared hierarchy/list section.
- Focus Wizard gating covers both “no focus mode configured” and “no values exist”.
- `flutter analyze` clean and tests recorded.

## AI instructions (required)
- Review `doc/architecture/` before implementing this phase, and keep docs updated for architectural changes.
- Run `flutter analyze` during this phase.
- In this last phase: fix any `flutter analyze` error or warning (even if not caused by the plan’s changes).
- Run tests only once at the end via the `flutter_test_report` task.

