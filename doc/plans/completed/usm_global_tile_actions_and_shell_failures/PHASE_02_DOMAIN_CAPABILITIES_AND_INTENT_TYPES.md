# Plan Phase 02 — Domain-first Capabilities + Typed Intent Surface

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T05:52:12.9402093Z

## Goal
Introduce a canonical, typed “Tile Action Surface” contract and add a domain-sourced capability model so tiles can be rendered consistently across templates without widget-layer DI or per-screen forks.

## Scope
- Add the tile action surface types (Option C):
  - Ownership (locked):
    - Domain: `EntityTileCapabilities`, `CompletionScope`, and `EntityTileCapabilitiesOverride` (and reuse existing `EntityType`)
    - Presentation: `TileIntent` + `TileIntentDispatcher`
  - Domain models:
    - `EntityTileCapabilities` (allowed actions + completion scope)
    - `EntityTileCapabilitiesOverride` (module-level override)
    - `CompletionScope`
  - Presentation models:
    - `TileIntent` (mutations + navigation; context-free data)
    - `TileIntentDispatcher` (executes intents; accepts `BuildContext`)

Dispatcher placement (batch 3 locks):
- Provide one dispatcher at the authenticated app shell (not per screen/page).
- Keep dispatcher implementation in `lib/presentation/screens/tiles/` near the tile builder.
- Handle navigation intents via a hybrid strategy:
  - prefer `Routing` for standard navigation,
  - use `EditorLauncher` for editor-only flags (e.g. `openToValues`).
- Introduce a domain-level capability source for USM sections.
  - Capabilities should be attached to section VMs (similar to how `entityStyle` is attached today).
  - Avoid mutating `ScreenItem` union types unless absolutely necessary.

## Locked decisions to implement in this phase
- Entity typing: reuse existing `EntityType` enum (no new `EntityKind`).
  - Implementation lock (1A): migrate remaining `String` entity type surfaces
    (e.g. agenda item typing, delete events) to `EntityType`.
- Capabilities computation: per-item in domain (not computed in widgets).
- Overrides (13A): define module-level `EntityTileCapabilitiesOverride` in typed module params (so it can be shipped in system specs and persisted alongside screen specs when applicable).
- Interpreter applies override and emits resolved capabilities on the resolved `SectionVm` (presentation consumes resolved capabilities).
- Completion intent payload: include explicit completion scope and occurrence
  dates (`occurrenceDate`, `originalOccurrenceDate`) when scoped to occurrence.

Completion display policy (3A, locked):
- For occurrence instances, UI completion truth uses occurrence completion:
  - `entity.occurrence?.isCompleted ?? entity.completed`

## Design constraints (must hold)
- Capabilities are the source of truth for what actions are shown/enabled.
- Per-item completion scope is derived from the entity model:
  - `Task.occurrence` / `Project.occurrence` determine whether completion is `entity` vs `occurrence`.
- Avoid `BuildContext` in intents.
- Dispatcher accepts `BuildContext` (for navigation/dialogs) but intent payloads remain context-free.
- Entity typing: use an enum for entity kind/type (no new stringly-typed entity type surfaces).

## Action set (initial)
Keep global action set minimal and stable:
- Mutations:
  - toggle completion (task + project)
  - toggle pinned (task + project)
  - request delete (task + project + value)
- Navigation intents:
  - open editor (task + project + value)
  - open details (project/value only; tasks are editor-only)
  - task-only: open move-to-project picker
  - task/project: open align-values

Move-to-project intent modeling (14B, locked):
- navigation: `openMoveToProjectPicker(...)`
- mutation: `moveTaskToProject(...)` (only after user selection)

## Capability resolution (locked)
Capabilities are entity-based by default, with an optional domain-level override.

Resolution rule (recommended):
1) Compute base capabilities from entity model (`EntityType` + `OccurrenceData` presence)
2) Apply module-level `EntityTileCapabilitiesOverride` (if provided by the interpreter for that section)
3) Output final capabilities on the section VM for renderers to consume

Override intent: allow modules to hide/disable specific actions without renderer forks.

Occurrence policy (locked): if completion scope requires `OccurrenceData` but the entity has none, treat as error.

## Deliverables
- A single canonical location for the capability models in domain (near `EntityStyleV1`).
- A single canonical location for intent/dispatcher models in presentation (near the tile builder).
- A plan for how section VMs will carry:
  - `entityStyle`
  - `entityTileCapabilities` (resolved)
  - optional `entityTileCapabilitiesOverride` (only if needed for debugging/inspection; ideally override is applied before emitting resolved capabilities)
- A plan for how renderers obtain capabilities from the VM and pass them to the tile builder.

## Implementation alignment (locked)
This phase’s types are designed to integrate with the existing USM spec path:
- Tile construction: `lib/presentation/screens/tiles/screen_item_tile_builder.dart`
- Mutations boundary: `lib/presentation/screens/bloc/screen_actions_bloc.dart`
- Domain mutation service currently used by the actions bloc: `lib/domain/screens/runtime/entity_action_service.dart`

## Locked storage location for capabilities (2B, locked)
- Capabilities live on the renderable item models (not a sidecar map keyed by ID).
  - For list-based sections: extend the item carrier (e.g. `ScreenItem.*`) to carry resolved `EntityTileCapabilities`.
  - For agenda: extend `AgendaItem` to carry resolved `EntityTileCapabilities` (and migrate `entityType` to `EntityType` per 1A).

## Decision lock (Q005A, migration strategy)
We will implement capabilities-on-items by extending `ScreenItem.task/project/value` to include a capabilities field.

Migration approach (locked): "optional-first → required later"
1) Add the capabilities field as optional (e.g. nullable) so existing call sites that construct `ScreenItem.task(task)` continue to compile.
2) Update all item producers (domain interpreters/section services) to populate capabilities.
3) Update all renderers/tile builder call sites to require capabilities before surfacing actions.
4) Once all producers are migrated, make the capabilities field required and remove legacy fallbacks.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).

## Completion checklist
- [x] Tile action surface types exist and are used consistently (`TileIntent`, `TileIntentDispatcher`)
- [x] Domain-sourced capability policy exists (`EntityTileCapabilities`, resolver, overrides)
- [x] Capability model supports occurrence-aware completion scope (`CompletionScope` + occurrence dates)

Completed at: 2026-01-16T05:52:12.9402093Z

Summary:
- Verified capability types live in domain and are attached to renderable item models (e.g. `ScreenItem.*`, `AgendaItem`).
- Verified presentation owns intents + dispatcher and routes mutations through `ScreenActionsBloc`.
