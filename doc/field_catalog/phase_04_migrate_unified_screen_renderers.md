# Phase 04 — Migrate unified screens to entity views

## Goal
Replace usage of legacy tiles/cards in unified screen rendering with the new entity entrypoints.

## Steps
1. Update `ScreenItemTileRegistry` to use `TaskView`/`ProjectView`/`ValueView`.
2. Update renderers that instantiate tiles directly (e.g. allocation/My Day) to use `TaskView`.
3. Ensure My Day tasks/projects look identical to normal tiles (same entity-level variant).
4. Run `flutter analyze` and fix any issues.

## Exit criteria
- Unified screen rendering uses entity views.
- `flutter analyze` passes with 0 issues.
