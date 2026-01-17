# Phase 01 — Decision Gates + Spec/Style Toggles

Created at: 2026-01-16T02:30:06Z
Last updated at: 2026-01-16T06:24:19.2555476Z

## Goal
Lock the remaining UI open questions into implementable choices, and express “calmness” defaults through spec-driven styling (USM-friendly) instead of renderer forks.

## Inputs
- Decisions + open questions in `doc/plans/ui_decisions/2026-01-16_scheduled-page-calm-agenda-mockup2.md`

## Work items
1) Resolve open questions (explicit approvals required)
- UI-Q001 Row density choice (A/B/C)
- UI-Q002 Priority encoding approach (or none)
- UI-Q003 Ongoing rows: show/hide date chip behavior
- UI-Q004 Row actions rendering policy (inline vs overflow vs progressive disclosure)
- UI-Q005 Grouping structure (keep blocks vs continuous feed)

Notes for UI-Q004 (must align with USM global tile actions):
- The existence and availability of actions is driven by domain-sourced capabilities (not screen-specific widget logic).
- The decision here is only how enabled capabilities are presented (e.g. overflow-only vs inline affordances) and how calm the defaults feel.
- Any “hide/disable” needs must be expressed as a module-level capability override (applied in domain interpreters), not as a renderer fork.

2) Identify which knobs can be expressed in spec (preferred)
- Use `AgendaSectionParamsV2.entityStyleOverride` and `EntityStyleV1` as the first-line mechanism.
- If new knobs are needed (e.g. “agenda meta policy”), decide whether they belong in:
  - `EntityStyleV1` (if it is a cross-template tile style concern)
  - `AgendaSectionParamsV2` (if it is agenda-only)

3) Identify if any capability overrides are needed (only if required)
- If Scheduled needs a calmer action surface (e.g. hide pin/delete by default until UX is validated), express that as a module-level `EntityTileCapabilitiesOverride` (domain) per the global tile actions plan.
- Prefer style knobs over capability overrides unless the action must truly be unavailable.

3) Update the decision doc if any new contract is introduced
- Only if we introduce new style parameters or change layering responsibilities.

## Deliverables
- A small, explicit “approved configuration” list (choices for Q001–Q005)
- A mapping table: (approved choice) → (spec knob / code location)
- If UI-Q004 requires it: a mapping of (section/module) → (capability override)

## Approved configuration (assumed)
User direction: “Implement full plan”. This phase treats that as approval for the remaining UI open questions.

- UI-Q001 Row density: Option A (Minimal + expand)
  - Implemented via `AgendaMetaDensityV1.minimalExpandable`.
- UI-Q002 Priority encoding: subtle dot (default)
  - Implemented via `AgendaPriorityEncodingV1.subtleDot` (tooltip exposes the numeric priority).
- UI-Q003 Ongoing rows show/hide date chips: show deadline chip (start date hidden)
  - Implemented via `agendaShowDeadlineChipOnOngoing=true` + `showOnlyDeadlineDate=true` on ongoing rows.
- UI-Q004 Row actions visibility: progressive disclosure on desktop (hover/focus)
  - Implemented via `AgendaActionsVisibilityV1.hoverOrFocus`.
  - Guardrail: on touch platforms actions remain visible for discoverability.
- UI-Q005 Grouping structure: keep existing blocks
  - No grouping changes made (Today/This week/Next week/Later remain).

## Mapping (choice → knob/location)
- Style contract: `EntityStyleV1`
  - `agendaMetaDensity`, `agendaPriorityEncoding`, `agendaActionsVisibility`, `agendaPrimaryValueIconOnly`, `agendaMaxSecondaryValues`, `agendaShowDeadlineChipOnOngoing`
- Defaults (Scheduled / agendaV2): `EntityStyleResolver` (agendaV2 branch)
- Plumbing to tiles: `ScreenItemTileBuilder` → `TaskView` / `ProjectView`
- Rendering:
  - Task agenda card: `TaskViewVariant.agendaCard` in `TaskView`
  - Project agenda card: `ProjectViewVariant.agendaCard` in `ProjectView`
- Tag pills visibility: renderer checks `EntityStyleV1.showAgendaTagPills`

## Completion
Completed at: 2026-01-16T06:24:19.2555476Z

Summary:
- Added agenda-specific, spec-driven calmness knobs to `EntityStyleV1` and resolved defaults for Scheduled/agendaV2.
- Kept USM boundaries: no widget-layer mutation wiring introduced.
- Restored analyzer cleanliness after incidental file corruption.

## AI instructions (required)
- Run `flutter analyze` for the phase.
- Ensure any `flutter analyze` errors/warnings caused by this phase’s changes are fixed by the end of the phase.
- Review `doc/architecture/` before implementing the phase, and keep architecture docs updated if the phase changes architecture.
- When the phase is complete, update this file immediately (same day) with summary + completion date (UTC).
