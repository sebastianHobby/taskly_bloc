# Phase 03 — Entity entrypoints: TaskView / ProjectView / ValueView

## Goal
Add the new entity-level entrypoints that are the *only* place where per-screen customization is allowed. These entrypoints compose consistent field widgets.

## Steps
1. Create:
   - `TaskView`
   - `ProjectView`
   - `ValueView`
   in `lib/presentation/entity_views/`.
2. Initially support the main “list tile” presentation.
3. Implement these entrypoints by composing existing widgets (e.g. `DateChip`, `ValueChip`, `ValuesFooter`, `PriorityFlag`) to avoid diverging visual styles.
4. Keep legacy widgets (`TaskListTile`, `ProjectListTile`, `EnhancedValueCard`) temporarily as thin wrappers that delegate to the new views.
5. Run `flutter analyze` and fix any issues.

## Exit criteria
- New entrypoints exist and are used by wrappers.
- No UI behavior changes beyond refactoring.
- `flutter analyze` passes with 0 issues.
