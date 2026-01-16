# Plan Phase 03 — Make Entity Views Dumb + Plumb Action Surface Through Tile Builder

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T04:36:01.7618276Z

## Goal
Refactor entity tiles (`TaskView`, `ProjectView`, and any similar tile widgets) so they:
- do not pull services from DI (`getIt`)
- do not perform mutations
- do not surface mutation errors directly (no SnackBars/toasts)

Instead, they emit intents via the Tile Action Surface.

## Scope
- `TaskView`:
  - remove `EntityActionService` usage from overflow menus
  - remove any direct delete/pin/complete logic
  - emit intents (`TileIntent.*`) via dispatcher (dispatcher accepts `BuildContext`)
  - completion checkbox is part of the intent surface (no special renderer callback)
- `ProjectView`:
  - same treatment
- `ValueView`:
  - if it has any mutations or DI, apply the same rules
- `ScreenItemTileBuilder`:
  - accept an action surface parameter (resolved capabilities + dispatcher)
  - pass it through to entity views
- Update all call sites that instantiate `TaskView`/`ProjectView` directly.
  - include non-USM feature widgets that currently instantiate entity views directly.

## Non-goals
- No UI redesign; keep visuals identical unless strictly required.
- No new UX beyond shared delete confirm (owned above the tile).

## Locked decisions to preserve
- Task tile open/tap uses `Routing` (route-based) for task edit.
- Align values action is a navigation intent that opens the editor with
  `openToValues: true`.
- Move-to-project supports both quick move and editor deep-link and is
  capability-gated per section/module.

Move-to-project intent modeling (14B, locked):
- tiles only emit navigation intent to open the picker/UX
- dispatcher performs the mutation intent after destination selection

Project pinning policy (15A, locked):
- project pin action remains hidden by default via capabilities (unless enabled by module override)

Additional locks captured after review
- (1A) Entity typing uses `EntityType` enum across tile actions (no string entityType).
- (2B) Capabilities are carried on item models (e.g. `ScreenItem.*`, `AgendaItem`).
- (3A) Checkbox state uses `entity.occurrence?.isCompleted ?? entity.completed`.

Dispatcher locks captured after review (batch 3)
- (1A) Dispatcher is provided at authenticated app shell (single instance).
- (2A) Dispatcher implementation lives alongside the tile builder (`presentation/screens/tiles`).
- (3C) Hybrid navigation: `Routing` by default; `EditorLauncher` when editor flags are needed.

## Error surfacing policy
- Tiles do not show SnackBars.
- Mutations emit failure states via `ScreenActionsBloc`; SnackBars are shown globally at app shell (later phase).

## Backwards compatibility policy
- No legacy fallback behaviors inside tiles.
- All call sites must be migrated (delete legacy paths).

Lock (Q006C): remove the `onTaskToggle` callback path entirely (no transitional adapter).

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).

## Completion checklist
- [ ] No `getIt<EntityActionService>()` calls remain inside entity view widgets
- [ ] Entity views only emit intents via dispatcher/action surface
- [ ] No `ScaffoldMessenger.showSnackBar` calls remain inside entity tiles for mutations
- [ ] All callers compile after signature changes
