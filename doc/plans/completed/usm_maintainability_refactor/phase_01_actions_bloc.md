# Phase 01 — USM-001 (Option B): Dedicated Actions BLoC/Cubit

Created at: 2026-01-15T00:00:00Z
Last updated at: 2026-01-15T00:00:00Z

## Outcome
Move all screen/template-driven *mutations* (complete/uncomplete, pin/unpin, delete, etc.) out of widgets/templates and into a dedicated presentation BLoC/Cubit.

This enforces the presentation boundary described in [doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md](../../architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md): widgets do not call domain services directly.

## Scope
- Typed USM path only (`ScreenSpec` → `UnifiedScreenPageFromSpec` → `ScreenTemplateWidget` → `SectionWidget`).
- Replace direct `getIt<EntityActionService>()` calls inside templates/widgets with dispatches to an Actions Cubit.
- Keep **read/watch** pipeline (`ScreenSpecBloc`) intact.

### Explicit non-scope
- Do not change any UI layout/UX.
- Do not change domain action semantics.
- Do not merge read + write into `ScreenSpecBloc` (approved design is a separate actions bloc/cubit).

## AI instructions (required)
- Review architecture docs under `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.

## Design
### New presentation-layer unit
Create a small presentation cubit (preferred over a full Bloc unless you need concurrency policies) that is the *only* place in the typed USM UI path that calls `EntityActionService`.

- File (suggested): `lib/presentation/screens/bloc/screen_actions_cubit.dart`

### Public API (derive from usages)
Do **not** pre-add a large list of action methods.

Instead:
1) Grep the typed USM presentation code for mutation callbacks (starting at `ScreenTemplateWidget`)
2) Implement only the minimal set of cubit methods required by those call sites
3) Add more methods only when you encounter a call site that needs them

Expected initial set (based on current code patterns; verify with grep):
- `completeTask(taskId)` / `uncompleteTask(taskId)`
- `pinTask(taskId)` / `unpinTask(taskId)`

Optional later (only if found in typed USM call sites):
- `deleteProject(projectId)` / `deleteTask(taskId)`

Optional: `Stream<ScreenActionEffect>` or a `ScreenActionsState` for error feedback/toasts (add only if the UI currently needs it).

Recommended minimal state:
- `sealed class ScreenActionsState { const ScreenActionsState(); }`
- `final class ScreenActionsIdle extends ScreenActionsState { const ScreenActionsIdle(); }`
- `final class ScreenActionsFailure extends ScreenActionsState { const ScreenActionsFailure(this.message); final String message; }`

If the UI currently does not surface errors, you can still keep state for logging and future UI.

### Dependency injection
- Update DI registration in `lib/core/di/dependency_injection.dart` (note: typed USM uses `core/di`, not `core/dependency_injection`).
- Register `ScreenActionsCubit` as a factory (it is UI-scope; it should not be a global singleton).

Example registration pattern (adapt to local conventions):
- Prefer `registerFactory` for UI-scoped cubits.

### Wiring (widget tree)
Provide the cubit at the correct level:

- Preferred: provide alongside `ScreenSpecBloc` in `UnifiedScreenPageFromSpec` using `MultiBlocProvider`.
  - File: `lib/presentation/screens/view/unified_screen_spec_page.dart`

Pseudo-structure:
- `BlocProvider<ScreenSpecBloc>(...)`
- `BlocProvider<ScreenActionsCubit>(...)`
- child: `_UnifiedScreenSpecBody()`

### Replace direct service calls
Replace all direct `getIt<EntityActionService>()` usage in typed template code with cubit calls.

Primary target:
- `lib/presentation/screens/templates/screen_template_widget.dart`
  - In `_ModuleSliver.build`: currently constructs `entityActionService = getIt<EntityActionService>();` and calls `completeTask/uncompleteTask/pinTask/unpinTask`.
  - Replace with `context.read<ScreenActionsCubit>().completeTask(task.id)` etc.

Secondary targets (if any direct domain calls exist):
- `lib/presentation/widgets/section_widget.dart` should stay “dumb”; it already only uses callbacks.
- Any template-specific widget/renderer that directly calls domain services should switch to cubit callbacks.

## Mechanical implementation steps
1) Create `screen_actions_cubit.dart` with:
   - constructor: `ScreenActionsCubit({required EntityActionService entityActionService})`
   - methods calling `entityActionService` and catching/logging errors.
   - choose logging mechanism consistent with repo (`talker`).

  NOTE: Keep the cubit “thin”: no reading streams, no domain queries, no navigation.

2) Add DI registration.

3) Update `UnifiedScreenPageFromSpec` to provide `ScreenActionsCubit`.

4) Update `ScreenTemplateWidget`:
   - `_ModuleSliver` and `_EntityDetailModuleSliver` should no longer call `getIt<EntityActionService>()`.
   - All mutation callbacks should use `context.read<ScreenActionsCubit>()`.

5) Ensure no widgets/pages call domain services directly (grep for `getIt<EntityActionService>` and similar).

## Verification checklist
- `flutter analyze` passes.
- No remaining `getIt<EntityActionService>()` in presentation templates/widgets for typed USM.
- Behavior unchanged: task completion/pin still works (manual smoke test).

## Notes / risks
- If some actions require contextual information (screen key, analytics), add parameters to cubit methods rather than letting widgets call services.
- If a future need arises for “action results” (snackbars), add a lightweight effect stream.
