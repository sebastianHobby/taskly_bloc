# Option L — Dedicated Hierarchy Template (Phase 1: Domain wiring)

Created at: 2026-01-13T00:00:00Z
Last updated at: 2026-01-13T00:00:00Z

## Objective
Introduce a new first-class Unified Screen template for the Value → Project → Task hierarchy.

Deliverables:
- New `SectionTemplateId` entry for the hierarchy template.
- New typed params model under `lib/domain/screens/templates/params/`.
- Params codec support in `SectionTemplateParamsCodec`.
- New interpreter under `lib/domain/screens/templates/interpreters/`.
- DI wiring in `lib/core/di/dependency_injection.dart`.

## AI instructions
- Review `doc/architecture/` before implementing.
- Run `flutter analyze` for this phase.
- Fix any errors or warnings introduced by the phase.
- If architecture changes are introduced, update the relevant `doc/architecture/` docs in the same PR.
