# Template V2 Migration (Remaining Templates) — Phase 2: Support Blocks

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Migrate the “support block” style templates to be consistent with the V2 template conventions (typed params, explicit variant keys, and predictable rendering contracts).

## In scope
- `issues_summary`
- `allocation_alerts`
- `check_in_summary`

## Proposed target state
- Keep templates as section-level building blocks (top-of-screen sections).
- Keep/extend typed params models (potentially `*ParamsV2` depending on Phase 1 decision).
- Standardize style keys:
  - Decision: keep current required style keys as-is (no new required style keys in this phase).
  - Rationale: minimize break risk; evolve schemas only when a real screen needs it.
- Improve consistency of data contracts:
  - Clarify whether these should remain specialized `SectionDataResult.*` variants or become `dataV2` with a typed `EnrichmentResultV2` payload.

## Implementation outline
- Domain
  - Update params + codec mapping in `lib/domain/screens/templates/interpreters/section_template_params_codec.dart`.
  - If introducing new IDs, register new interpreters in DI (`lib/core/di/dependency_injection.dart`) and add aliasing strategy.
- Presentation
  - Keep renderers in `lib/presentation/screens/templates/renderers/` but align signatures and error handling with V2 renderers.
  - Decision: keep `SectionWidget` as the single switchboard (no renderer registry refactor).
  - Rationale: matches current documented V2 architecture and keeps changes low-churn.
- Tests
  - Add/adjust tests for param decode strictness and renderer selection.

## Exit criteria
- Each template has a stable, documented params schema.
- Section renders without bespoke per-screen branching.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
