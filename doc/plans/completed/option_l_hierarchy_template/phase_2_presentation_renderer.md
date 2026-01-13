# Option L — Dedicated Hierarchy Template (Phase 2: Presentation + routing)

Created at: 2026-01-13T00:00:00Z
Last updated at: 2026-01-13T00:00:00Z

## Objective
Render the new hierarchy template via `SectionWidget` and a dedicated renderer wrapper.

Deliverables:
- Renderer under `lib/presentation/screens/templates/renderers/`.
- Routing/guards in `lib/presentation/widgets/section_widget.dart`.
- Someday migration to the new template ID (no behavior regression).

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any errors or warnings introduced by the phase.
- If architecture changes are introduced, update the relevant `doc/architecture/` docs in the same PR.
