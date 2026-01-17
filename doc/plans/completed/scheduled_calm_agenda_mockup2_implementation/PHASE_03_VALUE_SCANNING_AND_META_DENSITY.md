# Phase 03 — Value Scanning + Meta Density (UI-D002, UI-D003)

Created at: 2026-01-16T02:30:06Z
Last updated at: 2026-01-16T06:24:19.2555476Z

## Goal
Implement the calm, mockup-2-aligned presentation while preserving Taskly’s “values-first” scanning.

## Prerequisites
- Phase 01 approvals for UI-Q001 and UI-Q003.

## Scope
- UI-D002: reduce perceived chrome / “chip soup” in Scheduled agenda rows.
- UI-D003: make primary value scannable and visually stable.

## Implementation strategy (USM-friendly)
Prefer small reusable primitives and config-driven behavior:
- If changes are cross-template tile style: add fields to `EntityStyleV1` and resolve via `EntityStyleResolver`.
- If changes are agenda-only: add fields to `AgendaSectionParamsV2` and plumb through the section VM.
- Avoid screen-specific forks of `TaskView`/`ProjectView` that would create long-term divergence.

USM tile actions alignment (important):
- If any meta tokens become interactive (e.g. align values, move-to-project), interaction must route through `TileIntent` + dispatcher and be gated by domain-sourced capabilities.
- Do not add widget-local mutation logic or per-page SnackBars.

## Candidate work items (depends on approvals)
- Primary value: icon-only, filled style, consistent placement.
- Secondary values: cap count (e.g. 2) and summarize remainder as `+N`.
- Decide which meta tokens remain always-on vs expanded.

## Acceptance criteria
- Scheduled rows feel calmer at default density (less wrapping, fewer tokens).
- Primary value remains the easiest non-title signal to scan.

## Completion
Completed at: 2026-01-16T06:24:19.2555476Z

Summary:
- Implemented calm agenda defaults through `EntityStyleV1` knobs (no renderer forks).
- Primary value uses icon-only filled chip; secondary values are capped and summarized as `+N` when needed.
- Meta density uses `minimalExpandable` with an explicit “More details/Less details” affordance.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).
