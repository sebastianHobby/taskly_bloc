# Plan Phase 04 — Global Mutation Wiring (Tiles → ScreenActionsBloc) + Shell Failure Listener

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T04:36:01.7618276Z

## Goal
1) Ensure all tile-originated mutations flow through `ScreenActionsBloc`.
2) Ensure all `ScreenActionsBloc` failures are surfaced by exactly one app-shell listener (SnackBars), not by pages.

## Part A: Tile intents → ScreenActionsBloc
### Scope
- Provide a canonical dispatcher implementation for USM templates/pages that maps:
  - `TileIntent.setCompletion(...)` → `ScreenActionsTaskCompletionChanged` / `ScreenActionsProjectCompletionChanged`
  - `TileIntent.setPinned(...)` → `ScreenActionsTaskPinnedChanged` / (project pinned event if needed)
  - `TileIntent.requestDelete(...)` → show confirm dialog → `ScreenActionsDeleteEntity`

### Occurrence-aware completion wiring (required)
- Extend the relevant event(s) in `ScreenActionsBloc` so completion can carry:
  - `occurrenceDate`
  - `originalOccurrenceDate`
- Extend `EntityActionService.completeTask/completeProject` (and uncomplete) in `lib/domain/screens/runtime/entity_action_service.dart` to accept and pass:
  - `occurrenceDate`
  - `originalOccurrenceDate`
  through to the repositories.

Lock (Q4A): always pass `originalOccurrenceDate` end-to-end for occurrence completion.

Occurrence policy (locked): if the dispatcher receives an occurrence-scoped intent but the entity does not have `OccurrenceData`, treat as error (assert in debug; surface friendly failure via bloc in release).

Mapping rule for expanded occurrences:
- If `entity.occurrence != null`:
  - `occurrenceDate = entity.occurrence!.date`
  - `originalOccurrenceDate = entity.occurrence!.originalDate ?? entity.occurrence!.date`
- Else:
  - `occurrenceDate = null` and no original date

Completion display policy (3A, locked):
- When rendering the checkbox state, treat occurrence completion as authoritative:
  - `entity.occurrence?.isCompleted ?? entity.completed`

### Notes
- Navigation intents stay out of `ScreenActionsBloc` and are handled by page/template routing.
- Dispatcher API (locked): dispatcher methods accept `BuildContext`; intents themselves do not carry context.
- Entity type (locked): migrate away from string entity types; use an enum for `ScreenActionsDeleteEntity` and dispatcher mapping.

Lock (Q006C): do not keep a legacy `onTaskToggle` callback pipeline. Completion originates from the tile as an intent, routed via the explicit tile action surface.

Dispatcher provisioning/location/navigation (batch 3 locks)
- Provide a single dispatcher at `_AuthenticatedApp`.
- Keep dispatcher code near `ScreenItemTileBuilder` (`lib/presentation/screens/tiles/`).
- Navigation intent handling is hybrid:
  - use `Routing` for standard navigation,
  - use `EditorLauncher` when an editor-only flag is required (e.g. open-to-values).

Entity typing lock (1A):
- Standardize on existing `EntityType` enum for:
  - `ScreenActionsDeleteEntity`
  - agenda items
  - dedupe keys `(failureKind, entityType, entityId)`

## Locked decisions to implement in this phase
- Global `ScreenActionsBloc` provisioning: single provider at authenticated app
  shell (`_AuthenticatedApp`), not per-page.
- Failure state shape: include a typed `failureKind` plus a
  `fallbackMessage` and `error` to support localization and safe defaults.
- Global SnackBar policy: failures only.
- Dedupe/throttle key: `(failureKind, entityType, entityId)`.
- Occurrence mismatch handling:
  - Debug: assert
  - Release: emit a generic failure SnackBar message
- Move-to-project intent: support both quick move and editor deep-link,
  capability-gated per section/module.
- Project pinning remains default-off (capability exists but hidden by default);
  TODO to enable later via capability overrides.

Move-to-project intent modeling (14B, locked):
- dispatcher handles the navigation intent to open the picker/UX
- once the user selects a destination, dispatcher emits a mutation intent which maps to a `ScreenActionsBloc` event

## Part B: Global provider + single failure listener (authenticated app)
### Scope
- Provide `ScreenActionsBloc` once for the authenticated app shell.
- Attach exactly one listener that shows a localized friendly SnackBar for failure states.

Lock (1A):
- Use a single `BlocProvider<ScreenActionsBloc>` at `_AuthenticatedApp`.
- Remove page-level `BlocProvider<ScreenActionsBloc>` and failure SnackBar listeners.

### Hardening requirements
- Use `GlobalKey<ScaffoldMessengerState>` via `MaterialApp.router(scaffoldMessengerKey: ...)`.
- Deduplicate/throttle SnackBars:
  - key: `(failureKind, entityType, entityId)`
  - window: 2000ms
  - behavior: replace (hide current then show)
- Ensure navigation safety:
  - do not rely on soon-to-dispose page contexts
  - schedule post-frame when needed

Canonical host (repo reality): `_AuthenticatedApp` in `presentation/features/app/view/app.dart`.

### Migration
- Remove page-level `BlocProvider<ScreenActionsBloc>` where safe.
- Remove page-level SnackBar listeners for `ScreenActionsBloc` failures.
- Keep local listeners only if they do non-SnackBar, page-specific behavior.

### Delete confirmation (locked)
Use the existing shared dialog helper (`showDeleteConfirmationDialog`) from `lib/presentation/widgets/delete_confirmation.dart`.
Do not introduce a new confirm dialog widget.

Lock (3A):
- Delete confirmation is owned by the dispatcher:
  - `TileIntent.requestDelete(...)` -> dispatcher shows confirm dialog -> dispatcher emits `ScreenActionsDeleteEntity(...)`.
  - Use existing `Completer<void>` event pattern when a flow must await completion.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).

## Completion checklist
- [ ] USM renderers consistently pass tile action surface (capabilities + dispatcher)
- [ ] Tile-originated mutations flow through `ScreenActionsBloc`
- [ ] Completion supports occurrence + `originalOccurrenceDate` end-to-end
- [ ] Authenticated app provides one `ScreenActionsBloc` and one failure listener
- [ ] No duplicated SnackBars for action failures
