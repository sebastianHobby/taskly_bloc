# Phase 02 — USM screen specs + module scaffolding

Created at: 2026-01-15T12:30:44.4044895Z
Last updated at: 2026-01-15T12:30:44.4044895Z

## Goal

Move Journal from the dedicated `journalHub` template to a standard USM screen (`standardScaffoldV1`) with slotted modules, aligned to UX-001C.

## Scope

- Add/adjust system screen specs for the Journal Today-first surface.
- Introduce typed module specs for Journal sections.
- Add interpreter registration and Section VM(s) needed to render those sections.

No deep UI polish in this phase; focus on structure and compile-time correctness.

## Implementation tasks

1) Screen spec migration
- Update system screen catalog to define the Journal screen using `ScreenTemplateSpec.standardScaffoldV1`.
- Add (or confirm) separate screen keys for:
  - History
  - Manage trackers
  - Entry editor (if implemented as a USM screen vs a dedicated route)

2) Module specs
- Create typed `ScreenModuleSpec`(s) for:
  - Today hero composer header
  - Today entries list
  - Previous-days teaser + “See all history”

3) Interpreters
- Implement module interpreters that expose the required reactive data (streams) for the section VMs.
- Keep failures localized to section-level error VMs (do not crash the screen stream).

4) Presentation wiring
- Update the template switchboard/rendering registry to render the new section VMs.
- Ensure all repository reads and stream subscriptions remain in BLoCs/interpreters (no widget->repo).

## Acceptance criteria

- Navigating to the Journal screen key renders via `standardScaffoldV1`.
- All modules render placeholder UI driven by section VMs (even if minimal).
- No architecture invariant violations.

## AI instructions

- Review `doc/architecture/` before implementing this phase.
- Run `flutter analyze` for this phase.
- Fix any `flutter analyze` errors/warnings caused by this phase’s changes by the end of the phase.
- When the phase is complete, update:
  - `Last updated at:` (UTC)
  - `Completed at:` (UTC)
  - A short summary of what changed

## Completion

Completed at: <UTC>
Summary:
- <fill when complete>
