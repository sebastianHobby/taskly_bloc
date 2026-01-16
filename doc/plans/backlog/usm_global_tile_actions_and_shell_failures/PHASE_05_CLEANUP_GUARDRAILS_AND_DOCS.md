# Plan Phase 05 — Cleanup, Guardrails, Documentation

Created at: 2026-01-16T00:00:00Z
Last updated at: 2026-01-16T04:36:01.7618276Z

## Goal
Finish the migration by removing dead code paths, preventing regressions, and updating architecture docs.

## Scope
- Remove unused imports/legacy helpers that existed only to support tile-internal DI mutation.
- Remove any per-page `ScreenActionsBloc` providers that remain and are no longer needed.
- Remove/avoid page-level SnackBar listeners for `ScreenActionsBloc` failures.

## Guardrails (recommended)
Guardrails (locked):
- Documentation invariant update (required): update USM architecture doc to make the tile action/mutation policy explicit and non-optional.
- Lightweight grep-based check (required): add a CI/tool check to prevent regressions.

Grep guardrail: recommended scoped patterns
- Paths to guard:
	- `lib/presentation/entity_views/**`
	- `lib/presentation/screens/tiles/**`
- Patterns to forbid (initial set):
	- `getIt<EntityActionService>`
	- `ScaffoldMessenger.of(` and `showSnackBar(` inside entity views
	- `showDeleteSnackBar(` inside entity views/tiles (success SnackBars must not live in tiles)

Notes:
- Keep the check narrowly scoped to avoid false positives.
- Allow usages in shared helpers (e.g. global failure listener) and in tests.

## Documentation updates (required if behavior changes)
Update architecture docs to reflect:
- Tiles/widgets are dumb and emit intents.
- Mutations are handled by `ScreenActionsBloc`.
- Action failures are surfaced by the app shell (single listener) and screens must not show SnackBars for these failures.

Also document:
- Capabilities are domain-sourced, entity-based by default, and may be overridden at the module level (domain interpreter) when needed.
- Entity typing uses enums (avoid stringly-typed entity kinds in new code).

## Locked decisions to enforce via guardrails/docs
- (1A) Entity typing uses the existing `EntityType` enum across tile actions.
	- No new stringly-typed entity kind surfaces in new code.
- (2B) Resolved `EntityTileCapabilities` live on item models (not sidecar maps keyed by IDs).
- (3A) Completion display uses occurrence completion when present:
	- `entity.occurrence?.isCompleted ?? entity.completed`

## Additional locked decisions to enforce (batch 2)
- Global `ScreenActionsBloc` provisioning + single app-shell failure listener (no per-page SnackBars).
- `ScreenActionsFailureState` payload shape includes `failureKind` + `fallbackMessage` + optional `error` (+ optional entity context for dedupe).
- Delete confirmation owned by dispatcher (dialog is not owned by tiles, and not emitted as a bloc-driven UI state machine).

## Additional locked decisions to enforce (batch 3)
- `TileIntentDispatcher` is provided at authenticated app shell (single instance).
- Dispatcher code lives near the tile builder (`lib/presentation/screens/tiles/`).
- Navigation intents use hybrid approach (`Routing` default; `EditorLauncher` for editor-only flags).

Suggested target doc:
- `doc/architecture/UNIFIED_SCREEN_MODEL_ARCHITECTURE.md`

## AI instructions (required)
- Run `flutter analyze` for the phase.
- In this last phase: fix **any** `flutter analyze` error or warning (regardless of whether it is related to the plan).
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).

## Completion checklist
- [ ] No remaining widget-layer DI mutation calls in entity view widgets
- [ ] No remaining duplicated failure SnackBar listeners
- [ ] Guardrail added (if approved)
- [ ] Docs updated
- [ ] Analyzer clean
