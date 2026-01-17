# Phase 04 — Subtle Priority Encoding (UI-D004)

Created at: 2026-01-16T02:30:06Z
Last updated at: 2026-01-16T06:24:19.2555476Z

## Goal
Implement subtle priority encoding (or explicitly choose none) without reintroducing dashboard-like “status noise”.

## Prerequisites
- Phase 01 approval for UI-Q002.

## Scope
- UI-D004: replace explicit `P#` display (by default) with the approved subtle encoding.

## Options (examples)
- Typography: slightly stronger title weight for higher priority.
- Shape: small neutral glyph (dot/diamond) with tooltip.
- Stroke: subtle tick thickness change.

## Acceptance criteria
- Priority is discoverable but not visually dominant.
- The chosen encoding is consistent across task + project tiles (unless intentionally different).

USM tile actions alignment (guardrail)
- Keep priority encoding visual-only.
- If any interaction is introduced (menus, tooltips that trigger actions), route it through `TileIntent` and gate it via capabilities.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).

## Completion
Completed at: 2026-01-16T06:24:19.2555476Z

Summary:
- Added `AgendaPriorityEncodingV1` and implemented subtle priority encodings for agenda cards.
- Default encoding for Scheduled/agendaV2 is a subtle dot with tooltip; explicit `P#` remains available via `explicitPill`.
