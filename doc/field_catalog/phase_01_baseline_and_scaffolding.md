# Phase 01 — Baseline + scaffolding

## Goal
Get the codebase into a stable state where `flutter analyze` is clean, and scaffold the new field-catalog architecture without changing UI behavior yet.

## Constraints
- Keep UX unchanged in this phase.
- No tests should be run in this phase.
- End-of-phase requirement: `flutter analyze` has **0 errors/warnings**.

## Steps
1. Run `flutter analyze` and record current errors.
2. Fix analyzer errors/warnings.
   - If errors are unrelated to the field catalog work (e.g., data-layer compile issues), still fix them because phase gates require a clean analyzer.
3. Create new directories/files (empty or minimal) for the upcoming phases:
   - `lib/presentation/field_catalog/` (new field widget + formatting layer)
   - `lib/presentation/entity_views/` (new TaskView/ProjectView/ValueView entrypoints)
   - Keep these unused for now to avoid behavior changes.

## Exit criteria
- `flutter analyze` passes with 0 issues.
- Scaffolding exists but is not yet wired into production UI.
