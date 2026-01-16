# Phase 01 — Decision Gates + Spec/Style Toggles

Created at: 2026-01-16T02:30:06Z
Last updated at: 2026-01-16T02:30:06Z

## Goal
Lock the remaining UI open questions into implementable choices, and express “calmness” defaults through spec-driven styling (USM-friendly) instead of renderer forks.

## Inputs
- Decisions + open questions in `doc/plans/ui_decisions/2026-01-16_scheduled-page-calm-agenda-mockup2.md`

## Work items
1) Resolve open questions (explicit approvals required)
- UI-Q001 Row density choice (A/B/C)
- UI-Q002 Priority encoding approach (or none)
- UI-Q003 Ongoing rows: show/hide date chip behavior
- UI-Q004 Row actions visibility policy (always visible vs progressive disclosure)
- UI-Q005 Grouping structure (keep blocks vs continuous feed)

2) Identify which knobs can be expressed in spec (preferred)
- Use `AgendaSectionParamsV2.entityStyleOverride` and `EntityStyleV1` as the first-line mechanism.
- If new knobs are needed (e.g. “agenda meta policy”), decide whether they belong in:
  - `EntityStyleV1` (if it is a cross-template tile style concern)
  - `AgendaSectionParamsV2` (if it is agenda-only)

3) Update the decision doc if any new contract is introduced
- Only if we introduce new style parameters or change layering responsibilities.

## Deliverables
- A small, explicit “approved configuration” list (choices for Q001–Q005)
- A mapping table: (approved choice) → (spec knob / code location)

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).
