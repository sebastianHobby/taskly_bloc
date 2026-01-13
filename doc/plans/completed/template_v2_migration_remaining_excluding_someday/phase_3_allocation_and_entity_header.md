# Template V2 Migration (Remaining Templates) — Phase 3: Allocation + Entity Header

Created at: 2026-01-13T00:00:00Z (UTC)
Last updated at: 2026-01-13T00:00:00Z (UTC)

## Objective
Bring `allocation` and `entity_header` into the “V2 world” as much as makes sense, while preserving their specialized UX.

## In scope
- `allocation`
- `entity_header`

## Proposed target state
### Allocation
- Decision: keep `allocation` as a specialized template/result, but align it to V2 conventions (strict typed params, explicit tile variant, consistent renderer API).
- Non-goal: introduce a new V2 layout spec type for allocation in this migration.
- Clarify responsibility boundaries:
  - Data shaping (grouping/pinning/exclusions) in domain (`SectionDataService` + allocation engine).
  - Pure view-state (filters/sort toggles) in presentation only.

### Entity header
- Decision: keep a single `entity_header` template (no new IDs); continue returning specialized result variants (project/value/missing) and align params + rendering conventions.

## Implementation outline
- Domain
  - Adjust params and codec mapping if introducing V2 versions.
  - Ensure interpreters remain thin wrappers over domain services.
- Presentation
  - Standardize renderer APIs and reduce template-specific branching in `SectionWidget`.

## Exit criteria
- Allocation behavior is fully represented by typed params (no hidden per-screen magic).
- Entity headers remain stable and testable, with a clear contract.

## AI instructions
- Re-read `doc/architecture/` before implementing the phase.
- Run `flutter analyze` during the phase and ensure any errors/warnings introduced (or discovered) are fixed by the end of the phase.
- If this phase changes module boundaries, responsibilities, or data flow, update the relevant files under `doc/architecture/` in the same PR.
