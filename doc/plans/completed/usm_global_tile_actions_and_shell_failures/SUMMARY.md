# USM Global Tile Actions + Shell Failures — Summary

Implementation date (UTC): 2026-01-16

## What shipped
- Domain-sourced tile capabilities (`EntityTileCapabilities`, `CompletionScope`) carried on renderable items.
- Presentation tile action surface: typed `TileIntent` + `TileIntentDispatcher` (tiles emit intents; dispatcher executes with `BuildContext`).
- Mutations routed through `ScreenActionsBloc` (no widget-layer DI/mutations in tiles).
- Single authenticated app-shell failure listener using `scaffoldMessengerKey`, with dedupe keyed by `(failureKind, entityType, entityId)`.
- Guardrail script to prevent regressions in entity views/tiles.
- Architecture documentation updated to make the above policy explicit.

## Known gaps / follow-ups
- Optionally wire `tool/usm_tile_action_guardrail.dart` into a CI/pre-push step if you want enforcement beyond local runs.
