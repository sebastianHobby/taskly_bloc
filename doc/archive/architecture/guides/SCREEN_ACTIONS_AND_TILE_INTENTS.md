# Screen Actions + Tile Intents -- Guide

> Audience: developers
>
> Scope: shared action handling for entity tiles and screen-level actions.
> Descriptive only; invariants live in [../INVARIANTS.md](../INVARIANTS.md).

## 1) Why this exists

Entity tiles appear across screens. Taskly routes their user actions through a
shared **tile intent** pipeline so completion, delete, and navigation
behave consistently and remain BLoC-owned.

## 2) Key pieces

Tile intents:
- `lib/presentation/screens/tiles/tile_intent.dart`
- `lib/presentation/screens/tiles/tile_overflow_action_catalog.dart`

Dispatcher (UI -> BLoC + routing):
- `lib/presentation/screens/tiles/tile_intent_dispatcher.dart`

Shared screen actions BLoC:
- `lib/presentation/screens/bloc/screen_actions_bloc.dart`
- `lib/presentation/screens/bloc/screen_actions_state.dart`

## 3) Data flow (typical)

```text
Tile tap -> TileIntent -> TileIntentDispatcher
  -> ScreenActionsBloc event (writes via domain)
  -> UI effect or error (snackbar, navigation)
```

## 4) Notes

- Mutations create `OperationContext` in the BLoC (see invariants).
- Occurrence-aware completion requires explicit occurrence keys.
- Navigation side-effects are triggered from presentation (not domain/data).
