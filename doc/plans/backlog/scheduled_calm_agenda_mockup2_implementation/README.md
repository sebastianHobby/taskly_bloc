# Plan — Scheduled Calm Agenda (Mockup 2) Implementation

Created at: 2026-01-16T02:30:06Z
Last updated at: 2026-01-16T02:30:06Z

## Source decisions
This plan implements the persisted Scheduled decisions in:
- `doc/plans/ui_decisions/2026-01-16_scheduled-page-calm-agenda-mockup2.md`

## Scope (decisions)
- UI-D001: Rename “In progress” → “Ongoing” (Scheduled tag pill / label)
- UI-D002: Align Scheduled visual language toward “mockup 2” (reduce chrome; calm list language)
- UI-D003: Values remain the primary scanning primitive (primary value icon-only, filled; secondary values less dominant)
- UI-D004: Priority encoded subtly (avoid explicit `P#` by default)

## Constraints
- UI/UX changes must follow the Unified Screen Model (USM) patterns.
- Per repo workflow: do not implement UI/UX changes without explicit user approval; this plan includes decision gates for remaining open questions.

## Alignment constraint (USM tile actions)
Scheduled agenda tiles must not introduce screen/page-local mutation wiring.

- Tiles/widgets are dumb: no widget-layer DI mutation calls.
- Mutations flow via `TileIntent` → `ScreenActionsBloc`.
- Mutation failures are surfaced by the authenticated app shell listener (no per-page SnackBars).

## Dependencies
- Global tile actions + shell failure policy (canonical):
  - `doc/plans/wip/usm_global_tile_actions_and_shell_failures/`

(These plans can be executed independently for purely visual changes, but any work that touches tile actions/mutations should land after or alongside the global tile-actions work to avoid rework.)
